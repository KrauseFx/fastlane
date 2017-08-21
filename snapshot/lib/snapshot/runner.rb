require 'shellwords'
require 'plist'
require 'os'
require 'thread'

module Snapshot
  class Runner
    def work
      if File.exist?("./fastlane/snapshot.js") or File.exist?("./snapshot.js")
        UI.error "Found old snapshot configuration file 'snapshot.js'"
        UI.error "You updated to snapshot 1.0 which now uses UI Automation"
        UI.error "Please follow the migration guide: https://github.com/fastlane/fastlane/blob/master/snapshot/MigrationGuide.md"
        UI.error "And read the updated documentation: https://github.com/fastlane/fastlane/tree/master/snapshot"
        sleep 3 # to be sure the user sees this, as compiling clears the screen
      end

      Snapshot.config[:output_directory] = File.expand_path(Snapshot.config[:output_directory])

      verify_helper_is_current

      # Also print out the path to the used Xcode installation
      # We go 2 folders up, to not show "Contents/Developer/"
      values = Snapshot.config.values(ask: false)
      values[:xcode_path] = File.expand_path("../..", FastlaneCore::Helper.xcode_path)
      FastlaneCore::PrintTable.print_values(config: values, hide_keys: [], title: "Summary for snapshot #{Fastlane::VERSION}")

      clear_previous_screenshots if Snapshot.config[:clear_previous_screenshots]

      UI.success "Building and running project - this might take some time..."

      launcher_config = SimulatorLauncherConfiguration.new(snapshot_config: Snapshot.config)

      if Helper.xcode_at_least?(9)
        launcher = SimulatorLauncher.new(launcher_configuration: launcher_config)
        results = launcher.take_screenshots_simultaneously
      else
        launcher = SimulatorLauncherXcode8.new(launcher_configuration: launcher_config)
        results = launcher.take_screenshots_one_simulator_at_a_time
      end

      print_results(results)

      UI.test_failure!(launcher.collected_errors.uniq.join('; ')) if launcher.collected_errors.count > 0

      # Generate HTML report
      ReportsGenerator.new.generate

      # Clear the Derived Data
      unless Snapshot.config[:derived_data_path]
        # this should actually be launcher.derived_data_path
        FileUtils.rm_rf(TestCommandGeneratorBase.derived_data_path)
      end
    end

    def print_results(results)
      return if results.count == 0

      rows = []
      results.each do |device, languages|
        current = [device]
        languages.each do |language, value|
          current << (value == true ? " 💚" : " ❌")
        end
        rows << current
      end

      params = {
        rows: FastlaneCore::PrintTable.transform_output(rows),
        headings: ["Device"] + results.values.first.keys,
        title: "snapshot results"
      }
      puts ""
      puts Terminal::Table.new(params)
      puts ""
    end

    def clear_previous_screenshots
      UI.important "Clearing previously generated screenshots"
      path = File.join(Snapshot.config[:output_directory], "*", "*.png")
      Dir[path].each do |current|
        UI.verbose "Deleting #{current}"
        File.delete(current)
      end
    end

    def version_of_bundled_helper
      runner_dir = File.dirname(__FILE__)

      current_version = ""
      if Helper.xcode_at_least?("9.0")
        bundled_helper = File.read(File.expand_path('../assets/SnapshotHelper.swift', runner_dir))
        current_version = bundled_helper.match(/\n.*SnapshotHelperVersion \[.+\]/)[0]
      else
        bundled_helper = File.read(File.expand_path('../assets/SnapshotHelperXcode8.swift', runner_dir))
        current_version = bundled_helper.match(/\n.*SnapshotHelperXcode8Version \[.+\]/)[0]
      end

      ## Something like "// SnapshotHelperVersion [1.2]", but be relaxed about whitespace
      current_version.gsub(%r{^//\w*}, '').strip
    end

    # rubocop:disable Style/Next
    def verify_helper_is_current
      return if Snapshot.config[:skip_helper_version_check]
      current_version = version_of_bundled_helper
      UI.verbose "Checking that helper files contain #{current_version}"

      helper_files = Update.find_helper
      helper_files.each do |path|
        content = File.read(path)

        unless content.include?(current_version)
          UI.error "Your '#{path}' is outdated, please run `fastlane snapshot update`"
          UI.error "to update your Helper file"
          UI.user_error!("Please update your Snapshot Helper file")
        end
      end
    end
    # rubocop:enable Style/Next
  end
end
