require 'supply/client'

module Fastlane
  module Actions
    class ValidatePlayStoreJsonKeyAction < Action
      def self.run(params)
        FastlaneCore::PrintTable.print_values(
          config: params,
          mask_keys: [:json_key_data],
          title: "Summary for validate_play_store_json_key"
        )

        begin
          client = Supply::Client.make_from_config(params: params)
          FastlaneCore::UI.success("Successfully established connection to Google Play Store.")
          FastlaneCore::UI.verbose("client: " + client.inspect)
        rescue => e
          UI.error("Could not establish a connection to Google Play Store with this json key file.")
          UI.error("#{e.message}\n#{e.backtrace.join("\n")}") if FastlaneCore::Globals.verbose?
        end
      end

      def self.description
        "Validate that the Google Play Store `json_key` works"
      end

      def self.authors
        ["janpio"]
      end

      def self.details
        "Use this action to test and validate your private key json key file used to connect and authenticate with the Google Play API"
      end

      def self.example_code
        [
          "validate_play_store_json_key(
            json_key: 'path/to/you/json/key/file'
          )"
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :json_key,
            env_name: "SUPPLY_JSON_KEY",
            short_option: "-j",
            conflicting_options: [:json_key_data],
            optional: true, # this shouldn't be optional but is until I find out how json_key OR json_key_data can be required
            description: "The path to a file containing service account JSON, used to authenticate with Google",
            code_gen_sensitive: true,
            default_value: CredentialsManager::AppfileConfig.try_fetch_value(:json_key_file),
            default_value_dynamic: true,
            verify_block: proc do |value|
              UI.user_error!("Could not find service account json file at path '#{File.expand_path(value)}'") unless File.exist?(File.expand_path(value))
              UI.user_error!("'#{value}' doesn't seem to be a JSON file") unless FastlaneCore::Helper.json_file?(File.expand_path(value))
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :json_key_data,
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
            end
          ),
          # stuff
          FastlaneCore::ConfigItem.new(key: :root_url,
            env_name: "SUPPLY_ROOT_URL",
            description: "Root URL for the Google Play API. The provided URL will be used for API calls in place of https://www.googleapis.com/",
            optional: true,
            verify_block: proc do |value|
              UI.user_error!("Could not parse URL '#{value}'") unless value =~ URI::DEFAULT_PARSER.make_regexp
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
