require 'fastlane_core/project'
require 'fastlane_core/device_manager'

require_relative 'module'

module Snapshot
  class DetectValues
    # This is needed as these are more complex default values
    def self.set_additional_default_values
      config = Snapshot.config

      # First, try loading the Snapfile from the current directory
      configuration_file_path = File.expand_path(Snapshot.snapfile_name)
      config.load_configuration_file(Snapshot.snapfile_name)

      # Detect the project
      FastlaneCore::Project.detect_projects(config)
      Snapshot.project = FastlaneCore::Project.new(config)

      # Go into the project's folder, as there might be a Snapfile there
      Dir.chdir(File.expand_path("..", Snapshot.project.path)) do
        unless File.expand_path(Snapshot.snapfile_name) == configuration_file_path
          config.load_configuration_file(Snapshot.snapfile_name)
        end
      end

      if config[:test_without_building] == true && config[:derived_data_path].to_s.length == 0
        UI.user_error!("Cannot use test_without_building option without a derived_data_path!")
      end

      Snapshot.project.select_scheme(preferred_to_include: "UITests")

      coerce_to_array_of_strings(:only_testing)
      coerce_to_array_of_strings(:skip_testing)

      # Devices
      if config[:devices].nil? && !Snapshot.project.mac?
        config[:devices] = []

        # We only care about a subset of the simulators
        all_simulators = FastlaneCore::Simulator.all
        all_simulators.each do |sim|
          # Filter iPads, we only want the following simulators
          # Xcode 7:
          #   ["iPad Pro", "iPad Air"]
          # Xcode 8:
          #   ["iPad Pro (9.7-Inch)", "iPad Pro (12.9-Inch)"]
          #
          # Full list: ["iPad 2", "iPad Retina", "iPad Air", "iPad Air 2", "iPad Pro"]
          next if sim.name.include?("iPad 2")
          next if sim.name.include?("iPad Retina")
          next if sim.name.include?("iPad Air 2")
          # In Xcode 8, we only need iPad Pro 9.7 inch, not the iPad Air
          next if all_simulators.any? { |a| a.name.include?("9.7-inch") } && sim.name.include?("iPad Air")

          # In Xcode 9, we only need one iPad Pro (12.9-inch)
          next if sim.name.include?('iPad Pro (12.9-inch) (2nd generation)')

          # Filter iPhones
          # Full list: ["iPhone 4s", "iPhone 5", "iPhone 5s", "iPhone 6", "iPhone 6 Plus", "iPhone 6s", "iPhone 6s Plus"]
          next if sim.name.include?("5s") # same screen resolution as iPhone 5
          next if sim.name.include?("SE") # duplicate of iPhone 5
          next if sim.name.include?("iPhone 6") # same as iPhone 7

          next if sim.name.include?("Apple TV")

          config[:devices] << sim.name
        end
      elsif config[:devices].nil? && Snapshot.project.mac?
        config[:devices] = ["Mac"]
      end
    end

    def self.coerce_to_array_of_strings(config_key)
      config_value = Snapshot.config[config_key]

      return if config_value.nil?

      # splitting on comma allows us to support comma-separated lists of values
      # from the command line, even though the ConfigItem is not defined as an
      # Array type
      config_value = config_value.split(',') unless config_value.kind_of?(Array)
      Snapshot.config[config_key] = config_value.map(&:to_s)
    end
  end
end
