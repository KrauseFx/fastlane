module Fastlane
  module Actions
    module SharedValues
      TESTFAIRY_BUILD_URL = :TESTFAIRY_BUILD_URL
      TESTFAIRY_DOWNLOAD_URL = :TESTFAIRY_DOWNLOAD_URL
      TESTFAIRY_LANDING_PAGE = :TESTFAIRY_LANDING_PAGE
    end

    class TestfairyAction < Action
      def self.upload_build(upload_url, ipa, options, timeout)
        require 'faraday'
        require 'faraday_middleware'

        UI.success("Uploading to #{upload_url}...")

        connection = Faraday.new(url: upload_url) do |builder|
          builder.request(:multipart)
          builder.request(:url_encoded)
          builder.request(:retry, max: 3, interval: 5)
          builder.response(:json, content_type: /\bjson$/)
          builder.use(FaradayMiddleware::FollowRedirects)
          builder.adapter(:net_http)
        end

        options[:file] = Faraday::UploadIO.new(ipa, 'application/octet-stream') if ipa && File.exist?(ipa)

        symbols_file = options.delete(:symbols_file)
        if symbols_file
          options[:symbols_file] = Faraday::UploadIO.new(symbols_file, 'application/octet-stream')
        end

        begin
          connection.post do |req|
            req.options.timeout = timeout
            req.url("/api/upload/")
            req.body = options
          end
        rescue Faraday::TimeoutError
          UI.crash!("Uploading build to TestFairy timed out ⏳")
        end
      end

      def self.run(params)
        UI.success('Starting with ipa upload to TestFairy...')

        metrics_to_client = lambda do |metrics|
          metrics.map do |metric|
            case metric
            when :cpu, :memory, :network, :gps, :battery, :mic, :wifi
              metric.to_s
            when :phone_signal
              'phone-signal'
            else
              UI.user_error!("Unknown metric: #{metric}")
            end
          end
        end

        options_to_client = lambda do |options|
          options.map do |option|
            case option.to_sym
            when :shake, :anonymous
              option.to_s
            when :video_only_wifi
              'video-only-wifi'
            else
              UI.user_error!("Unknown option: #{option}")
            end
          end
        end

        # Rejecting key `upload_url` and `timeout` as we don't need it in options
        client_options = Hash[params.values.reject do |key, value|
          [:upload_url, :timeout].include?(key)
        end.map do |key, value|
          case key
          when :api_key
            [key, value]
          when :ipa
            [key, value]
          when :aab
            [key, value]
          when :apk
            [key, value]
          when :symbols_file
            [key, value]
          when :testers_groups
            [key, value.join(',')]
          when :metrics
            [key, metrics_to_client.call(value).join(',')]
          when :comment
            [key, value]
          when :auto_update
            ['auto-update', value]
          when :notify
            [key, value]
          when :options
            [key, options_to_client.call(value).join(',')]
          when :custom
            [key, value]
          when :tags
            [key, value.join(',')]
          when :folder_name
            [key, value]
          when :landing_page_mode
            [key, value]
          when :upload_to_saucelabs
            [key, value]
          when :platform
            [key, value]
          else
            UI.user_error!("Unknown parameter: #{key}")
          end
        end]

        path = params[:ipa] || params[:aab] || params[:apk]
        UI.user_error!("No ipa, aab or apk were given") unless path

        return path if Helper.test?

        response = self.upload_build(params[:upload_url], path, client_options, params[:timeout])
        if parse_response(response)
          UI.success("Build URL: #{Actions.lane_context[SharedValues::TESTFAIRY_BUILD_URL]}")
          UI.success("Download URL: #{Actions.lane_context[SharedValues::TESTFAIRY_DOWNLOAD_URL]}")
          UI.success("Landing Page URL: #{Actions.lane_context[SharedValues::TESTFAIRY_LANDING_PAGE]}")
          UI.success("Build successfully uploaded to TestFairy.")
        else
          UI.user_error!("Error when trying to upload ipa to TestFairy")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.parse_response(response)
        if response.body && response.body.key?('status') && response.body['status'] == 'ok'
          build_url = response.body['build_url']
          app_url = response.body['app_url']
          landing_page_url = response.body['landing_page_url']

          Actions.lane_context[SharedValues::TESTFAIRY_BUILD_URL] = build_url
          Actions.lane_context[SharedValues::TESTFAIRY_DOWNLOAD_URL] = app_url
          Actions.lane_context[SharedValues::TESTFAIRY_LANDING_PAGE] = landing_page_url

          return true
        else
          UI.error("Error uploading to TestFairy: #{response.body}")

          return false
        end
      end
      private_class_method :parse_response

      def self.description
        'Upload a new build to [TestFairy](https://www.testfairy.com/)'
      end

      def self.details
        "You can retrieve your API key on [your settings page](https://free.testfairy.com/settings/)"
      end

      def self.available_options
        [
          # required
          FastlaneCore::ConfigItem.new(key: :api_key,
                                       env_name: "FL_TESTFAIRY_API_KEY", # The name of the environment variable
                                       description: "API Key for TestFairy", # a short description of this parameter
                                       sensitive: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("No API key for TestFairy given, pass using `api_key: 'key'`") unless value.to_s.length > 0
                                       end),
          FastlaneCore::ConfigItem.new(key: :ipa,
                                       env_name: 'TESTFAIRY_IPA_PATH',
                                       description: 'Path to your IPA file for iOS',
                                       default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
                                       default_value_dynamic: true,
                                       optional: true,
                                       conflicting_options: [:aab, :apk],
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find ipa file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :apk,
                                       env_name: 'TESTFAIRY_APK_PATH',
                                       description: 'Path to your APK file for Android',
                                       default_value: Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH],
                                       default_value_dynamic: true,
                                       optional: true,
                                       conflicting_options: [:aab, :ipa],
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find apk file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :aab,
                                       env_name: 'TESTFAIRY_AAB_PATH',
                                       description: 'Path to your AAB file for Android',
                                       default_value: Actions.lane_context[SharedValues::GRADLE_AAB_OUTPUT_PATH],
                                       default_value_dynamic: true,
                                       optional: true,
                                       conflicting_options: [:apk, :ipa],
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find aab file at path '#{value}'") unless File.exist?(value)
                                       end),
          # optional
          FastlaneCore::ConfigItem.new(key: :symbols_file,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_SYMBOLS_FILE",
                                       description: "Symbols mapping file",
                                       default_value: Actions.lane_context[SharedValues::DSYM_OUTPUT_PATH],
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find dSYM file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :upload_url,
                                       env_name: "FL_TESTFAIRY_UPLOAD_URL", # The name of the environment variable
                                       description: "API URL for TestFairy", # a short description of this parameter
                                       default_value: "https://upload.testfairy.com",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :testers_groups,
                                       optional: true,
                                       type: Array,
                                       short_option: '-g',
                                       env_name: "FL_TESTFAIRY_TESTERS_GROUPS",
                                       description: "Array of tester groups to be notified",
                                       default_value: []), # the default value is an empty list
          FastlaneCore::ConfigItem.new(key: :metrics,
                                       optional: true,
                                       type: Array,
                                       env_name: "FL_TESTFAIRY_METRICS",
                                       description: "Array of metrics to record (cpu,memory,network,phone_signal,gps,battery,mic,wifi)",
                                       default_value: []),
          # max-duration
          # video
          # video-quality
          # video-rate
          FastlaneCore::ConfigItem.new(key: :comment,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_COMMENT",
                                       description: "Additional release notes for this upload. This text will be added to email notifications",
                                       default_value: 'No comment provided'), # the default value if the user didn't provide one
          FastlaneCore::ConfigItem.new(key: :auto_update,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_AUTO_UPDATE",
                                       description: "Allows an easy upgrade of all users to the current version. To enable set to 'on'",
                                       default_value: 'off'),
          # not well documented
          FastlaneCore::ConfigItem.new(key: :notify,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_NOTIFY",
                                       description: "Send email to testers",
                                       default_value: 'off'),
          FastlaneCore::ConfigItem.new(key: :options,
                                       optional: true,
                                       type: Array,
                                       env_name: "FL_TESTFAIRY_OPTIONS",
                                       description: "Array of options (shake,video_only_wifi,anonymous)",
                                       default_value: []),
          FastlaneCore::ConfigItem.new(key: :custom,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_CUSTOM",
                                       description: "Array of custom options. Contact support for more information",
                                       default_value: ''),
          FastlaneCore::ConfigItem.new(key: :timeout,
                                       env_name: "FL_TESTFAIRY_TIMEOUT",
                                       description: "Request timeout in seconds",
                                       type: Integer,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :tags,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_TAGS",
                                       description: "Custom tags that can be used to organize your builds",
                                       type: Array,
                                       default_value: []),
          FastlaneCore::ConfigItem.new(key: :folder_name,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_FOLDER_NAME",
                                       description: "Name of the dashboard folder that contains this app",
                                       default_value: ''),
          FastlaneCore::ConfigItem.new(key: :landing_page_mode,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_LANDING_PAGE_MODE",
                                       description: "Visibility of build landing after upload. Can be 'open' or 'closed'",
                                       default_value: 'open',
                                       verify_block: proc do |value|
                                         UI.user_error!("The landing page mode can only be open or closed") unless %w(open closed).include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :upload_to_saucelabs,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_UPLOAD_TO_SAUCELABS",
                                       description: "Upload file directly to Sauce Labs. It can be 'on' or 'off'",
                                       default_value: 'off',
                                       verify_block: proc do |value|
                                         UI.user_error!("The upload to Sauce Labs can only be on or off") unless %w(on off).include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :platform,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_PLATFORM",
                                       description: "Use if upload build is not iOS or Android. Contact support for more information",
                                       default_value: '')
        ]
      end

      def self.example_code
        [
          'testfairy(
            api_key: "...",
            ipa: "./ipa_file.ipa",
            comment: "Build #{lane_context[SharedValues::BUILD_NUMBER]}",
          )',
          'testfairy(
            api_key: "...",
            apk: "../build/app/outputs/apk/qa/release/app-qa-release.apk",
            comment: "Build #{lane_context[SharedValues::BUILD_NUMBER]}",
           )'
        ]
      end

      def self.category
        :beta
      end

      def self.output
        [
          ['TESTFAIRY_BUILD_URL', 'URL for the sessions of the newly uploaded build'],
          ['TESTFAIRY_DOWNLOAD_URL', 'URL directly to the newly uploaded build'],
          ['TESTFAIRY_LANDING_PAGE', 'URL of the build\'s landing page']
        ]
      end

      def self.authors
        ["taka0125", "tcurdt", "vijaysharm", "cdm2012"]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end
