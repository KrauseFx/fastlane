require 'fastlane_core/device_manager'
require 'fastlane_core/project'
require_relative 'module'

module Scan
  # This class detects all kinds of default values
  class DetectValues
    # This is needed as these are more complex default values
    # Returns the finished config object
    def self.set_additional_default_values
      config = Scan.config

      # First, try loading the Scanfile from the current directory
      config.load_configuration_file(Scan.scanfile_name)

      prevalidate

      # Detect the project
      FastlaneCore::Project.detect_projects(config)
      Scan.project = FastlaneCore::Project.new(config)

      # Go into the project's folder, as there might be a Snapfile there
      imported_path = File.expand_path(Scan.scanfile_name)
      Dir.chdir(File.expand_path("..", Scan.project.path)) do
        config.load_configuration_file(Scan.scanfile_name) unless File.expand_path(Scan.scanfile_name) == imported_path
      end

      Scan.project.select_scheme

      devices = Scan.config[:devices] || Array(Scan.config[:device]) # important to use Array(nil) for when the value is nil
      if devices.count > 0
        detect_simulator(devices, '', '', '', nil)
      else
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
      return unless Scan.config[:derived_data_path].to_s.empty?
      default_path = Scan.project.build_settings(key: "BUILT_PRODUCTS_DIR")
      # => /Users/.../Library/Developer/Xcode/DerivedData/app-bqrfaojicpsqnoglloisfftjhksc/Build/Products/Release-iphoneos
      # We got 3 folders up to point to ".../DerivedData/app-[random_chars]/"
      default_path = File.expand_path("../../..", default_path)
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
      require 'set'

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

          selector = ->(sim) { pieces.count > 0 && sim.name == pieces.first }

          set + (
            if pieces.count == 0
              [] # empty array
            elsif pieces.count == 1
              simulators
                .select(&selector)
                .reverse # more efficient, because `simctl` prints higher versions first
                .sort_by! { |sim| Gem::Version.new(sim.os_version) }
                .pop(1)
            else # pieces.count == 2 -- mathematically, because of the 'end of line' part of our regular expression
              version = pieces[1].tr('()', '')
              potential_emptiness_error = lambda do |sims|
                if sims.empty?
                  UI.error("No simulators found that are equal to the version " \
                  "of specifier (#{version}) and greater than or equal to the version " \
                  "of deployment target (#{deployment_target_version})")
                end
              end
              filter_simulators(simulators, :equal, version).tap(&potential_emptiness_error).select(&selector)
            end
          ).tap do |array|
            if array.empty?
              UI.test_failure!("No device found with name '#{device_string}'") if Scan.config[:ensure_devices_found]
              UI.error("Ignoring '#{device_string}', couldn’t find matching simulator")
            end
          end
        end

        set_of_simulators.to_a
      end

      unless Scan.config[:skip_detect_devices]
        default = lambda do
          UI.error("Couldn't find any matching simulators for '#{devices}' - falling back to default simulator") if (devices || []).count > 0

          result = Array(
            simulators
              .select { |sim| sim.name == default_device_name }
              .reverse # more efficient, because `simctl` prints higher versions first
              .sort_by! { |sim| Gem::Version.new(sim.os_version) }
              .last || simulators.first
          )

          UI.message("Found simulator \"#{result.first.name} (#{result.first.os_version})\"") if result.first

          result
        end
      end

      # Convert array to lazy enumerable (evaluate map only when needed)
      # grab the first unempty evaluated array
      Scan.devices = [matches, default].lazy.reject(&:nil?).map do |x|
        arr = x.call
        arr unless arr.empty?
      end.reject(&:nil?).first
    end

    def self.min_xcode8?
      Helper.xcode_at_least?("8.0")
    end

    def self.detect_destination
      if Scan.config[:destination]
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
        Scan.config[:destination] = Scan.devices.map { |d| "platform=#{d.os_type} Simulator,id=#{d.udid}" }
      elsif Scan.project.mac_app?
        Scan.config[:destination] = min_xcode8? ? ["platform=macOS"] : ["platform=OS X"]
      end
    end

    # get deployment target version
    def self.get_deployment_target_version(deployment_target_key)
      Scan.config[:deployment_target_version] || Scan.project.build_settings(key: deployment_target_key) || '0'
    end
  end
end
