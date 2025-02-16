require 'open3'
require 'fileutils'
require 'shellwords'
require 'terminal-table'

require 'fastlane_core/print_table'
require 'fastlane_core/command_executor'
require_relative 'module'
require_relative 'generators/package_command_generator'
require_relative 'generators/build_command_generator'
require_relative 'error_handler'

module Gym
  class Runner
    # @return (String) The path to the resulting ipa
    def run
      unless Gym.config[:skip_build_archive]
        build_app
      end
      verify_archive unless Gym.config[:skip_archive]

      return nil if Gym.config[:skip_archive]

      FileUtils.mkdir_p(File.expand_path(Gym.config[:output_directory]))

      # Archive
      if Gym.building_for_ios?
        fix_generic_archive unless Gym.project.watchos? # See https://github.com/fastlane/fastlane/pull/4325
        return BuildCommandGenerator.archive_path if Gym.config[:skip_package_ipa]

        package_app
        compress_and_move_dsym

        unless Gym.export_destination_upload?
          path = move_ipa
          move_manifest
          move_app_thinning
          move_app_thinning_size_report
          move_apps_folder
          move_asset_packs
          move_appstore_info
        end
      elsif Gym.building_for_mac?
        path = File.expand_path(Gym.config[:output_directory])
        compress_and_move_dsym
        if Gym.project.mac_app? || Gym.building_mac_catalyst_for_mac?
          path = copy_mac_app
          return path if Gym.config[:skip_package_pkg]

          package_app
          unless Gym.export_destination_upload?
            path = move_pkg
            move_appstore_info
          end
          return path
        end
        copy_files_from_path(File.join(BuildCommandGenerator.archive_path, "Products/usr/local/bin/*")) if Gym.project.command_line_tool?
      end
      return path
    end
    # rubocop:enable Metrics/PerceivedComplexity

    #####################################################
    # @!group Printing out things
    #####################################################

    # @param [Array] An array containing all the parts of the command
    def print_command(command, title)
      rows = command.map do |c|
        current = c.to_s.dup
        next unless current.length > 0

        match_default_parameter = current.match(/(-.*) '(.*)'/)
        if match_default_parameter
          # That's a default parameter, like `-project 'Name'`
          match_default_parameter[1, 2]
        else
          current.gsub!("| ", "\| ") # as the | will somehow break the terminal table
          [current, ""]
        end
      end

      puts(Terminal::Table.new(
             title: title.green,
             headings: ["Option", "Value"],
             rows: FastlaneCore::PrintTable.transform_output(rows.delete_if { |c| c.to_s.empty? })
      ))
    end

    private

    #####################################################
    # @!group The individual steps
    #####################################################

    def fix_generic_archive
      return unless FastlaneCore::Env.truthy?("GYM_USE_GENERIC_ARCHIVE_FIX")
      Gym::XcodebuildFixes.generic_archive_fix
    end

    def mark_archive_as_built_by_gym(archive_path)
      escaped_archive_path = archive_path.shellescape
      system("xattr -w info.fastlane.generated_by_gym 1 #{escaped_archive_path}")
    end

    # Builds the app and prepares the archive
    def build_app
      command = BuildCommandGenerator.generate
      print_command(command, "Generated Build Command") if FastlaneCore::Globals.verbose?
      FastlaneCore::CommandExecutor.execute(command: command,
                                          print_all: true,
                                      print_command: !Gym.config[:silent],
                                              error: proc do |output|
                                                ErrorHandler.handle_build_error(output)
                                              end)

      unless Gym.config[:skip_archive]
        mark_archive_as_built_by_gym(BuildCommandGenerator.archive_path)
        UI.success("Successfully stored the archive. You can find it in the Xcode Organizer.") unless Gym.config[:archive_path].nil?
        UI.verbose("Stored the archive in: " + BuildCommandGenerator.archive_path)
      end

      post_build_app
    end

    # Post-processing of build_app
    def post_build_app
      command = BuildCommandGenerator.post_build

      return if command.empty?

      print_command(command, "Generated Post-Build Command") if FastlaneCore::Globals.verbose?
      FastlaneCore::CommandExecutor.execute(command: command,
                                          print_all: true,
                                      print_command: !Gym.config[:silent],
                                              error: proc do |output|
                                                ErrorHandler.handle_build_error(output)
                                              end)
    end

    # Makes sure the archive is there and valid
    def verify_archive
      # from https://github.com/fastlane/fastlane/issues/3179
      if (Dir[BuildCommandGenerator.archive_path + "/*"]).count == 0
        ErrorHandler.handle_empty_archive
      end
    end

    def package_app
      command = PackageCommandGenerator.generate
      print_command(command, "Generated Package Command") if FastlaneCore::Globals.verbose?

      FastlaneCore::CommandExecutor.execute(command: command,
                                          print_all: false,
                                      print_command: !Gym.config[:silent],
                                              error: proc do |output|
                                                ErrorHandler.handle_package_error(output)
                                              end)
    end

    def compress_and_move_dsym
      return unless PackageCommandGenerator.dsym_path

      # Compress and move the dsym file
      containing_directory = File.expand_path("..", PackageCommandGenerator.dsym_path)
      bcsymbolmaps_directory = File.expand_path("../../BCSymbolMaps", PackageCommandGenerator.dsym_path)
      available_dsyms = Dir.glob("#{containing_directory}/*.dSYM")
      uuid_regex = /[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}/

      if Dir.exist?(bcsymbolmaps_directory)
        UI.message("Mapping dSYM(s) using generated BCSymbolMaps") unless Gym.config[:silent]
        available_dsyms.each do |dsym|
          dwarfdump_command = []
          dwarfdump_command << "dwarfdump"
          dwarfdump_command << "--uuid #{dsym.shellescape}"

          # Extract uuids
          dwarfdump_result = Helper.backticks(dwarfdump_command.join(" "), print: false)
          architecture_infos = dwarfdump_result.split("\n")
          architecture_infos.each do |info|
            info_array = info.split(" ", 4)
            uuid = info_array[1]
            dwarf_file_path = info_array[3]

            if uuid.nil? || !uuid.match(uuid_regex)
              next
            end

            # Find bcsymbolmap file to be used:
            #  - if a <uuid>.plist file exists, we will extract uuid of bcsymbolmap and use it
            #  - if a <uuid>.bcsymbolmap file exists, we will use it
            #  - otherwise let dsymutil figure it out
            symbol_map_path = nil
            split_dwarf_file_path = File.split(dwarf_file_path)
            dsym_plist_file_path = File.join(split_dwarf_file_path[0], "..", "#{uuid}.plist")
            if File.exist?(dsym_plist_file_path)
              dsym_plist = Plist.parse_xml(dsym_plist_file_path)
              original_uuid = dsym_plist['DBGOriginalUUID']
              possible_symbol_map_path = "#{bcsymbolmaps_directory}/#{original_uuid}.bcsymbolmap"
              if File.exist?(possible_symbol_map_path)
                symbol_map_path = possible_symbol_map_path.shellescape
              end
            end
            if symbol_map_path.nil?
              possible_symbol_map_path = File.join(bcsymbolmaps_directory, "#{uuid}.bcsymbolmap")
              if File.exist?(possible_symbol_map_path)
                symbol_map_path = possible_symbol_map_path.shellescape
              end
            end
            if symbol_map_path.nil?
              symbol_map_path = bcsymbolmaps_directory.shellescape
            end
            command = []
            command << "dsymutil"
            command << "--symbol-map #{symbol_map_path}"
            command << dsym.shellescape
            Helper.backticks(command.join(" "), print: !Gym.config[:silent])
          end
        end
      end

      UI.message("Compressing #{available_dsyms.count} dSYM(s)") unless Gym.config[:silent]

      output_path = File.expand_path(File.join(Gym.config[:output_directory], Gym.config[:output_name] + ".app.dSYM.zip"))
      command = "cd '#{containing_directory}' && zip -r '#{output_path}' *.dSYM"
      Helper.backticks(command, print: !Gym.config[:silent])
      puts("") # new line

      UI.success("Successfully exported and compressed dSYM file")
    end

    # Moves over the binary and dsym file to the output directory
    # @return (String) The path to the resulting ipa file
    def move_ipa
      FileUtils.mv(PackageCommandGenerator.ipa_path, File.expand_path(Gym.config[:output_directory]), force: true)
      ipa_path = File.expand_path(File.join(Gym.config[:output_directory], File.basename(PackageCommandGenerator.ipa_path)))

      UI.success("Successfully exported and signed the ipa file:")
      UI.message(ipa_path)
      ipa_path
    end

    # Moves over the binary and dsym file to the output directory
    # @return (String) The path to the resulting pkg file
    def move_pkg
      binary_path = File.expand_path(File.join(Gym.config[:output_directory], File.basename(PackageCommandGenerator.binary_path)))
      if File.exist?(binary_path)
        UI.important(" Removing #{File.basename(binary_path)}") if FastlaneCore::Globals.verbose?
        FileUtils.rm_rf(binary_path)
      end
      FileUtils.mv(PackageCommandGenerator.binary_path, File.expand_path(Gym.config[:output_directory]), force: true)

      UI.success("Successfully exported and signed the pkg file:")
      UI.message(binary_path)
      binary_path
    end

    # copies framework from temp folder:

    def copy_files_from_path(path)
      UI.success("Exporting Files:")
      Dir[path].each do |f|
        existing_file = File.join(File.expand_path(Gym.config[:output_directory]), File.basename(f))
        # If the target file already exists in output directory
        # we have to remove it first, otherwise cp_r fails even with remove_destination
        # e.g.: there are symlinks in the .framework
        if File.exist?(existing_file)
          UI.important("Removing #{File.basename(f)} from output directory") if FastlaneCore::Globals.verbose?
          FileUtils.rm_rf(existing_file)
        end
        FileUtils.cp_r(f, File.expand_path(Gym.config[:output_directory]), remove_destination: true)
        UI.message("\t ▸ #{File.basename(f)}")
      end
    end

    # Copies the .app from the archive into the output directory
    def copy_mac_app
      exe_name = Gym.project.build_settings(key: "EXECUTABLE_NAME")
      app_path = File.join(BuildCommandGenerator.archive_path, "Products/Applications/#{exe_name}.app")

      unless File.exist?(app_path)
        # Apparently the `EXECUTABLE_NAME` is not correct. This can happen when building a workspace which has a project
        # earlier in the build order that has a different `EXECUTABLE_NAME` than the app. Try to find the last `.app` as
        # a fallback for this situation.
        app_path = Dir[File.join(BuildCommandGenerator.archive_path, "Products", "Applications", "*.app")].last
      end

      UI.crash!("Couldn't find application in '#{BuildCommandGenerator.archive_path}'") unless app_path && File.exist?(app_path)

      joined_app_path = File.join(Gym.config[:output_directory], File.basename(app_path))
      FileUtils.rm_rf(joined_app_path)
      FileUtils.cp_r(app_path, File.expand_path(Gym.config[:output_directory]), remove_destination: true)

      UI.success("Successfully exported the .app file:")
      UI.message(joined_app_path)
      joined_app_path
    end

    # Move the manifest.plist if exists into the output directory
    def move_manifest
      if File.exist?(PackageCommandGenerator.manifest_path)
        FileUtils.mv(PackageCommandGenerator.manifest_path, File.expand_path(Gym.config[:output_directory]), force: true)
        manifest_path = File.join(File.expand_path(Gym.config[:output_directory]), File.basename(PackageCommandGenerator.manifest_path))

        UI.success("Successfully exported the manifest.plist file:")
        UI.message(manifest_path)
        manifest_path
      end
    end

    # Move the app-thinning.plist file into the output directory
    def move_app_thinning
      if File.exist?(PackageCommandGenerator.app_thinning_path)
        FileUtils.mv(PackageCommandGenerator.app_thinning_path, File.expand_path(Gym.config[:output_directory]), force: true)
        app_thinning_path = File.join(File.expand_path(Gym.config[:output_directory]), File.basename(PackageCommandGenerator.app_thinning_path))

        UI.success("Successfully exported the app-thinning.plist file:")
        UI.message(app_thinning_path)
        app_thinning_path
      end
    end

    # Move the App Thinning Size Report.txt file into the output directory
    def move_app_thinning_size_report
      if File.exist?(PackageCommandGenerator.app_thinning_size_report_path)
        FileUtils.mv(PackageCommandGenerator.app_thinning_size_report_path, File.expand_path(Gym.config[:output_directory]), force: true)
        app_thinning_size_report_path = File.join(File.expand_path(Gym.config[:output_directory]), File.basename(PackageCommandGenerator.app_thinning_size_report_path))

        UI.success("Successfully exported the App Thinning Size Report.txt file:")
        UI.message(app_thinning_size_report_path)
        app_thinning_size_report_path
      end
    end

    # Move the Apps folder to the output directory
    def move_apps_folder
      if Dir.exist?(PackageCommandGenerator.apps_path)
        FileUtils.mv(PackageCommandGenerator.apps_path, File.expand_path(Gym.config[:output_directory]), force: true)
        apps_path = File.join(File.expand_path(Gym.config[:output_directory]), File.basename(PackageCommandGenerator.apps_path))

        UI.success("Successfully exported Apps folder:")
        UI.message(apps_path)
        apps_path
      end
    end

    # Move Asset Packs folder to the output directory
    # @return (String) The path to the resulting Asset Packs (aka OnDemandResources) folder
    def move_asset_packs
      if Dir.exist?(PackageCommandGenerator.asset_packs_path)
        FileUtils.mv(PackageCommandGenerator.asset_packs_path, File.expand_path(Gym.config[:output_directory]), force: true)
        asset_packs_path = File.join(File.expand_path(Gym.config[:output_directory]), File.basename(PackageCommandGenerator.asset_packs_path))

        UI.success("Successfully exported Asset Pack folder:")
        UI.message(asset_packs_path)
        asset_packs_path
      end
    end

    # Move the AppStoreInfo.plist folder to the output directory
    def move_appstore_info
      if File.exist?(PackageCommandGenerator.appstore_info_path)
        FileUtils.mv(PackageCommandGenerator.appstore_info_path, File.expand_path(Gym.config[:output_directory]), force: true)
        appstore_info_path = File.join(File.expand_path(Gym.config[:output_directory]), File.basename(PackageCommandGenerator.appstore_info_path))

        UI.success("Successfully exported the AppStoreInfo.plist file:")
        UI.message(appstore_info_path)
        appstore_info_path
      end
    end

    def find_archive_path
      Dir.glob(File.join(BuildCommandGenerator.build_path, "*.ipa")).last
    end
  end
end
