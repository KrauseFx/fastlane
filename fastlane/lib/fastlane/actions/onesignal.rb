module Fastlane
  module Actions
    module SharedValues
      ONE_SIGNAL_APP_ID = :ONE_SIGNAL_APP_ID
      ONE_SIGNAL_APP_AUTH_KEY = :ONE_SIGNAL_APP_AUTH_KEY
    end

    class OnesignalAction < Action
      def self.run(params)
        require 'net/http'
        require 'uri'
        require 'base64'

        app_id = params[:app_id].to_s.strip
        auth_token = params[:auth_token]
        app_name = params[:app_name].to_s
        apns_p12_password = params[:apns_p12_password]
        android_token = params[:android_token]
        android_gcm_sender_id = params[:android_gcm_sender_id]
        organization_id = params[:organization_id]

        has_app_id = !app_id.empty?
        has_app_name = !app_name.empty?

        is_update = has_app_id

        UI.user_error!('Please specify the `app_id` or the `app_name` parameters!') if !has_app_id && !has_app_name

        UI.message("Parameter App ID: #{app_id}") if has_app_id
        UI.message("Parameter App name: #{app_name}") if has_app_name

        payload = {}

        payload['name'] = app_name if has_app_name

        unless params[:apns_p12].nil?
          data = File.read(params[:apns_p12])
          apns_p12 = Base64.encode64(data)
          payload["apns_env"] = params[:apns_env]
          payload["apns_p12"] = apns_p12
          # we need to have something for the p12 password, even if it's an empty string
          payload["apns_p12_password"] = apns_p12_password || ""
        end

        unless params[:fcm_json].nil?
          data = File.read(params[:fcm_json])
          fcm_json = Base64.strict_encode64(data)
          payload["fcm_v1_service_account_json"] = fcm_json
        end

        payload["gcm_key"] = android_token unless android_token.nil?
        payload["android_gcm_sender_id"] = android_gcm_sender_id unless android_gcm_sender_id.nil?
        payload["organization_id"] = organization_id unless organization_id.nil?

        # here's the actual lifting - POST or PUT to OneSignal
        json_headers = { 'Content-Type' => 'application/json', 'Authorization' => "Key #{auth_token}" }
        url = +'https://api.onesignal.com/apps'
        url << '/' + app_id if is_update
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        if is_update
          response = http.put(uri.path, payload.to_json, json_headers)
        else
          response = http.post(uri.path, payload.to_json, json_headers)
        end

        response_body = JSON.parse(response.body)

        Actions.lane_context[SharedValues::ONE_SIGNAL_APP_ID] = response_body["id"]
        Actions.lane_context[SharedValues::ONE_SIGNAL_APP_AUTH_KEY] = response_body["basic_auth_key"]

        check_response_code(response, is_update)
      end

      def self.check_response_code(response, is_update)
        case response.code.to_i
        when 200, 204
          UI.success("Successfully #{is_update ? 'updated' : 'created new'} OneSignal app")
        else
          UI.user_error!("Unexpected #{response.code} with response: #{response.body}")
        end
      end

      def self.description
        "Create or update a new [OneSignal](https://onesignal.com/) application"
      end

      def self.details
        "You can use this action to automatically create or update a OneSignal application. You can also upload a `.p12` with password, a GCM key, or both."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :app_id,
                                       env_name: "ONE_SIGNAL_APP_ID",
                                       sensitive: true,
                                       description: "OneSignal App ID. Setting this updates an existing app",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :auth_token,
                                       env_name: "ONE_SIGNAL_AUTH_KEY",
                                       sensitive: true,
                                       description: "OneSignal Authorization Key",
                                       verify_block: proc do |value|
                                         if value.to_s.empty?
                                           UI.error("Please add 'ENV[\"ONE_SIGNAL_AUTH_KEY\"] = \"your token\"' to your Fastfile's `before_all` section.")
                                           UI.user_error!("No ONE_SIGNAL_AUTH_KEY given.")
                                         end
                                       end),

          FastlaneCore::ConfigItem.new(key: :app_name,
                                       env_name: "ONE_SIGNAL_APP_NAME",
                                       description: "OneSignal App Name. This is required when creating an app (in other words, when `:app_id` is not set, and optional when updating an app",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :android_token,
                                       env_name: "ANDROID_TOKEN",
                                       description: "ANDROID GCM KEY",
                                       sensitive: true,
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :android_gcm_sender_id,
                                       env_name: "ANDROID_GCM_SENDER_ID",
                                       description: "GCM SENDER ID",
                                       sensitive: true,
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :fcm_json,
                                       env_name: "FCM_JSON",
                                       description: "FCM Service Account JSON File (in .json format)",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :apns_p12,
                                       env_name: "APNS_P12",
                                       description: "APNS P12 File (in .p12 format)",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :apns_p12_password,
                                       env_name: "APNS_P12_PASSWORD",
                                       sensitive: true,
                                       description: "APNS P12 password",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :apns_env,
                                       env_name: "APNS_ENV",
                                       description: "APNS environment",
                                       optional: true,
                                       default_value: 'production'),

          FastlaneCore::ConfigItem.new(key: :organization_id,
                                       env_name: "ONE_SIGNAL_ORGANIZATION_ID",
                                       sensitive: true,
                                       description: "OneSignal Organization ID",
                                       optional: true)
        ]
      end

      def self.output
        [
          ['ONE_SIGNAL_APP_ID', 'The app ID of the newly created or updated app'],
          ['ONE_SIGNAL_APP_AUTH_KEY', 'The auth token for the newly created or updated app']
        ]
      end

      def self.authors
        ["timothybarraclough", "smartshowltd"]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end

      def self.example_code
        [
          'onesignal(
            auth_token: "Your OneSignal Auth Token",
            app_name: "Name for OneSignal App",
            android_token: "Your Android GCM key (optional)",
            android_gcm_sender_id: "Your Android GCM Sender ID (optional)",
            fcm_json: "Path to FCM Service Account JSON File (optional)",
            apns_p12: "Path to Apple .p12 file (optional)",
            apns_p12_password: "Password for .p12 file (optional)",
            apns_env: "production/sandbox (defaults to production)",
            organization_id: "Onesignal organization id (optional)"
          )',
          'onesignal(
            app_id: "Your OneSignal App ID",
            auth_token: "Your OneSignal Auth Token",
            app_name: "New Name for OneSignal App",
            android_token: "Your Android GCM key (optional)",
            android_gcm_sender_id: "Your Android GCM Sender ID (optional)",
            fcm_json: "Path to FCM Service Account JSON File (optional)",
            apns_p12: "Path to Apple .p12 file (optional)",
            apns_p12_password: "Password for .p12 file (optional)",
            apns_env: "production/sandbox (defaults to production)",
            organization_id: "Onesignal organization id (optional)"
          )'
        ]
      end

      def self.category
        :push
      end
    end
  end
end
