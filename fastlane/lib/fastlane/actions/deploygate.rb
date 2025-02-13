module Fastlane
  module Actions
    module SharedValues
      DEPLOYGATE_URL = :DEPLOYGATE_URL
      DEPLOYGATE_REVISION = :DEPLOYGATE_REVISION # auto increment revision number
      DEPLOYGATE_APP_INFO = :DEPLOYGATE_APP_INFO # contains app revision, bundle identifier, etc.
    end

    class DeploygateAction < Action
      DEPLOYGATE_URL_BASE = 'https://deploygate.com'

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end

      def self.upload_build(api_token, user_name, binary, options)
        require 'faraday'
        require 'faraday_middleware'

        connection = Faraday.new(url: DEPLOYGATE_URL_BASE, request: { timeout: 120 }) do |builder|
          builder.request(:multipart)
          builder.request(:json)
          builder.response(:json, content_type: /\bjson$/)
          builder.use(FaradayMiddleware::FollowRedirects)
          builder.adapter(:net_http)
        end

        options.update({
          token: api_token,
          file: Faraday::UploadIO.new(binary, 'application/octet-stream'),
          message: options[:message] || ''
        })
        options[:disable_notify] = 'yes' if options[:disable_notify]

        connection.post("/api/users/#{user_name}/apps", options)
      rescue Faraday::TimeoutError
        UI.crash!("Timed out while uploading build. Check https://deploygate.com/ to see if the upload was completed.")
      end

      def self.run(options)
        # Available options: https://deploygate.com/docs/api
        UI.success('Starting with app upload to DeployGate... this could take some time ⏳')

        api_token = options[:api_token]
        user_name = options[:user]
        binary = options[:ipa] || options[:apk] || options[:aab]
        upload_options = options.values.select do |key, _|
          [:message, :distribution_key, :release_note, :disable_notify, :distribution_name].include?(key)
        end

        UI.user_error!('missing `ipa`, `apk` and `aab`. deploygate action needs least one.') unless binary

        return binary if Helper.test?

        response = self.upload_build(api_token, user_name, binary, upload_options)
        if parse_response(response)
          UI.message("DeployGate URL: #{Actions.lane_context[SharedValues::DEPLOYGATE_URL]}")
          UI.success("Build successfully uploaded to DeployGate as revision \##{Actions.lane_context[SharedValues::DEPLOYGATE_REVISION]}!")
        else
          UI.user_error!("Error when trying to upload app to DeployGate")
        end
      end

      def self.parse_response(response)
        if response.body && response.body.key?('error')

          if response.body['error']
            UI.error("Error uploading to DeployGate: #{response.body['message']}")
            help_message(response)
            return
          else
            res = response.body['results']
            url = DEPLOYGATE_URL_BASE + res['path']

            Actions.lane_context[SharedValues::DEPLOYGATE_URL] = url
            Actions.lane_context[SharedValues::DEPLOYGATE_REVISION] = res['revision']
            Actions.lane_context[SharedValues::DEPLOYGATE_APP_INFO] = res
          end
        else
          UI.error("Error uploading to DeployGate: #{response.body}")
          return
        end
        true
      end
      private_class_method :parse_response

      def self.help_message(response)
        message =
          case response.body['message']
          when 'you are not authenticated'
            'Invalid API Token specified.'
          when 'application create error: permit'
            'Access denied: May be trying to upload to wrong user or updating app you join as a tester?'
          when 'application create error: limit'
            'Plan limit: You have reached to the limit of current plan or your plan was expired.'
          end
        UI.error(message) if message
      end
      private_class_method :help_message

      def self.description
        "Upload a new build to [DeployGate](https://deploygate.com/)"
      end

      def self.details
        [
          "You can retrieve your username and API token on [your settings page](https://deploygate.com/settings).",
          "More information about the available options can be found in the [DeployGate Push API document](https://deploygate.com/docs/api)."
        ].join("\n")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "DEPLOYGATE_API_TOKEN",
                                       description: "Deploygate API Token",
                                       sensitive: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("No API Token for DeployGate given, pass using `api_token: 'token'`") unless value.to_s.length > 0
                                       end),
          FastlaneCore::ConfigItem.new(key: :user,
                                       env_name: "DEPLOYGATE_USER",
                                       description: "Target username or organization name",
                                       verify_block: proc do |value|
                                         UI.user_error!("No User for DeployGate given, pass using `user: 'user'`") unless value.to_s.length > 0
                                       end),
          FastlaneCore::ConfigItem.new(key: :ipa,
                                       env_name: "DEPLOYGATE_IPA_PATH",
                                       description: "Path to your IPA file. Optional if you use the _gym_ or _xcodebuild_ action",
                                       default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
                                       default_value_dynamic: true,
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find ipa file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :apk,
                                       env_name: "DEPLOYGATE_APK_PATH",
                                       description: "Path to your APK file",
                                       default_value: Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH],
                                       default_value_dynamic: true,
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find apk file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :aab,
                                       env_name: "DEPLOYGATE_AAB_PATH",
                                       description: "Path to your AAB file",
                                       default_value: Actions.lane_context[SharedValues::GRADLE_AAB_OUTPUT_PATH],
                                       default_value_dynamic: true,
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find aab file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :message,
                                       env_name: "DEPLOYGATE_MESSAGE",
                                       description: "Release Notes",
                                       default_value: "No changelog provided"),
          FastlaneCore::ConfigItem.new(key: :distribution_key,
                                       optional: true,
                                       env_name: "DEPLOYGATE_DISTRIBUTION_KEY",
                                       sensitive: true,
                                       description: "Target Distribution Key"),
          FastlaneCore::ConfigItem.new(key: :release_note,
                                       optional: true,
                                       env_name: "DEPLOYGATE_RELEASE_NOTE",
                                       description: "Release note for distribution page"),
          FastlaneCore::ConfigItem.new(key: :disable_notify,
                                       optional: true,
                                       type: Boolean,
                                       default_value: false,
                                       env_name: "DEPLOYGATE_DISABLE_NOTIFY",
                                       description: "Disables Push notification emails"),
          FastlaneCore::ConfigItem.new(key: :distribution_name,
                                       optional: true,
                                       env_name: "DEPLOYGATE_DISTRIBUTION_NAME",
                                       description: "Target Distribution Name")
        ]
      end

      def self.output
        [
          ['DEPLOYGATE_URL', 'URL of the newly uploaded build'],
          ['DEPLOYGATE_REVISION', 'auto incremented revision number'],
          ['DEPLOYGATE_APP_INFO', 'Contains app revision, bundle identifier, etc.']
        ]
      end

      def self.example_code
        [
          'deploygate(
            api_token: "...",
            user: "target username or organization name",
            ipa: "./ipa_file.ipa",
            message: "Build #{lane_context[SharedValues::BUILD_NUMBER]}",
            distribution_key: "(Optional) Target Distribution Key",
            distribution_name: "(Optional) Target Distribution Name"
          )',
          'deploygate(
            api_token: "...",
            user: "target username or organization name",
            apk: "./apk_file.apk",
            message: "Build #{lane_context[SharedValues::BUILD_NUMBER]}",
            distribution_key: "(Optional) Target Distribution Key",
            distribution_name: "(Optional) Target Distribution Name"
          )',
          'deploygate(
            api_token: "...",
            user: "target username or organization name",
            aab: "./aab_file.aab",
            message: "Build #{lane_context[SharedValues::BUILD_NUMBER]}",
            distribution_key: "(Optional) Target Distribution Key",
            distribution_name: "(Optional) Target Distribution Name"
          )'
        ]
      end

      def self.category
        :beta
      end

      def self.authors
        ["tnj", "tomorrowkey"]
      end
    end
  end
end
