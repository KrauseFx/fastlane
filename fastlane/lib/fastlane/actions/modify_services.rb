module Fastlane
  module Actions
    class ModifyServicesAction < Action
      def self.run(params)
        require 'produce'

        Produce.config = params

        Dir.chdir(FastlaneCore::FastlaneFolder.path || Dir.pwd) do
          require 'produce/service'
          services = params[:services]

          enabled_services = services.select { |_k, v| v == true || (v != false && v.to_s != 'off') }.map { |k, v| [k, v == true || v.to_s == 'on' ? 'on' : v] }.to_h
          disabled_services = services.select { |_k, v| v == false || v.to_s == 'off' }.map { |k, v| [k, 'off'] }.to_h

          enabled_services_object = self.service_object
          enabled_services.each do |k, v|
            enabled_services_object.__hash__[k] = true
            enabled_services_object.send("#{k}=", v)
          end
          Produce::Service.enable(enabled_services_object, nil) unless enabled_services.empty?

          disabled_services_object = self.service_object
          disabled_services.each do |k, v|
            disabled_services_object.__hash__[k] = true
            disabled_services_object.send("#{k}=", v)
          end
          Produce::Service.disable(disabled_services_object, nil) unless disabled_services.empty?
        end
      end

      def self.service_object
        service_object = Object.new
        service_object.class.module_eval { attr_accessor :__hash__ }
        service_object.__hash__ = {}
        Produce::DeveloperCenter::ALLOWED_SERVICES.keys.each do |service|
          name = self.services_mapping[service]
          service_object.class.module_eval { attr_accessor :"#{name}" }
        end
        service_object
      end

      def self.services_mapping
        {
          access_wifi: 'access_wifi',
          app_attest: 'app_attest',
          app_group: 'app_group',
          apple_pay: 'apple_pay',
          associated_domains: 'associated_domains',
          auto_fill_credential: 'auto_fill_credential',
          class_kit: 'class_kit',
          icloud: 'icloud',
          custom_network_protocol: 'custom_network_protocol',
          data_protection: 'data_protection',
          extended_virtual_address_space: 'extended_virtual_address_space',
    increased_memory_limit: 'increased_memory_limit',
    increased_memory_limit_debugging: 'increased_memory_limit_debugging',
          family_controls: 'family_controls',
          file_provider_testing_mode: 'file_provider_testing_mode',
          fonts: 'fonts',
          game_center: 'game_center',
          health_kit: 'health_kit',
          hls_interstitial_preview: 'hls_interstitial_preview',
          home_kit: 'home_kit',
          hotspot: 'hotspot',
          in_app_purchase: 'in_app_purchase',
          inter_app_audio: 'inter_app_audio',
          low_latency_hls: 'low_latency_hls',
          managed_associated_domains: 'managed_associated_domains',
          maps: 'maps',
          multipath: 'multipath',
          network_extension: 'network_extension',
          nfc_tag_reading: 'nfc_tag_reading',
          personal_vpn: 'personal_vpn',
          passbook: 'passbook',
          push_notification: 'push_notification',
          sign_in_with_apple: 'sign_in_with_apple',
          siri_kit: 'siri_kit',
          system_extension: 'system_extension',
          user_management: 'user_management',
          vpn_configuration: 'vpn_configuration',
          wallet: 'wallet',
          wireless_accessory: 'wireless_accessory',
          car_play_audio_app: 'car_play_audio_app',
          car_play_messaging_app: 'car_play_messaging_app',
          car_play_navigation_app: 'car_play_navigation_app',
          car_play_voip_calling_app: 'car_play_voip_calling_app',
          critical_alerts: 'critical_alerts',
          hotspot_helper: 'hotspot_helper',
          driver_kit: 'driver_kit',
          driver_kit_endpoint_security: 'driver_kit_endpoint_security',
          driver_kit_family_hid_device: 'driver_kit_family_hid_device',
          driver_kit_family_networking: 'driver_kit_family_networking',
          driver_kit_family_serial: 'driver_kit_family_serial',
          driver_kit_hid_event_service: 'driver_kit_hid_event_service',
          driver_kit_transport_hid: 'driver_kit_transport_hid',
          multitasking_camera_access: 'multitasking_camera_access',
          sf_universal_link_api: 'sf_universal_link_api',
          vp9_decoder: 'vp9_decoder',
          music_kit: 'music_kit',
          shazam_kit: 'shazam_kit',
          communication_notifications: 'communication_notifications',
          group_activities: 'group_activities',
          health_kit_estimate_recalibration: 'health_kit_estimate_recalibration',
          time_sensitive_notifications: 'time_sensitive_notifications'
        }
      end

      def self.allowed_services_description
        return Produce::DeveloperCenter::ALLOWED_SERVICES.map do |k, v|
          "#{k}: (#{v.join('|')})(:on|:off)(true|false)"
        end.join(", ")
      end

      def self.description
        'Modifies the services of the app created on Developer Portal'
      end

      def self.details
        [
          "The options are the same as `:enable_services` in the [produce action](https://docs.fastlane.tools/actions/produce/#parameters_1)"
        ].join("\n")
      end

      def self.available_options
        require 'produce'
        user = CredentialsManager::AppfileConfig.try_fetch_value(:apple_dev_portal_id)
        user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)
        [
          FastlaneCore::ConfigItem.new(key: :username,
                                       short_option: "-u",
                                       env_name: "PRODUCE_USERNAME",
                                       description: "Your Apple ID Username",
                                       default_value: user,
                                       default_value_dynamic: true),
          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                       env_name: "PRODUCE_APP_IDENTIFIER",
                                       short_option: "-a",
                                       description: "App Identifier (Bundle ID, e.g. com.krausefx.app)",
                                       code_gen_sensitive: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier),
                                       default_value_dynamic: true),
          FastlaneCore::ConfigItem.new(key: :services,
                                       display_in_shell: false,
                                       env_name: "PRODUCE_ENABLE_SERVICES",
                                       description: "Array with Spaceship App Services (e.g. #{allowed_services_description})",
                                       type: Hash,
                                       default_value: {},
                                       verify_block: proc do |value|
                                         allowed_keys = Produce::DeveloperCenter::ALLOWED_SERVICES.keys
                                         UI.user_error!("enable_services has to be of type Hash") unless value.kind_of?(Hash)
                                         value.each do |key, v|
                                           UI.user_error!("The key: '#{key}' is not supported in `enable_services' - following keys are available: [#{allowed_keys.join(',')}]") unless allowed_keys.include?(key.to_sym)
                                         end
                                       end),
          FastlaneCore::ConfigItem.new(key: :team_id,
                                       short_option: "-b",
                                       env_name: "PRODUCE_TEAM_ID",
                                       description: "The ID of your Developer Portal team if you're in multiple teams",
                                       optional: true,
                                       code_gen_sensitive: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_id),
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         ENV["FASTLANE_TEAM_ID"] = value.to_s
                                       end),
          FastlaneCore::ConfigItem.new(key: :team_name,
                                       short_option: "-l",
                                       env_name: "PRODUCE_TEAM_NAME",
                                       description: "The name of your Developer Portal team if you're in multiple teams",
                                       optional: true,
                                       code_gen_sensitive: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_name),
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         ENV["FASTLANE_TEAM_NAME"] = value.to_s
                                       end)
        ]
      end

      def self.author
        "bhimsenpadalkar"
      end

      def self.is_supported?(platform)
        platform == :ios
      end

      def self.example_code
        [
          'modify_services(
            username: "test.account@gmail.com",
            app_identifier: "com.someorg.app",
            services: {
              push_notification: "on",
              associated_domains: "off",
              wallet: :on,
              apple_pay: :off,
              data_protection: true,
              multipath: false
            })'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
