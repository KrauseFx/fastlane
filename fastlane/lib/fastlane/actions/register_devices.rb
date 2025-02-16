require 'credentials_manager'

module Fastlane
  module Actions
    class RegisterDevicesAction < Action
      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.file_column_headers
        ['Device ID', 'Device Name', 'Device Platform']
      end

      def self.run(params)
        platform = Spaceship::ConnectAPI::BundleIdPlatform.map(params[:platform])

        if params[:devices]
          new_devices = params[:devices].map do |name, udid|
            [udid, name]
          end
        elsif params[:devices_file]
          require 'csv'

          devices_file = CSV.read(File.expand_path(File.join(params[:devices_file])), col_sep: "\t")
          unless devices_file.first == file_column_headers.first(2) || devices_file.first == file_column_headers
            UI.user_error!("Please provide a file according to the Apple Sample UDID file (https://developer.apple.com/account/resources/downloads/Multiple-Upload-Samples.zip)")
          end

          new_devices = devices_file.drop(1).map do |row|
            if row.count == 1
              UI.user_error!("Invalid device line, ensure you are using tabs (NOT spaces). See Apple's sample/spec here: https://developer.apple.com/account/resources/downloads/Multiple-Upload-Samples.zip")
            elsif !(2..3).cover?(row.count)
              UI.user_error!("Invalid device line, please provide a file according to the Apple Sample UDID file (https://developer.apple.com/account/resources/downloads/Multiple-Upload-Samples.zip)")
            end
            row
          end
        else
          UI.user_error!("You must pass either a valid `devices` or `devices_file`. Please check the readme.")
        end

        require 'spaceship'
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

        UI.message("Fetching list of currently registered devices...")
        existing_devices = Spaceship::ConnectAPI::Device.all

        device_objs = new_devices.map do |device|
          new_device_udid = device[0]
          new_device_name = device[1]
          new_device_platform = device[2]
          new_device_enabled = new_device_name.start_with?("#") === false
          if existing_devices.map(&:udid).map(&:downcase).include?(new_device_udid.downcase)
            UI.verbose("UDID #{new_device_udid} already exists - Skipping...")
            existing_device = existing_devices.select { |device| device.udid == new_device_udid }[0]
            if existing_device.name != new_device_name
                UI.message("UDID #{new_device_udid} update device status")
                try_set_device_status(udid: new_device_udid, name: new_device_name, enabled: new_device_enabled )
            end
            next
          end

          if !new_device_enabled
            UI.message("UDID #{new_device_udid} disabled")
            next
          end

          device_platform = platform

          device_platform_supported = !new_device_platform.nil? && self.is_supported?(new_device_platform.to_sym)
          if device_platform_supported
            if new_device_platform == "mac"
              device_platform = Spaceship::ConnectAPI::BundleIdPlatform::MAC_OS
            else
              device_platform = Spaceship::ConnectAPI::BundleIdPlatform::IOS
            end
          end

          try_create_device(name: new_device_name, platform: device_platform, udid: new_device_udid)

        end

        UI.success("Successfully registered new devices.")
        return device_objs
      end

      def self.try_create_device(name: nil, platform: nil, udid: nil)
        Spaceship::ConnectAPI::Device.find_or_create(udid, name: name, platform: platform)
      rescue => ex
        UI.error(ex.to_s)
        UI.crash!("Failed to register new device (name: #{name}, UDID: #{udid})")
      end

      def self.try_set_device_status(udid: nil, name: nil, enabled: nil)
        if enabled
          Spaceship::ConnectAPI::Device.enable(udid)
        else
          Spaceship::ConnectAPI::Device.disable(udid)
        end
        Spaceship::ConnectAPI::Device.rename(udid, name)
      rescue => ex
        UI.error(ex.to_s)
        UI.crash!("Failed to modify device (name: #{name}, UDID: #{udid})")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Registers new devices to the Apple Dev Portal"
      end

      def self.available_options
        user = CredentialsManager::AppfileConfig.try_fetch_value(:apple_dev_portal_id)
        user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)
        platform = Actions.lane_context[Actions::SharedValues::PLATFORM_NAME].to_s

        [
          FastlaneCore::ConfigItem.new(key: :devices,
                                       env_name: "FL_REGISTER_DEVICES_DEVICES",
                                       description: "A hash of devices, with the name as key and the UDID as value",
                                       type: Hash,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :devices_file,
                                       env_name: "FL_REGISTER_DEVICES_FILE",
                                       description: "Provide a path to a file with the devices to register. For the format of the file see the examples",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Could not find file '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :api_key_path,
                                       env_names: ["FL_REGISTER_DEVICES_API_KEY_PATH", "APP_STORE_CONNECT_API_KEY_PATH"],
                                       description: "Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)",
                                       optional: true,
                                       conflicting_options: [:api_key],
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find API key JSON file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :api_key,
                                       env_names: ["FL_REGISTER_DEVICES_API_KEY", "APP_STORE_CONNECT_API_KEY"],
                                       description: "Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)",
                                       type: Hash,
                                       default_value: Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::APP_STORE_CONNECT_API_KEY],
                                       default_value_dynamic: true,
                                       optional: true,
                                       sensitive: true,
                                       conflicting_options: [:api_key_path]),
          FastlaneCore::ConfigItem.new(key: :team_id,
                                     env_name: "REGISTER_DEVICES_TEAM_ID",
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_id),
                                       default_value_dynamic: true,
                                     description: "The ID of your Developer Portal team if you're in multiple teams",
                                     optional: true,
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_TEAM_ID"] = value.to_s
                                     end),
          FastlaneCore::ConfigItem.new(key: :team_name,
                                       env_name: "REGISTER_DEVICES_TEAM_NAME",
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
                                       default_value_dynamic: true),
          FastlaneCore::ConfigItem.new(key: :platform,
                                       env_name: "REGISTER_DEVICES_PLATFORM",
                                       description: "The platform to use (optional)",
                                       optional: true,
                                       default_value: platform.empty? ? "ios" : platform,
                                       verify_block: proc do |value|
                                         UI.user_error!("The platform can only be ios or mac") unless %w(ios mac).include?(value)
                                       end)
        ]
      end

      def self.details
        [
          "This will register iOS/Mac devices with the Developer Portal so that you can include them in your provisioning profiles.",
          "This is an optimistic action, in that it will only ever add new devices to the member center, and never remove devices. If a device which has already been registered within the member center is not passed to this action, it will be left alone in the member center and continue to work.",
          "The action will connect to the Apple Developer Portal using the username you specified in your `Appfile` with `apple_id`, but you can override it using the `username` option, or by setting the env variable `ENV['DELIVER_USER']`."
        ].join("\n")
      end

      def self.author
        "lmirosevic"
      end

      def self.example_code
        [
          'register_devices(
            devices: {
              "Luka iPhone 6" => "1234567890123456789012345678901234567890",
              "Felix iPad Air 2" => "abcdefghijklmnopqrstvuwxyzabcdefghijklmn"
            }
          ) # Simply provide a list of devices as a Hash',
          'register_devices(
            devices: {
              "#Felix iPad Air 2" => "abcdefghijklmnopqrstvuwxyzabcdefghijklmn"
            }
          ) # A hash at the beginning of the name means the device should be disabled',
          'register_devices(
            devices_file: "./devices.txt"
          ) # Alternatively provide a standard UDID export .txt file, see the Apple Sample (http://devimages.apple.com/downloads/devices/Multiple-Upload-Samples.zip)',
          'register_devices(
            devices_file: "./devices.txt", # You must pass in either `devices_file` or `devices`.
            team_id: "XXXXXXXXXX",         # Optional, if you"re a member of multiple teams, then you need to pass the team ID here.
            username: "luka@goonbee.com"   # Optional, lets you override the Apple Member Center username.
          )',
          'register_devices(
            devices: {
              "Luka MacBook" => "12345678-1234-1234-1234-123456789012",
              "Felix MacBook Pro" => "ABCDEFGH-ABCD-ABCD-ABCD-ABCDEFGHIJKL"
            },
            platform: "mac"
          ) # Register devices for Mac'
        ]
      end

      def self.category
        :code_signing
      end
    end
  end
end
