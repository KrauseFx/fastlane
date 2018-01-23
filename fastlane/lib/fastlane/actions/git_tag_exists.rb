module Fastlane
  module Actions
    class GitTagExistsAction < Action
      def self.run(params)
        tag_ref = "refs/tags/#{params[:tag].shellescape}"
        if params[:remote]
          command = "git ls-remote -q --exit-code #{params[:remote_name].shellescape} #{tag_ref}"
        else
          command = "git rev-parse -q --verify #{tag_ref}"
        end
        exists = true
        Actions.sh(
          command,
          log: FastlaneCore::Globals.verbose?,
          error_callback: lambda { |result|
            exists = false
          }
        )
        exists
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Checks if the git tag with the given name exists in the current repo"
      end

      def self.details
        nil
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :tag,
                                       description: "The tag name that should be checked"),
          FastlaneCore::ConfigItem.new(key: :remote,
                                       description: "Defaults to `false`",
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :remote_name,
                                       description: "The remote to check. Defaults to `origin`",
                                       default_value: 'origin'),
        ]
      end

      def self.return_value
        "Boolean value whether the tag exists or not"
      end

      def self.output
        [
        ]
      end

      def self.authors
        ["antondomashnev"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'if git_tag_exists(tag: "1.1.0")
            UI.message("Found it 🚀")
          end'
        ]
      end

      def self.category
        :source_control
      end
    end
  end
end
