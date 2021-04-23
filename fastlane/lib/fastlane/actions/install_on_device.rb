module Fastlane
  module Actions
    module SharedValues
    end

    class InstallOnDeviceAction < Action
      def self.run(params)
        unless Helper.test?
          UI.user_error!("ios-deploy not installed, see https://github.com/ios-control/ios-deploy for instructions") if `which ios-deploy`.length == 0
        end
        taxi_cmd = [
          "ios-deploy",
          params[:extra],
          "--bundle",
          params[:ipa].shellescape
        ]
        taxi_cmd << "--no-wifi" if params[:skip_wifi]
        taxi_cmd << ["--id", params[:device_id]] if params[:device_id]
        taxi_cmd.compact!
        return taxi_cmd.join(" ") if Helper.test?
        Actions.sh(taxi_cmd.join(" "))
        UI.message("Deployed #{params[:ipa]} to device!")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Installs an .ipa file on a connected iOS-device via usb or wifi"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :extra,
                                       short_option: "-X",
                                       env_name: "FL_IOD_EXTRA",
                                       description: "Extra Commandline arguments passed to ios-deploy",
                                       optional: true,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :device_id,
                                       short_option: "-d",
                                       env_name: "FL_IOD_DEVICE_ID",
                                       description: "id of the device / if not set defaults to first found device",
                                       optional: true,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :skip_wifi,
                                       short_option: "-w",
                                       env_name: "FL_IOD_WIFI",
                                       description: "Do not search for devices via WiFi",
                                       optional: true,
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :ipa,
                                       short_option: "-i",
                                       env_name: "FL_IOD_IPA",
                                       description: "The IPA file to put on the device",
                                       optional: true,
                                       is_string: true,
                                       default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH] || Dir["*.ipa"].first,
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         unless Helper.test?
                                           UI.user_error!("Could not find ipa file at path '#{value}'") unless File.exist?(value)
                                           UI.user_error!("'#{value}' doesn't seem to be an ipa file") unless value.end_with?(".ipa")
                                         end
                                       end)
        ]
      end

      def self.authors
        ["hjanuschka"]
      end

      def self.details
        "Installs the ipa on the device. If no id is given, the first found iOS device will be used. Works via USB or Wi-Fi. This requires `ios-deploy` to be installed. Please have a look at [ios-deploy](https://github.com/ios-control/ios-deploy). To quickly install it, use `npm -g i ios-deploy`"
      end

      def self.is_supported?(platform)
        platform == :ios
      end

      def self.example_code
        [
          'install_on_device(
            device_id: "a3be6c9ff7e5c3c6028597513243b0f933b876d4",
            ipa: "./app.ipa"
          )'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
