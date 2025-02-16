require 'fastlane_core/device_manager'
require 'fastlane_core/project'
require 'pathname'
require 'set'
require_relative 'module'

module Scan
  # This class detects all kinds of default values
  class DetectValues
    PLATFORMS = {
      'iOS' => { simulator: 'iphonesimulator', name: 'com.apple.platform.iphoneos' },
      'tvOS' => { simulator: 'appletvsimulator', name: 'com.apple.platform.appletvos' },
      'watchOS' => { simulator: 'watchsimulator', name: 'com.apple.platform.watchos' },
      'visionOS' => { simulator: 'xrsimulator', name: 'com.apple.platform.xros' }
    }.freeze

    # This is needed as these are more complex default values
    # Returns the finished config object
    def self.set_additional_default_values
      config = Scan.config

      # First, try loading the Scanfile from the current directory
      config.load_configuration_file(Scan.scanfile_name)

      prevalidate

      # Detect the project if not SPM package
      if Scan.config[:package_path].nil?
        FastlaneCore::Project.detect_projects(config)
        Scan.project = FastlaneCore::Project.new(config)

        # Go into the project's folder, as there might be a Snapfile there
        imported_path = File.expand_path(Scan.scanfile_name)
        Dir.chdir(File.expand_path("..", Scan.project.path)) do
          config.load_configuration_file(Scan.scanfile_name) unless File.expand_path(Scan.scanfile_name) == imported_path
        end

        Scan.project.select_scheme
      end

      devices = Scan.config[:devices] || Array(Scan.config[:device]) # important to use Array(nil) for when the value is nil
      if devices.count > 0
        detect_simulator(devices, '', '', '', nil)
      elsif Scan.project
        if Scan.project.ios?
          # An iPhone 5s is a reasonably small and useful default for tests
          detect_simulator(devices, 'iOS', 'IPHONEOS_DEPLOYMENT_TARGET', 'iPhone 5s', nil)
        elsif Scan.project.tvos?
          detect_simulator(devices, 'tvOS', 'TVOS_DEPLOYMENT_TARGET', 'Apple TV 1080p', 'TV')
        end
      end

      detect_destination

      default_derived_data

      coerce_to_array_of_strings(:only_testing)
      coerce_to_array_of_strings(:skip_testing)

      coerce_to_array_of_strings(:only_test_configurations)
      coerce_to_array_of_strings(:skip_test_configurations)

      return config
    end

    def self.prevalidate
      output_types = Scan.config[:output_types]
      has_multiple_report_types = output_types && output_types.split(',').size > 1
      if has_multiple_report_types && Scan.config[:custom_report_file_name]
        UI.user_error!("Using a :custom_report_file_name with multiple :output_types (#{output_types}) will lead to unexpected results. Use :output_files instead.")
      end
    end

    def self.coerce_to_array_of_strings(config_key)
      config_value = Scan.config[config_key]

      return if config_value.nil?

      # splitting on comma allows us to support comma-separated lists of values
      # from the command line, even though the ConfigItem is not defined as an
      # Array type
      config_value = config_value.split(',') unless config_value.kind_of?(Array)
      Scan.config[config_key] = config_value.map(&:to_s)
    end

    def self.default_derived_data
      return unless Scan.project

      return unless Scan.config[:derived_data_path].to_s.empty?
      default_path = Scan.project.build_settings(key: "BUILT_PRODUCTS_DIR")
      # => /Users/.../Library/Developer/Xcode/DerivedData/app-bqrfaojicpsqnoglloisfftjhksc/Build/Products/Release-iphoneos
      # We got 3 folders up to point to ".../DerivedData/app-[random_chars]/"
      default_path = File.expand_path("../../..", default_path)
      if default_path.nil?
        UI.error("Can't retrieve BUILT_PRODUCTS_DIR from the project to detect derived data path.")
        UI.error("Either set `derived_data_path` explicitly in `scan`, or enable build for running in the scheme.")
        return
      end
      UI.verbose("Detected derived data path '#{default_path}'")
      Scan.config[:derived_data_path] = default_path
    end

    def self.filter_simulators(simulators, operator = :greater_than_or_equal, deployment_target)
      deployment_target_version = Gem::Version.new(deployment_target)
      simulators.select do |s|
        sim_version = Gem::Version.new(s.os_version)
        if operator == :greater_than_or_equal
          sim_version >= deployment_target_version
        elsif operator == :equal
          sim_version == deployment_target_version
        else
          false # this will show an error message in the detect_simulator method
        end
      end
    end

    def self.default_os_version(os_type)
      @os_versions ||= {}
      @os_versions[os_type] ||= begin
        UI.crash!("Unknown platform: #{os_type}") unless PLATFORMS.key?(os_type)
        platform = PLATFORMS[os_type]

        _, error, = Open3.capture3('xcrun simctl runtime -h')
        unless error.include?('Usage: simctl runtime <operation> <arguments>')
          UI.error("xcrun simctl runtime broken, run 'xcrun simctl runtime' and make sure it works")
          UI.user_error!("xcrun simctl runtime not working.")
        end

        # `match list` subcommand added in Xcode 15
        if error.include?('match list')

          # list SDK version for currently running Xcode
          sdks_output, status = Open3.capture2('xcodebuild -showsdks -json')
          sdk_version = begin
            raise status unless status.success?
            JSON.parse(sdks_output).find { |e| e['platform'] == platform[:simulator] }['sdkVersion']
          rescue StandardError => e
            UI.error(e)
            UI.error("xcodebuild CLI broken, please run `xcodebuild` and make sure it works")
            UI.user_error!("xcodebuild not working")
          end

          # Get runtime build from SDK version
          runtime_output, status = Open3.capture2('xcrun simctl runtime match list -j')
          runtime_build = begin
            raise status unless status.success?
            JSON.parse(runtime_output).values.find { |elem| elem['platform'] == platform[:name] && elem['sdkVersion'] == sdk_version }['chosenRuntimeBuild']
          rescue StandardError => e
            UI.error(e)
            UI.error("xcrun simctl runtime broken, please verify that `xcrun simctl runtime match list` and `xcrun simctl runtime list` work")
            UI.user_error!("xcrun simctl runtime not working")
          end

          # Get OS version corresponding to build
          Gem::Version.new(FastlaneCore::DeviceManager.runtime_build_os_versions[runtime_build])
        end
      end
    end

    def self.clear_cache
      @os_versions = nil
    end

    def self.compatibility_constraint(sim, device_name)
      latest_os = default_os_version(sim.os_type)
      sim.name == device_name && (latest_os.nil? || Gem::Version.new(sim.os_version) <= latest_os)
    end

    def self.highest_compatible_simulator(simulators, device_name)
      simulators
        .select { |sim| compatibility_constraint(sim, device_name) }
        .reverse
        .sort_by! { |sim| Gem::Version.new(sim.os_version) }
        .last
    end

    def self.regular_expression_for_split_on_whitespace_followed_by_parenthesized_version
      # %r{
      #   \s # a whitespace character
      #   (?= # followed by -- using lookahead
      #   \( # open parenthesis
      #   [\d\.]+ # our version -- one or more digits or full stops
      #   \) # close parenthesis
      #   $ # end of line
      #   ) # end of lookahead
      # }
      /\s(?=\([\d\.]+\)$)/
    end

    def self.detect_simulator(devices, requested_os_type, deployment_target_key, default_device_name, simulator_type_descriptor)
      clear_cache

      deployment_target_version = get_deployment_target_version(deployment_target_key)
      simulators = filter_simulators(
        FastlaneCore::DeviceManager.simulators(requested_os_type).tap do |array|
          if array.empty?
            UI.user_error!(['No', simulator_type_descriptor, 'simulators found on local machine'].reject(&:nil?).join(' '))
          end
        end,
        :greater_than_or_equal,
        deployment_target_version
      ).tap do |sims|
        if sims.empty?
          UI.error("No simulators found that are greater than or equal to the version of deployment target (#{deployment_target_version})")
        end
      end

      # At this point we have all simulators for the given deployment target (or higher)

      # We create 2 lambdas, which we iterate over later on
      # If the first lambda `matches` found a simulator to use
      # we'll never call the second one
      matches = lambda do
        set_of_simulators = devices.inject(
          Set.new # of simulators
        ) do |set, device_string|
          pieces = device_string.split(regular_expression_for_split_on_whitespace_followed_by_parenthesized_version)

          display_device = "'#{device_string}'"

          set + (
            if pieces.count == 0
              [] # empty array
            elsif pieces.count == 1
              [ highest_compatible_simulator(simulators, pieces.first) ].compact
            else # pieces.count == 2 -- mathematically, because of the 'end of line' part of our regular expression
              version = pieces[1].tr('()', '')
              display_device = "'#{pieces[0]}' with version #{version}"

              potential_emptiness_error = lambda do |sims|
                if sims.empty?
                  UI.error("No simulators found that are equal to the version " \
                  "of specifier (#{version}) and greater than or equal to the version " \
                  "of deployment target (#{deployment_target_version})")
                end
              end
              filter_simulators(simulators, :equal, version).tap(&potential_emptiness_error).select { |sim| sim.name == pieces.first }
            end
          ).tap do |array|
            if array.empty?
              UI.test_failure!("No device found with name #{display_device}") if Scan.config[:ensure_devices_found]
              UI.error("Ignoring '#{device_string}', couldn't find matching simulator")
            end
          end
        end

        set_of_simulators.to_a
      end

      unless Scan.config[:skip_detect_devices]
        default = lambda do
          UI.error("Couldn't find any matching simulators for '#{devices}' - falling back to default simulator") if (devices || []).count > 0

          result = [ highest_compatible_simulator(simulators, default_device_name) || simulators.first ]

          UI.message("Found simulator \"#{result.first.name} (#{result.first.os_version})\"") if result.first

          result
        end
      end

      # Convert array to lazy enumerable (evaluate map only when needed)
      # grab the first unempty evaluated array
      Scan.devices = [matches, default].lazy.reject(&:nil?).map { |x|
        arr = x.call
        arr unless arr.empty?
      }.reject(&:nil?).first
    end

    def self.min_xcode8?
      Helper.xcode_at_least?("8.0")
    end

    def self.detect_destination
      if Scan.config[:destination]
        # No need to show below warnings message(s) for xcode13+, because
        # Apple recommended to have destination in all xcodebuild commands
        # otherwise, Apple will generate warnings in console logs
        # see: https://github.com/fastlane/fastlane/issues/19579
        return if Helper.xcode_at_least?("13.0")

        UI.important("It's not recommended to set the `destination` value directly")
        UI.important("Instead use the other options available in `fastlane scan --help`")
        UI.important("Using your value '#{Scan.config[:destination]}' for now")
        UI.important("because I trust you know what you're doing...")
        return
      end

      # building up the destination now
      if Scan.building_mac_catalyst_for_mac?
        Scan.config[:destination] = ["platform=macOS,variant=Mac Catalyst"]
      elsif Scan.devices && Scan.devices.count > 0
        # Explicitly run simulator in Rosetta (needed for Xcode 14.3 and up)
        # Fixes https://github.com/fastlane/fastlane/issues/21194
        arch = ""
        if Scan.config[:run_rosetta_simulator]
          arch = ",arch=x86_64"
        end

        Scan.config[:destination] = Scan.devices.map { |d| "platform=#{d.os_type} Simulator,id=#{d.udid}" + arch }
      elsif Scan.project && Scan.project.mac_app?
        Scan.config[:destination] = min_xcode8? ? ["platform=macOS"] : ["platform=OS X"]
      end
    end

    # get deployment target version
    def self.get_deployment_target_version(deployment_target_key)
      version = Scan.config[:deployment_target_version]
      version ||= Scan.project.build_settings(key: deployment_target_key) if Scan.project
      version ||= 0
      return version
    end
  end
end
