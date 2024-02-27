module Fastlane
  module Actions
    class UploadSymbolsToSentryAction < Action
      def self.run(params)
        # Warning about using new plugin
        UI.important("It's recommended to use the official Sentry Fastlane plugin")
        UI.important("GitHub: https://github.com/getsentry/fastlane-plugin-sentry")
        UI.important("Installation: fastlane add_plugin sentry")

        UI.user_error!("This plugin is now completely deprecated")
        # the code below doesn't run anymore
        # Actions.verify_gem!('rest-client')
        # require 'rest-client'

        # Params - API
        host = params[:api_host]
        api_key = params[:api_key]
        auth_token = params[:auth_token]
        org = params[:org_slug]
        project = params[:project_slug]

        # Params - dSYM
        dsym_path = params[:dsym_path]
        dsym_paths = params[:dsym_paths] || []

        has_api_key = !api_key.to_s.empty?
        has_auth_token = !auth_token.to_s.empty?

        # Will fail if none or both authentication methods are provided
        if !has_api_key && !has_auth_token
          UI.user_error!("No API key or authentication token found for SentryAction given, pass using `api_key: 'key'` or `auth_token: 'token'`")
        elsif has_api_key && has_auth_token
          UI.user_error!("Both API key and authentication token found for SentryAction given, please only give one")
        end

        # Url to post dSYMs to
        url = "#{host}/projects/#{org}/#{project}/files/dsyms/"

        if has_api_key
          resource = RestClient::Resource.new(url, api_key, '')
        else
          resource = RestClient::Resource.new(url, headers: { Authorization: "Bearer #{auth_token}" })
        end

        UI.message("Will upload dSYM(s) to #{url}")

        # Upload dsym(s)
        dsym_paths += [dsym_path]
        uploaded_paths = dsym_paths.compact.map do |dsym|
          upload_dsym(resource, dsym)
        end

        # Return uploaded dSYM paths
        uploaded_paths
      end

      def self.upload_dsym(resource, dsym)
        UI.message("Uploading... #{dsym}")
        resource.post(file: File.new(dsym, 'rb')) unless Helper.test?
        UI.success('dSYM successfully uploaded to Sentry!')

        dsym
      rescue
        UI.user_error!('Error while trying to upload dSYM to Sentry')
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Upload dSYM symbolication files to Sentry"
      end

      def self.details
        "This action allows you to upload symbolication files to Sentry. It's extra useful if you use it to download the latest dSYM files from Apple when you use Bitcode."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_host,
                                       env_name: "SENTRY_HOST",
                                       description: "API host url for Sentry",
                                       default_value: "https://app.getsentry.com/api/0",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :api_key,
                                       env_name: "SENTRY_API_KEY",
                                       description: "API key for Sentry",
                                       sensitive: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :auth_token,
                                       env_name: "SENTRY_AUTH_TOKEN",
                                       description: "Authentication token for Sentry",
                                       sensitive: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :org_slug,
                                       env_name: "SENTRY_ORG_SLUG",
                                       description: "Organization slug for Sentry project",
                                       verify_block: proc do |value|
                                         UI.user_error!("No organization slug for SentryAction given, pass using `org_slug: 'org'`") unless value && !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :project_slug,
                                       env_name: "SENTRY_PROJECT_SLUG",
                                       description: "Project slug for Sentry",
                                       verify_block: proc do |value|
                                         UI.user_error!("No project slug for SentryAction given, pass using `project_slug: 'project'`") unless value && !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :dsym_path,
                                       env_name: "SENTRY_DSYM_PATH",
                                       description: "Path to your symbols file. For iOS and Mac provide path to app.dSYM.zip",
                                       default_value: Actions.lane_context[SharedValues::DSYM_OUTPUT_PATH],
                                       default_value_dynamic: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :dsym_paths,
                                       env_name: "SENTRY_DSYM_PATHS",
                                       description: "Path to an array of your symbols file. For iOS and Mac provide path to app.dSYM.zip",
                                       default_value: Actions.lane_context[SharedValues::DSYM_PATHS],
                                       default_value_dynamic: true,
                                       type: Array,
                                       optional: true)
        ]
      end

      def self.return_value
        "The uploaded dSYM path(s)"
      end

      def self.authors
        ["joshdholtz"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end

      def self.example_code
        [
          'upload_symbols_to_sentry(
            auth_token: "...",
            org_slug: "...",
            project_slug: "...",
            dsym_path: "./App.dSYM.zip"
          )'
        ]
      end

      def self.category
        :deprecated
      end

      def self.deprecated_notes
        [
          "Please use the `sentry` plugin instead.",
          "Install using `fastlane add_plugin sentry`.",
          "Replace `upload_symbols_to_sentry(...)` with `sentry_upload_dsym(...)`."
        ].join("\n")
      end
    end
  end
end
