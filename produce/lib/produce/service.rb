require 'spaceship'
require_relative 'module'

# rubocop:disable Metrics/ClassLength
module Produce
  class Service
    include Spaceship::ConnectAPI::BundleIdCapability::Type
    include Spaceship::ConnectAPI::BundleIdCapability::Settings
    include Spaceship::ConnectAPI::BundleIdCapability::Options

    def self.enable(options, args)
      self.new.enable(options, args)
    end

    def self.disable(options, args)
      self.new.disable(options, args)
    end

    def self.available_services(options, args)
      self.new.available_services(options, args)
    end

    def enable(options, _args)
      unless bundle_id
        UI.message("[DevCenter] App '#{Produce.config[:app_identifier]}' does not exist")
        return
      end

      UI.success("[DevCenter] App found '#{bundle_id.name}'")
      UI.message("Enabling services")
      enabled = update(true, options)
      UI.success("Done! Enabled #{enabled} services.")
    end

    def disable(options, _args)
      unless bundle_id
        UI.message("[DevCenter] App '#{Produce.config[:app_identifier]}' does not exist")
        return
      end

      UI.success("[DevCenter] App found '#{bundle_id.name}'")
      UI.message("Disabling services")
      disabled = update(false, options)
      UI.success("Done! Disabled #{disabled} services.")
    end

    def available_services(options, _args)
      unless bundle_id
        UI.message("[DevCenter] App '#{Produce.config[:app_identifier]}' does not exist")
        return
      end

      UI.success("[DevCenter] App found '#{bundle_id.name}'")
      UI.message("Fetching available services")
      return Spaceship::ConnectAPI::Capabilities.all
    end

    def valid_services_for(options)
      allowed_keys = [:access_wifi, :app_attest, :app_group, :apple_pay, :associated_domains, :auto_fill_credential, :car_play_audio_app, :car_play_messaging_app,
                      :car_play_navigation_app, :car_play_voip_calling_app, :class_kit, :icloud, :critical_alerts, :custom_network_protocol, :data_protection,
                      :extended_virtual_address_space, :file_provider_testing_mode, :family_controls, :fonts, :game_center, :health_kit, :hls_interstitial_preview, :home_kit, :hotspot,
                      :hotspot_helper, :in_app_purchase, :inter_app_audio, :low_latency_hls, :managed_associated_domains, :maps, :multipath, :network_extension,
                      :nfc_tag_reading, :passbook, :personal_vpn, :push_notification, :sign_in_with_apple, :siri_kit, :system_extension, :user_management, :vpn_configuration, :wallet,
                      :wireless_accessory, :driver_kit, :driver_kit_endpoint_security, :driver_kit_family_hid_device, :driver_kit_family_networking, :driver_kit_family_serial,
                      :driver_kit_hid_event_service, :driver_kit_transport_hid, :multitasking_camera_access, :sf_universal_link_api, :vp9_decoder, :music_kit, :shazam_kit,
                      :communication_notifications, :group_activities, :health_kit_estimate_recalibration, :time_sensitive_notifications, :increased_memory_limit, :increased_memory_limit_debugging]
      options.__hash__.select { |key, value| allowed_keys.include?(key) }
    end

    # @return (Hash) Settings configuration for a key-settings combination
    # @example
    #   [{
    #      key: "DATA_PROTECTION_PERMISSION_LEVEL",
    #      options:
    #      [
    #        {
    #          key: "COMPLETE_PROTECTION"
    #        }
    #      ]
    #    }]
    def build_settings_for(settings_key:, options_key:)
      return [{
       key: settings_key,
       options: [ {
           key: options_key
         } ]
      }]
    end

    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Require/MissingRequireStatement
    def update(on, options)
      updated = valid_services_for(options).count

      if options.access_wifi
        UI.message("\tAccess WiFi")
        bundle_id.update_capability(ACCESS_WIFI_INFORMATION, enabled: on)
      end

      if options.app_attest
        UI.message("\tApp Attest")
        bundle_id.update_capability(APP_ATTEST, enabled: on)
      end

      if options.app_group
        UI.message("\tApp Groups")
        bundle_id.update_capability(APP_GROUPS, enabled: on)
      end

      if options.apple_pay
        UI.message("\tApple Pay")
        bundle_id.update_capability(APPLE_PAY, enabled: on)
      end

      if options.associated_domains
        UI.message("\tAssociated Domains")
        bundle_id.update_capability(ASSOCIATED_DOMAINS, enabled: on)
      end

      if options.auto_fill_credential
        UI.message("\tAutoFill Credential")
        bundle_id.update_capability(AUTOFILL_CREDENTIAL_PROVIDER, enabled: on)
      end

      if options.car_play_audio_app
        UI.message("\tCarPlay Audio App")
        bundle_id.update_capability(CARPLAY_PLAYABLE_CONTENT, enabled: on)
      end

      if options.car_play_messaging_app
        UI.message("\tCarPlay Messaging App")
        bundle_id.update_capability(CARPLAY_MESSAGING, enabled: on)
      end

      if options.car_play_navigation_app
        UI.message("\tCarPlay Navigation App")
        bundle_id.update_capability(CARPLAY_NAVIGATION, enabled: on)
      end

      if options.car_play_voip_calling_app
        UI.message("\tCarPlay Voip Calling App")
        bundle_id.update_capability(CARPLAY_VOIP, enabled: on)
      end

      if options.class_kit
        UI.message("\tClassKit")
        bundle_id.update_capability(CLASSKIT, enabled: on)
      end

      if options.critical_alerts
        UI.message("\tCritical Alerts")
        bundle_id.update_capability(CRITICAL_ALERTS, enabled: on)
      end

      if options.custom_network_protocol
        UI.message("\tCustom Network Protocol")
        bundle_id.update_capability(NETWORK_CUSTOM_PROTOCOL, enabled: on)
      end

      if options.data_protection
        UI.message("\tData Protection")

        settings = []
        case options.data_protection
        when "complete"
          settings = build_settings_for(settings_key: DATA_PROTECTION_PERMISSION_LEVEL, options_key: COMPLETE_PROTECTION)
        when "unlessopen"
          settings = build_settings_for(settings_key: DATA_PROTECTION_PERMISSION_LEVEL, options_key: PROTECTED_UNLESS_OPEN)
        when "untilfirstauth"
          settings = build_settings_for(settings_key: DATA_PROTECTION_PERMISSION_LEVEL, options_key: PROTECTED_UNTIL_FIRST_USER_AUTH)
        else
          UI.user_error!("Unknown service '#{options.data_protection}'. Valid values: 'complete', 'unlessopen', 'untilfirstauth'") unless options.data_protection == true || options.data_protection == false
        end
        bundle_id.update_capability(DATA_PROTECTION, enabled: on, settings: settings)
      end

      if options.extended_virtual_address_space
        UI.message("\tExtended Virtual Address Space")
        bundle_id.update_capability(EXTENDED_VIRTUAL_ADDRESSING, enabled: on)
      end

      if options.increased_memory_limit
        UI.message("\tIncreased Memory Limit")
        bundle_id.update_capability(INCREASED_MEMORY_LIMIT, enabled: on)
      end

      if options.increased_memory_limit_debugging
        UI.message("\tIncreased Debugging Memory Limit")
        bundle_id.update_capability(INCREASED_MEMORY_LIMIT_DEBUGGING, enabled: on)
      end

      if options.family_controls
        UI.message("\tFamily Controls")
        bundle_id.update_capability(FAMILY_CONTROLS, enabled: on)
      end

      if options.file_provider_testing_mode
        UI.message("\tFile Provider Testing Mode")
        bundle_id.update_capability(FILEPROVIDER_TESTINGMODE, enabled: on)
      end

      if options.fonts
        UI.message("\tFonts")
        bundle_id.update_capability(FONT_INSTALLATION, enabled: on)
      end

      if options.game_center
        UI.message("\tGame Center")

        settings = []
        case options.game_center
        when "mac"
          settings = build_settings_for(settings_key: GAME_CENTER_SETTING, options_key: GAME_CENTER_MAC)
        when "ios"
          settings = build_settings_for(settings_key: GAME_CENTER_SETTING, options_key: GAME_CENTER_IOS)
        else
          UI.user_error!("Unknown service '#{options.game_center}'. Valid values: 'ios', 'mac'") unless options.game_center == true || options.game_center == false
        end
        bundle_id.update_capability(GAME_CENTER, enabled: on, settings: settings)
      end

      if options.health_kit
        UI.message("\tHealthKit")
        bundle_id.update_capability(HEALTHKIT, enabled: on)
      end

      if options.hls_interstitial_preview
        UI.message("\tHLS Interstitial Preview")
        bundle_id.update_capability(HLS_INTERSTITIAL_PREVIEW, enabled: on)
      end

      if options.home_kit
        UI.message("\tHomeKit")
        bundle_id.update_capability(HOMEKIT, enabled: on)
      end

      if options.hotspot
        UI.message("\tHotspot")
        bundle_id.update_capability(HOT_SPOT, enabled: on)
      end

      if options.hotspot_helper
        UI.message("\tHotspot Helper")
        bundle_id.update_capability(HOTSPOT_HELPER_MANAGED, enabled: on)
      end

      if options.icloud
        UI.message("\tiCloud")

        settings = []
        case options.icloud
        when "xcode6_compatible"
          settings = build_settings_for(settings_key: ICLOUD_VERSION, options_key: XCODE_6)
        when "xcode5_compatible"
          settings = build_settings_for(settings_key: ICLOUD_VERSION, options_key: XCODE_5)
        else
          UI.user_error!("Unknown service '#{options.icloud}'. Valid values: 'xcode6_compatible', 'xcode5_compatible', 'off'") unless options.icloud == true || options.icloud == false
        end
        bundle_id.update_capability(ICLOUD, enabled: on, settings: settings)
      end

      if options.in_app_purchase
        UI.message("\tIn-App Purchase")
        bundle_id.update_capability(IN_APP_PURCHASE, enabled: on)
      end

      if options.inter_app_audio
        UI.message("\tInter-App Audio")
        bundle_id.update_capability(INTER_APP_AUDIO, enabled: on)
      end

      if options.low_latency_hls
        UI.message("\tLow Latency HLS")
        bundle_id.update_capability(COREMEDIA_HLS_LOW_LATENCY, enabled: on)
      end

      if options.managed_associated_domains
        UI.message("\tManaged Associated Domains")
        bundle_id.update_capability(MDM_MANAGED_ASSOCIATED_DOMAINS, enabled: on)
      end

      if options.maps
        UI.message("\tMaps")
        bundle_id.update_capability(MAPS, enabled: on)
      end

      if options.multipath
        UI.message("\tMultipath")
        bundle_id.update_capability(MULTIPATH, enabled: on)
      end

      if options.network_extension
        UI.message("\tNetwork Extension")
        bundle_id.update_capability(NETWORK_EXTENSIONS, enabled: on)
      end

      if options.nfc_tag_reading
        UI.message("\tNFC Tag Reading")
        bundle_id.update_capability(NFC_TAG_READING, enabled: on)
      end

      if options.personal_vpn
        UI.message("\tPersonal VPN")
        bundle_id.update_capability(PERSONAL_VPN, enabled: on)
      end

      if options.push_notification
        UI.message("\tPush Notifications")
        bundle_id.update_capability(PUSH_NOTIFICATIONS, enabled: on)
      end

      if options.sign_in_with_apple
        UI.message("\tSign In With Apple")
        settings = build_settings_for(settings_key: APPLE_ID_AUTH_APP_CONSENT, options_key: PRIMARY_APP_CONSENT)
        bundle_id.update_capability(APPLE_ID_AUTH, enabled: on, settings: settings)
      end

      if options.siri_kit
        UI.message("\tSiriKit")
        bundle_id.update_capability(SIRIKIT, enabled: on)
      end

      if options.system_extension
        UI.message("\tSystem Extension")
        bundle_id.update_capability(SYSTEM_EXTENSION_INSTALL, enabled: on)
      end

      if options.user_management
        UI.message("\tUser Management")
        bundle_id.update_capability(USER_MANAGEMENT, enabled: on)
      end

      if options.wallet
        UI.message("\tWallet")
        bundle_id.update_capability(WALLET, enabled: on)
      end

      if options.wireless_accessory
        UI.message("\tWireless Accessory Configuration")
        bundle_id.update_capability(WIRELESS_ACCESSORY_CONFIGURATION, enabled: on)
      end

      if options.driver_kit
        UI.message("\tDriverKit")
        bundle_id.update_capability(DRIVERKIT, enabled: on)
      end

      if options.driver_kit_endpoint_security
        UI.message("\tDriverKit Endpoint Security")
        bundle_id.update_capability(DRIVERKIT_ENDPOINT_SECURITY, enabled: on)
      end

      if options.driver_kit_family_hid_device
        UI.message("\tDriverKit Family HID Device")
        bundle_id.update_capability(DRIVERKIT_HID_DEVICE, enabled: on)
      end

      if options.driver_kit_family_networking
        UI.message("\tDriverKit Family Networking")
        bundle_id.update_capability(DRIVERKIT_NETWORKING, enabled: on)
      end

      if options.driver_kit_family_serial
        UI.message("\tDriverKit Family Serial")
        bundle_id.update_capability(DRIVERKIT_SERIAL, enabled: on)
      end

      if options.driver_kit_hid_event_service
        UI.message("\tDriverKit HID EventService")
        bundle_id.update_capability(DRIVERKIT_HID_EVENT_SERVICE, enabled: on)
      end

      if options.driver_kit_transport_hid
        UI.message("\tDriverKit Transport HID")
        bundle_id.update_capability(DRIVERKIT_HID, enabled: on)
      end

      if options.multitasking_camera_access
        UI.message("\tMultitasking Camera Access")
        bundle_id.update_capability(IPAD_CAMERA_MULTITASKING, enabled: on)
      end

      if options.sf_universal_link_api
        UI.message("\tSFUniversalLink API")
        bundle_id.update_capability(SFUNIVERSALLINK_API, enabled: on)
      end

      if options.vp9_decoder
        UI.message("\tVP9 Decoder")
        bundle_id.update_capability(VP9_DECODER, enabled: on)
      end

      if options.music_kit
        UI.message("\tMusicKit")
        bundle_id.update_capability(MUSIC_KIT, enabled: on)
      end

      if options.shazam_kit
        UI.message("\tShazamKit")
        bundle_id.update_capability(SHAZAM_KIT, enabled: on)
      end

      if options.communication_notifications
        UI.message("\tCommunication Notifications")
        bundle_id.update_capability(USERNOTIFICATIONS_COMMUNICATION, enabled: on)
      end

      if options.group_activities
        UI.message("\tGroup Activities")
        bundle_id.update_capability(GROUP_ACTIVITIES, enabled: on)
      end

      if options.health_kit_estimate_recalibration
        UI.message("\tHealthKit Estimate Recalibration")
        bundle_id.update_capability(HEALTHKIT_RECALIBRATE_ESTIMATES, enabled: on)
      end

      if options.time_sensitive_notifications
        UI.message("\tTime Sensitive Notifications")
        bundle_id.update_capability(USERNOTIFICATIONS_TIMESENSITIVE, enabled: on)
      end

      updated
    end

    def bundle_id
      return @bundle_id if @bundle_id
      UI.message("Starting login with user '#{Produce.config[:username]}'")
      Spaceship.login(Produce.config[:username], nil)
      Spaceship.select_team
      UI.message("Successfully logged in")
      @bundle_id ||= Spaceship::ConnectAPI::BundleId.find(Produce.config[:app_identifier].to_s)
    end
  end
end
