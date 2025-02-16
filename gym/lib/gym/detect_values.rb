require 'fastlane_core/core_ext/cfpropertylist'
require 'fastlane_core/project'
require_relative 'module'
require_relative 'code_signing_mapping'
require_relative 'export_method'

module Gym
  # This class detects all kinds of default values
  class DetectValues
    # This is needed as these are more complex default values
    # Returns the finished config object
    def self.set_additional_default_values
      config = Gym.config

      # First, try loading the Gymfile from the current directory
      config.load_configuration_file(Gym.gymfile_name)

      # Detect the project
      FastlaneCore::Project.detect_projects(config)
      Gym.project = FastlaneCore::Project.new(config)

      # Go into the project's folder, as there might be a Gymfile there
      project_path = File.expand_path("..", Gym.project.path)
      unless File.expand_path(".") == project_path
        Dir.chdir(project_path) do
          config.load_configuration_file(Gym.gymfile_name)
        end
      end

      ensure_export_options_is_hash

      detect_scheme
      detect_platform # we can only do that *after* we have the scheme
      detect_selected_provisioning_profiles # we can only do that *after* we have the platform
      detect_configuration
      detect_toolchain
      detect_third_party_installer

      config[:output_name] ||= Gym.project.app_name

      config[:build_path] ||= archive_path_from_local_xcode_preferences

      # Make sure the output name is valid and remove a trailing `.ipa` extension
      # as it will be added by gym for free
      config[:output_name].gsub!(".ipa", "")
      config[:output_name].gsub!(File::SEPARATOR, "_")

      return config
    end

    def self.archive_path_from_local_xcode_preferences
      day = Time.now.strftime("%F") # e.g. 2015-08-07
      archive_path = File.expand_path("~/Library/Developer/Xcode/Archives/#{day}/")

      return archive_path unless has_xcode_preferences_plist?

      custom_archive_path = xcode_preferences_dictionary['IDECustomDistributionArchivesLocation']
      return archive_path if custom_archive_path.to_s.length == 0

      return File.join(custom_archive_path, day)
    end

    # Helper Methods

    # this file only exists when you edit the Xcode preferences to set custom values
    def self.has_xcode_preferences_plist?
      File.exist?(xcode_preference_plist_path)
    end

    def self.xcode_preference_plist_path
      File.expand_path("~/Library/Preferences/com.apple.dt.Xcode.plist")
    end

    def self.xcode_preferences_dictionary(path = xcode_preference_plist_path)
      CFPropertyList.native_types(CFPropertyList::List.new(file: path).value)
    end

    # Since Xcode 9 you need to provide the explicit mapping of what provisioning profile to use for
    # each target of your app
    def self.detect_selected_provisioning_profiles
      Gym.config[:export_options] ||= {}
      hash_to_use = (Gym.config[:export_options][:provisioningProfiles] || {}).dup || {} # dup so we can show the original values in `verbose` mode

      unless Gym.config[:skip_profile_detection]
        mapping_object = CodeSigningMapping.new(project: Gym.project)
        hash_to_use = mapping_object.merge_profile_mapping(primary_mapping: hash_to_use,
                                                           export_method: Gym.config[:export_method])
      end

      return if hash_to_use.count == 0 # We don't want to set a mapping if we don't have one
      Gym.config[:export_options][:provisioningProfiles] = hash_to_use
      UI.message("Detected provisioning profile mapping: #{hash_to_use}")
    rescue => ex
      # We don't want to fail the build if the automatic detection doesn't work
      # especially since the mapping is optional for pre Xcode 9 setups
      if Helper.xcode_at_least?("9.0")
        UI.error("Couldn't automatically detect the provisioning profile mapping")
        UI.error("Since Xcode 9 you need to provide an explicit mapping of what")
        UI.error("provisioning profile to use for each target of your app")
        UI.error(ex)
        UI.verbose(ex.backtrace.join("\n"))
      end
    end

    # Detects name of a "3rd Party Mac Developer Installer" cert for the configured team id
    def self.detect_third_party_installer
      return if Gym.config[:installer_cert_name]

      team_id = Gym.config[:export_team_id] || Gym.project.build_settings(key: "DEVELOPMENT_TEAM")
      return if team_id.nil?

      case Gym.config[:export_method]
      when ExportMethod::APP_STORE
        prefix = "3rd Party Mac Developer Installer: "
      when "developer-id"
        prefix = "Developer ID Installer: "
      else
        return
      end

      output = Helper.backticks("security find-certificate -a -c \"#{prefix}\"", print: false)

      # Find matches, filter by team_id, prepend prefix for full cert name
      certs = output.scan(/"(?:#{prefix})(.*)"/)
      certs = certs.flatten.uniq.select do |cert|
        cert.include?(team_id)
      end.map do |cert|
        prefix + cert
      end

      if certs.first
        UI.verbose("Detected installer certificate to use: #{certs.first}")
        Gym.config[:installer_cert_name] = certs.first
      end
    end

    def self.detect_scheme
      Gym.project.select_scheme
    end

    def self.min_xcode8?
      Helper.xcode_at_least?("8.0")
    end

    # Is it an iOS device or a Mac?
    def self.detect_platform
      return if Gym.config[:destination]

      platform = if Gym.project.tvos?
                   "tvOS"
                 elsif Gym.project.visionos?
                   "visionOS"
                 elsif Gym.building_for_ios?
                   "iOS"
                 elsif Gym.building_for_mac?
                   min_xcode8? ? "macOS" : "OS X"
                 else
                   "iOS"
                 end
      Gym.config[:destination] = "generic/platform=#{platform}"
    end

    # Detects the available configurations (e.g. Debug, Release)
    def self.detect_configuration
      config = Gym.config
      configurations = Gym.project.configurations
      return if configurations.count == 0 # this is an optional value anyway

      if config[:configuration]
        # Verify the configuration is available
        unless configurations.include?(config[:configuration])
          UI.error("Couldn't find specified configuration '#{config[:configuration]}'.")
          config[:configuration] = nil
        end
      end
    end

    # The toolchain parameter is used if you don't use the default toolchain of Xcode (e.g. Swift 2.3 with Xcode 8)
    def self.detect_toolchain
      return unless Gym.config[:toolchain]

      # Convert the aliases to the full string to make it easier for the user #justfastlanethings
      if Gym.config[:toolchain].to_s == "swift_2_3"
        Gym.config[:toolchain] = "com.apple.dt.toolchain.Swift_2_3"
      end
    end

    def self.ensure_export_options_is_hash
      return if Gym.config[:export_options].nil? || Gym.config[:export_options].kind_of?(Hash)

      # Reads options from file
      plist_file_path = Gym.config[:export_options]
      UI.user_error!("Couldn't find plist file at path #{File.expand_path(plist_file_path)}") unless File.exist?(plist_file_path)
      hash = Plist.parse_xml(plist_file_path)
      UI.user_error!("Couldn't read provided plist at path #{File.expand_path(plist_file_path)}") if hash.nil?
      # Convert keys to symbols
      Gym.config[:export_options] = keys_to_symbols(hash)
    end

    def self.keys_to_symbols(hash)
      # Convert keys to symbols
      hash = hash.each_with_object({}) do |(k, v), memo|
        memo[k.b.to_s.to_sym] = v
        memo
      end
      hash
    end
  end
end
