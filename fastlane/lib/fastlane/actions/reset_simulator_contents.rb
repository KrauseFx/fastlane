module Fastlane
  module Actions
    class ResetSimulatorContentsAction < Action
      def self.run(params)
        os_versions = params[:os_versions] || params[:ios]

        reset_simulators(os_versions)
      end

      def self.reset_simulators(os_versions)
        UI.verbose("Resetting simulator contents")

        if os_versions
          os_versions.each do |os_version|
            reset_all_by_version(os_version)
          end
        else
          reset_all
        end

        UI.success('Simulators reset done')
      end

      def self.reset_all_by_version(os_version)
        FastlaneCore::Simulator.reset_all_by_version(os_version: os_version)
        FastlaneCore::SimulatorTV.reset_all_by_version(os_version: os_version)
        FastlaneCore::SimulatorWatch.reset_all_by_version(os_version: os_version)
        FastlaneCore::SimulatorVision.reset_all_by_version(os_version: os_version)
      end

      def self.reset_all
        FastlaneCore::Simulator.reset_all
        FastlaneCore::SimulatorTV.reset_all
        FastlaneCore::SimulatorWatch.reset_all
        FastlaneCore::SimulatorVision.reset_all
      end

      def self.description
        "Shutdown and reset running simulators"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :ios,
                                       deprecated: "Use `:os_versions` instead",
                                       short_option: "-i",
                                       env_name: "FASTLANE_RESET_SIMULATOR_VERSIONS",
                                       description: "Which OS versions of Simulators you want to reset content and settings, this does not remove/recreate the simulators",
                                       optional: true,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :os_versions,
                                       short_option: "-v",
                                       env_name: "FASTLANE_RESET_SIMULATOR_OS_VERSIONS",
                                       description: "Which OS versions of Simulators you want to reset content and settings, this does not remove/recreate the simulators",
                                       optional: true,
                                       type: Array)
        ]
      end

      def self.aliases
        ["reset_simulators"]
      end

      def self.output
        nil
      end

      def self.return_value
        nil
      end

      def self.authors
        ["danramteke"]
      end

      def self.is_supported?(platform)
        [:ios, :tvos, :watchos].include?(platform)
      end

      def self.example_code
        [
          'reset_simulator_contents',
          'reset_simulator_contents(os_versions: ["10.3.1","12.2"])'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
