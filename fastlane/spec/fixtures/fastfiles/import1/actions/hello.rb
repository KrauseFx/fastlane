module Fastlane
  module Actions
    class HelloAction < Action
      def self.run(params)
        UI.message("Param1: #{params[:param1]}")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :param1,
                                       optional: false,
                                       type: String,
                                       default_value: "",
                                       description: "Param1")
        ]
      end

      def self.output
        []
      end

      def self.return_value
      end

      def self.authors
        ["lacostej"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
