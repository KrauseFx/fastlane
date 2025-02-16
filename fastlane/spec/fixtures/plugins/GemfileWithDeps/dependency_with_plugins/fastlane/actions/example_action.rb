module Fastlane
  module Actions
    class ExampleActionAction < Action
      def self.run(params)
        UI.message("App automation done right")
      end

      def self.is_supported?(platform)
        true
      end

      def self.available_options
      end
    end
  end
end
