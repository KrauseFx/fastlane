module Fastlane
  module Actions
    class ImportFromGemAction < Action
      def self.run(params)
        # in fast_file.rb
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Import fastfile/actions from a gem, alternative to import_from_git"
      end

      # def self.details
      # end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :gem_name,
                                       optional: false,
                                       type: String,
                                       default_value: "",
                                       description: "The gem to import Fastfile and actions from"),
          FastlaneCore::ConfigItem.new(key: :paths,
                                       description: "The path(s) of the Fastfile in the repository",
                                       default_value: ['fastlane/Fastfile*'],
                                       optional: true)
        ]
      end

      def self.category
        :misc
      end

      def self.output
        [
        ]
      end

      def self.return_value
      end

      def self.authors
        ["lacostej/jeromel@kahoot.com"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
