require 'google/apis/playcustomapp_v1'
require 'supply'

module Fastlane
  module Actions
    class CreateAppOnManagedPlayStoreAction < Action
      def self.run(params)
        client = PlaycustomappClient.make_from_config(params: params)

        FastlaneCore::PrintTable.print_values(
          config: params,
          mask_keys: [:json_key_data],
          title: "Summary for create_app_on_managed_play_store"
        )

        client.create_app(
          app_title: params[:app_title],
          language_code: params[:language],
          developer_account: params[:developer_account_id],
          apk_path: params[:apk]
        )
      end

      def self.description
        "Create Managed Google Play Apps"
      end

      def self.authors
        ["janpio"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        "Create new apps on Managed Google Play."
      end

      def self.example_code
        [
          "create_app_on_managed_play_store(
            json_key: 'path/to/you/json/key/file',
            developer_account_id: 'developer_account_id', # obtained using the `get_managed_play_store_publishing_rights` action (or looking at the Play Console url)
            app_title: 'Your app title',
            language: 'en_US', # primary app language in BCP 47 format
            apk: '/files/app-release.apk'
          )"
        ]
      end

      def self.available_options
        [
          # Authorization
          FastlaneCore::ConfigItem.new(key: :json_key,
                                       env_name: "SUPPLY_JSON_KEY",
                                       short_option: "-j",
                                       conflicting_options: [:json_key_data],
                                       optional: true, # optional until it is possible specify either json_key OR json_key_data are required
                                       description: "The path to a file containing service account JSON, used to authenticate with Google",
                                       code_gen_sensitive: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:json_key_file),
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Could not find service account json file at path '#{File.expand_path(value)}'") unless File.exist?(File.expand_path(value))
                                         UI.user_error!("'#{value}' doesn't seem to be a JSON file") unless FastlaneCore::Helper.json_file?(File.expand_path(value))
                                       end),
          FastlaneCore::ConfigItem.new(key: :json_key_data,
                                       env_name: "SUPPLY_JSON_KEY_DATA",
                                       short_option: "-c",
                                       conflicting_options: [:json_key],
                                       optional: true,
                                       description: "The raw service account JSON data used to authenticate with Google",
                                       code_gen_sensitive: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:json_key_data_raw),
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         begin
                                           JSON.parse(value)
                                         rescue JSON::ParserError
                                           UI.user_error!("Could not parse service account json: JSON::ParseError")
                                         end
                                       end),
          FastlaneCore::ConfigItem.new(key: :access_token,
                                       env_name: "SUPPLY_ACCESS_TOKEN",
                                       conflicting_options: [:issuer, :key, :json_key_data, :json_key],
                                       optional: true, # alternative for :json_key
                                       description: "The access token, used to authenticate with Google",
                                       code_gen_sensitive: true),
          FastlaneCore::ConfigItem.new(key: :developer_account_id,
                                       short_option: "-k",
                                       env_name: "SUPPLY_DEVELOPER_ACCOUNT_ID",
                                       description: "The ID of your Google Play Console account. Can be obtained from the URL when you log in (`https://play.google.com/apps/publish/?account=...` or when you 'Obtain private app publishing rights' (https://developers.google.com/android/work/play/custom-app-api/get-started#retrieve_the_developer_account_id)",
                                       code_gen_sensitive: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:developer_account_id),
                                       default_value_dynamic: true),
          # APK
          FastlaneCore::ConfigItem.new(key: :apk,
                                       env_name: "SUPPLY_APK",
                                       description: "Path to the APK file to upload",
                                       short_option: "-b",
                                       code_gen_sensitive: true,
                                       default_value: Dir["*.apk"].last || Dir[File.join("app", "build", "outputs", "apk", "app-release.apk")].last,
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("No value found for 'apk'") if value.to_s.length == 0
                                         UI.user_error!("Could not find apk file at path '#{value}'") unless File.exist?(value)
                                         UI.user_error!("apk file is not an apk") unless value.end_with?('.apk')
                                       end),
          # Title
          FastlaneCore::ConfigItem.new(key: :app_title,
                                       env_name: "SUPPLY_APP_TITLE",
                                       short_option: "-q",
                                       description: "App Title"),
          # Language
          FastlaneCore::ConfigItem.new(key: :language,
                                       short_option: "-m",
                                       env_name: "SUPPLY_LANGUAGE",
                                       description: "Default app language (e.g. 'en_US')",
                                       default_value: "en_US",
                                       verify_block: proc do |language|
                                         unless Supply::Languages::ALL_LANGUAGES.include?(language)
                                           UI.user_error!("Please enter one of the available languages: #{Supply::Languages::ALL_LANGUAGES}")
                                         end
                                       end),
          # Google Play API
          FastlaneCore::ConfigItem.new(key: :root_url,
                                       env_name: "SUPPLY_ROOT_URL",
                                       description: "Root URL for the Google Play API. The provided URL will be used for API calls in place of https://www.googleapis.com/",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Could not parse URL '#{value}'") unless value =~ URI.regexp
                                       end),
          FastlaneCore::ConfigItem.new(key: :timeout,
                                       env_name: "SUPPLY_TIMEOUT",
                                       optional: true,
                                       description: "Timeout for read, open, and send (in seconds)",
                                       type: Integer,
                                       default_value: 300)
        ]
      end

      def self.is_supported?(platform)
        [:android].include?(platform)
      end

      def self.category
        :misc
      end
    end
  end
end

require 'supply/client'
class PlaycustomappClient < Supply::AbstractGoogleServiceClient
  SERVICE = Google::Apis::PlaycustomappV1::PlaycustomappService
  SCOPE = Google::Apis::PlaycustomappV1::AUTH_ANDROIDPUBLISHER

  #####################################################
  # @!group Create
  #####################################################

  def create_app(app_title: nil, language_code: nil, developer_account: nil, apk_path: nil)
    custom_app = Google::Apis::PlaycustomappV1::CustomApp.new(title: app_title, language_code: language_code)

    call_google_api do
      client.create_account_custom_app(
        developer_account,
        custom_app,
        upload_source: apk_path
      )
    end
  end
end
