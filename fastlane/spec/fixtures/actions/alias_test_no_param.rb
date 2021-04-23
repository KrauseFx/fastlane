module Fastlane
  module Actions
    class AliasTestNoParamAction < Action
      attr_accessor :global_test

      def self.run(params)
        UI.important(@global_test)
      end

      def self.alias_used(action_alias, params)
        @global_test = "modified"
      end

      def self.aliases
        ["somealias_no_param"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.available_options
      end
    end
  end
end
