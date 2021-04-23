module Fastlane
  module Actions
    module SharedValues
    end

    class UploadToAppStoreAction < Action
      def self.run(config)
        require 'deliver'

        config.load_configuration_file("Deliverfile")
        config[:screenshots_path] ||= Actions.lane_context[SharedValues::SNAPSHOT_SCREENSHOTS_PATH] if Actions.lane_context[SharedValues::SNAPSHOT_SCREENSHOTS_PATH]
        config[:ipa] ||= Actions.lane_context[SharedValues::IPA_OUTPUT_PATH] if Actions.lane_context[SharedValues::IPA_OUTPUT_PATH]
        config[:pkg] ||= Actions.lane_context[SharedValues::PKG_OUTPUT_PATH] if Actions.lane_context[SharedValues::PKG_OUTPUT_PATH]
        config[:api_key] ||= Actions.lane_context[SharedValues::APP_STORE_CONNECT_API_KEY]

        return config if Helper.test?
        Deliver::Runner.new(config).run
      end

      def self.description
        "Upload metadata and binary to App Store Connect (via _deliver_)"
      end

      def self.details
        [
          "Using _upload_to_app_store_ after _build_app_ and _capture_screenshots_ will automatically upload the latest ipa and screenshots with no other configuration.",
          "",
          "If you don't want to verify an HTML preview for App Store builds, use the `:force` option.",
          "This is useful when running _fastlane_ on your Continuous Integration server:",
          "`_upload_to_app_store_(force: true)`",
          "If your account is on multiple teams and you need to tell the `iTMSTransporter` which 'provider' to use, you can set the `:itc_provider` option to pass this info."
        ].join("\n")
      end

      def self.available_options
        require "deliver"
        require "deliver/options"
        FastlaneCore::CommanderGenerator.new.generate(Deliver::Options.available_options)
      end

      def self.author
        "KrauseFx"
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.example_code
        [
          'upload_to_app_store(
            force: true, # Set to true to skip verification of HTML preview
            itc_provider: "abcde12345" # pass a specific value to the iTMSTransporter -itc_provider option
          )',
          'deliver   # alias for "upload_to_app_store"',
          'appstore  # alias for "upload_to_app_store"'
        ]
      end

      def self.category
        :production
      end
    end
  end
end
