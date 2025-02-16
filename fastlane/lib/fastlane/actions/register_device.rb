require 'credentials_manager'

module Fastlane
  module Actions
    class RegisterDeviceAction < Action
      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.run(params)
        require 'spaceship'

        name = params[:name]
        platform = params[:platform]
        udid = params[:udid]

        platform = Spaceship::ConnectAPI::BundleIdPlatform.map(platform)

        if (api_token = Spaceship::ConnectAPI::Token.from(hash: params[:api_key], filepath: params[:api_key_path]))
          UI.message("Creating authorization token for App Store Connect API")
          Spaceship::ConnectAPI.token = api_token
        elsif !Spaceship::ConnectAPI.token.nil?
          UI.message("Using existing authorization token for App Store Connect API")
        else
          UI.message("Login to App Store Connect (#{params[:username]})")
          credentials = CredentialsManager::AccountManager.new(user: params[:username])
          Spaceship::ConnectAPI.login(credentials.user, credentials.password, use_portal: true, use_tunes: false)
          UI.message("Login successful")
        end

        begin
          Spaceship::ConnectAPI::Device.find_or_create(udid, name: name, platform: platform)
        rescue => ex
          UI.error(ex.to_s)
          UI.crash!("Failed to register new device (name: #{name}, platform: #{platform}, UDID: #{udid})")
        end

        UI.success("Successfully registered new device")
        return udid
      end

      def self.description
        "Registers a new device to the Apple Dev Portal"
      end

      def self.available_options
        user = CredentialsManager::AppfileConfig.try_fetch_value(:apple_dev_portal_id)
        user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)
        platform = Actions.lane_context[Actions::SharedValues::PLATFORM_NAME].to_s

        [
          FastlaneCore::ConfigItem.new(key: :name,
                                       env_name: "FL_REGISTER_DEVICE_NAME",
                                       description: "Provide the name of the device to register as"),
          FastlaneCore::ConfigItem.new(key: :platform,
                                       env_name: "FL_REGISTER_DEVICE_PLATFORM",
                                       description: "Provide the platform of the device to register as (ios, mac)",
                                       optional: true,
                                       default_value: platform.empty? ? "ios" : platform,
                                       verify_block: proc do |value|
                                         UI.user_error!("The platform can only be ios or mac") unless %w(ios mac).include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :udid,
                                       env_name: "FL_REGISTER_DEVICE_UDID",
                                       description: "Provide the UDID of the device to register as"),
          FastlaneCore::ConfigItem.new(key: :api_key_path,
                                       env_names: ["FL_REGISTER_DEVICE_API_KEY_PATH", "APP_STORE_CONNECT_API_KEY_PATH"],
                                       description: "Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)",
                                       optional: true,
                                       conflicting_options: [:api_key],
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find API key JSON file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :api_key,
                                       env_names: ["FL_REGISTER_DEVICE_API_KEY", "APP_STORE_CONNECT_API_KEY"],
                                       description: "Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)",
                                       type: Hash,
                                       default_value: Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::APP_STORE_CONNECT_API_KEY],
                                       default_value_dynamic: true,
                                       optional: true,
                                       sensitive: true,
                                       conflicting_options: [:api_key_path]),
          FastlaneCore::ConfigItem.new(key: :team_id,
                                     env_name: "REGISTER_DEVICE_TEAM_ID",
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_id),
                                       default_value_dynamic: true,
                                     description: "The ID of your Developer Portal team if you're in multiple teams",
                                     optional: true,
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_TEAM_ID"] = value.to_s
                                     end),
          FastlaneCore::ConfigItem.new(key: :team_name,
                                       env_name: "REGISTER_DEVICE_TEAM_NAME",
                                       description: "The name of your Developer Portal team if you're in multiple teams",
                                       optional: true,
                                       code_gen_sensitive: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_name),
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         ENV["FASTLANE_TEAM_NAME"] = value.to_s
                                       end),
          FastlaneCore::ConfigItem.new(key: :username,
                                       env_name: "DELIVER_USER",
                                       description: "Optional: Your Apple ID",
                                       optional: true,
                                       default_value: user,
                                       default_value_dynamic: true)
        ]
      end

      def self.details
        [
          "This will register an iOS device with the Developer Portal so that you can include it in your provisioning profiles.",
          "This is an optimistic action, in that it will only ever add a device to the member center. If the device has already been registered within the member center, it will be left alone in the member center.",
          "The action will connect to the Apple Developer Portal using the username you specified in your `Appfile` with `apple_id`, but you can override it using the `:username` option."
        ].join("\n")
      end

      def self.author
        "pvinis"
      end

      def self.example_code
        [
          'register_device(
            name: "Luka iPhone 6",
            udid: "1234567890123456789012345678901234567890"
          ) # Simply provide the name and udid of the device',
          'register_device(
            name: "Luka iPhone 6",
            udid: "1234567890123456789012345678901234567890",
            team_id: "XXXXXXXXXX",         # Optional, if you"re a member of multiple teams, then you need to pass the team ID here.
            username: "luka@goonbee.com"   # Optional, lets you override the Apple Member Center username.
          )'
        ]
      end

      def self.return_type
        :string
      end

      def self.category
        :code_signing
      end
    end
  end
end
