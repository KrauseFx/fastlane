require_relative '../model'
module Spaceship
  class ConnectAPI
    class BundleIdCapability
      include Spaceship::ConnectAPI::Model

      attr_accessor :capability_type
      attr_accessor :settings

      attr_mapping({
        "capabilityType" => "capability_type",
        "settings" => "settings"
      })

      module Type
        ACCESS_WIFI_INFORMATION = "ACCESS_WIFI_INFORMATION"
        APP_ATTEST = "APP_ATTEST"
        APP_GROUPS = "APP_GROUPS"
        APPLE_PAY = "APPLE_PAY"
        ASSOCIATED_DOMAINS = "ASSOCIATED_DOMAINS"
        AUTOFILL_CREDENTIAL_PROVIDER = "AUTOFILL_CREDENTIAL_PROVIDER"
        CLASSKIT = "CLASSKIT"
        ICLOUD = "ICLOUD"
        USERNOTIFICATIONS_COMMUNICATION = "USERNOTIFICATIONS_COMMUNICATION"
        NETWORK_CUSTOM_PROTOCOL = "NETWORK_CUSTOM_PROTOCOL"
        DATA_PROTECTION = "DATA_PROTECTION"
        EXTENDED_VIRTUAL_ADDRESSING = "EXTENDED_VIRTUAL_ADDRESSING"
        INCREASED_MEMORY_LIMIT = "INCREASED_MEMORY_LIMIT"
        INCREASED_MEMORY_LIMIT_DEBUGGING = "INCREASED_MEMORY_LIMIT_DEBUGGING"
        FAMILY_CONTROLS = "FAMILY_CONTROLS"
        FILEPROVIDER_TESTINGMODE = "FILEPROVIDER_TESTINGMODE"
        FONT_INSTALLATION = "FONT_INSTALLATION"
        GAME_CENTER = "GAME_CENTER"
        GROUP_ACTIVITIES = "GROUP_ACTIVITIES"
        HEALTHKIT = "HEALTHKIT"
        HEALTHKIT_RECALIBRATE_ESTIMATES = "HEALTHKIT_RECALIBRATE_ESTIMATES"
        HLS_INTERSTITIAL_PREVIEW = "HLS_INTERSTITIAL_PREVIEW"
        HOMEKIT = "HOMEKIT"
        HOT_SPOT = "HOT_SPOT"
        IN_APP_PURCHASE = "IN_APP_PURCHASE"
        INTER_APP_AUDIO = "INTER_APP_AUDIO"
        COREMEDIA_HLS_LOW_LATENCY = "COREMEDIA_HLS_LOW_LATENCY"
        MDM_MANAGED_ASSOCIATED_DOMAINS = "MDM_MANAGED_ASSOCIATED_DOMAINS"
        MAPS = "MAPS"
        MULTIPATH = "MULTIPATH"
        NETWORK_EXTENSIONS = "NETWORK_EXTENSIONS"
        NFC_TAG_READING = "NFC_TAG_READING"
        PERSONAL_VPN = "PERSONAL_VPN"
        PUSH_NOTIFICATIONS = "PUSH_NOTIFICATIONS"
        APPLE_ID_AUTH = "APPLE_ID_AUTH"
        SIRIKIT = "SIRIKIT"
        SYSTEM_EXTENSION_INSTALL = "SYSTEM_EXTENSION_INSTALL"
        USERNOTIFICATIONS_TIMESENSITIVE = "USERNOTIFICATIONS_TIMESENSITIVE"
        USER_MANAGEMENT = "USER_MANAGEMENT"
        WALLET = "WALLET"
        WIRELESS_ACCESSORY_CONFIGURATION = "WIRELESS_ACCESSORY_CONFIGURATION"

        # Additional Capabilities
        CARPLAY_PLAYABLE_CONTENT = "CARPLAY_PLAYABLE_CONTENT"
        CARPLAY_MESSAGING = "CARPLAY_MESSAGING"
        CARPLAY_NAVIGATION = "CARPLAY_NAVIGATION"
        CARPLAY_VOIP = "CARPLAY_VOIP"
        CRITICAL_ALERTS = "CRITICAL_ALERTS"
        HOTSPOT_HELPER_MANAGED = "HOTSPOT_HELPER_MANAGED"
        DRIVERKIT = "DRIVERKIT"
        DRIVERKIT_ENDPOINT_SECURITY = "DRIVERKIT_ENDPOINT_SECURITY"
        DRIVERKIT_HID_DEVICE = "DRIVERKIT_HID_DEVICE"
        DRIVERKIT_NETWORKING = "DRIVERKIT_NETWORKING"
        DRIVERKIT_SERIAL = "DRIVERKIT_SERIAL"
        DRIVERKIT_HID_EVENT_SERVICE = "DRIVERKIT_HID_EVENT_SERVICE"
        DRIVERKIT_HID = "DRIVERKIT_HID"
        IPAD_CAMERA_MULTITASKING = "IPAD_CAMERA_MULTITASKING"
        SFUNIVERSALLINK_API = "SFUNIVERSALLINK_API"
        VP9_DECODER = "VP9_DECODER"

        # App Services
        MUSIC_KIT = "MUSIC_KIT"
        SHAZAM_KIT = "SHAZAM_KIT"

        # Undocumented as of 2020-06-09
        MARZIPAN = "MARZIPAN" # Catalyst
      end

      module Settings
        ICLOUD_VERSION = "ICLOUD_VERSION"
        DATA_PROTECTION_PERMISSION_LEVEL = "DATA_PROTECTION_PERMISSION_LEVEL"
        APPLE_ID_AUTH_APP_CONSENT = "APPLE_ID_AUTH_APP_CONSENT"
        GAME_CENTER_SETTING = "GAME_CENTER_SETTING"
      end

      module Options
        XCODE_5 = "XCODE_5"
        XCODE_6 = "XCODE_6"
        COMPLETE_PROTECTION = "COMPLETE_PROTECTION"
        PROTECTED_UNLESS_OPEN = "PROTECTED_UNLESS_OPEN"
        PROTECTED_UNTIL_FIRST_USER_AUTH = "PROTECTED_UNTIL_FIRST_USER_AUTH"
        PRIMARY_APP_CONSENT = "PRIMARY_APP_CONSENT"
        GAME_CENTER_MAC = "GAME_CENTER_MAC"
        GAME_CENTER_IOS = "GAME_CENTER_IOS"
      end

      def self.type
        return "bundleIdCapabilities"
      end

      #
      # Helpers
      #

      def is_type?(type)
        # JWT session returns type under "capability_type" attribute
        # Web session returns type under "id" attribute but with "P7GJR49W72_" prefixed
        return capability_type == type || id.end_with?(type)
      end

      #
      # API
      #

      def self.all(client: nil, bundle_id_id:, limit: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.get_bundle_id_capabilities(bundle_id_id: bundle_id_id, limit: limit).all_pages
        return resp.flat_map(&:to_models)
      end

      def self.create(client: nil, bundle_id_id:, capability_type:, settings: [])
        client ||= Spaceship::ConnectAPI
        resp = client.post_bundle_id_capability(bundle_id_id: bundle_id_id, capability_type: capability_type, settings: settings)
        return resp.to_models.first
      end

      def delete!(client: nil, filter: {}, includes: nil, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        client.delete_bundle_id_capability(bundle_id_capability_id: id)
      end
    end
  end
end
