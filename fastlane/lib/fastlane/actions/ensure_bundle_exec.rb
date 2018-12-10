module Fastlane
  module Actions
    module SharedValues
    end

    # Raises an exception and stop the lane execution if the repo is not on a specific branch
    class EnsureBundleExecAction < Action
      def self.run(params)
        return if PluginManager.new.gemfile_path.nil?
        if FastlaneCore::Helper.bundler?
          UI.success("Using bundled fastlane ✅")
        else
          UI.user_error!("fastlane detected a Gemfile in the current directory. However it seems like you don't use `bundle exec`. Use `bundle exec fastlane #{ARGV.join(' ')}`")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Raises an exception if not on a using bundler"
      end

      def self.details
        [
          "This action will check if you are using bundle exec to run fastlane."
        ].join("\n")
      end

      def self.available_options
        [
        ]
      end

      def self.output
        []
      end

      def self.author
        ['rishabhtayal']
      end

      def self.example_code
        [
          "ensure_bundle_exec"
        ]
      end

      def self.category
        :misc
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
