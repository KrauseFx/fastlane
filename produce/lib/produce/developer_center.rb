require 'spaceship'
require_relative 'module'

module Produce
  class DeveloperCenter
    SERVICE_ON = "on"
    SERVICE_OFF = "off"
    SERVICE_COMPLETE = "complete"
    SERVICE_UNLESS_OPEN = "unlessopen"
    SERVICE_UNTIL_FIRST_LAUNCH = "untilfirstauth"
    SERVICE_XCODE_5 = "xcode5_compatible"
    SERVICE_XCODE_6 = "xcode6_compatible"
    SERVICE_GAME_CENTER_IOS = "ios"
    SERVICE_GAME_CENTER_MACOS = "macos"
    SERVICE_PRIMARY_APP_CONSENT = "on"

    ALLOWED_SERVICES = {
      access_wifi: [SERVICE_ON, SERVICE_OFF],
      app_attest: [SERVICE_ON, SERVICE_OFF],
      app_group: [SERVICE_ON, SERVICE_OFF],
      apple_pay: [SERVICE_ON, SERVICE_OFF],
      associated_domains: [SERVICE_ON, SERVICE_OFF],
      auto_fill_credential: [SERVICE_ON, SERVICE_OFF],
      class_kit: [SERVICE_ON, SERVICE_OFF],
      cloud: [SERVICE_XCODE_5, SERVICE_XCODE_6],
      custom_network_protocol: [SERVICE_ON, SERVICE_OFF],
      data_protection: [
        SERVICE_COMPLETE,
        SERVICE_UNLESS_OPEN,
        SERVICE_UNTIL_FIRST_LAUNCH
      ],
      extended_virtual_address_space: [SERVICE_ON, SERVICE_OFF],
      game_center: [SERVICE_GAME_CENTER_IOS, SERVICE_GAME_CENTER_MACOS],
      health_kit: [SERVICE_ON, SERVICE_OFF],
      hls_interstitial_preview: [SERVICE_ON, SERVICE_OFF],
      home_kit: [SERVICE_ON, SERVICE_OFF],
      hotspot: [SERVICE_ON, SERVICE_OFF],
      in_app_purchase: [SERVICE_ON, SERVICE_OFF],
      inter_app_audio: [SERVICE_ON, SERVICE_OFF],
      low_latency_hls: [SERVICE_ON, SERVICE_OFF],
      managed_associated_domains: [SERVICE_ON, SERVICE_OFF],
      maps: [SERVICE_ON, SERVICE_OFF],
      multipath: [SERVICE_ON, SERVICE_OFF],
      network_extension: [SERVICE_ON, SERVICE_OFF],
      nfc_tag_reading: [SERVICE_ON, SERVICE_OFF],
      personal_vpn: [SERVICE_ON, SERVICE_OFF],
      passbook: [SERVICE_ON, SERVICE_OFF],
      push_notification: [SERVICE_ON, SERVICE_OFF],
      sign_in_with_apple: [SERVICE_PRIMARY_APP_CONSENT],
      siri_kit: [SERVICE_ON, SERVICE_OFF],
      system_extension: [SERVICE_ON, SERVICE_OFF],
      user_management: [SERVICE_ON, SERVICE_OFF],
      vpn_configuration: [SERVICE_ON, SERVICE_OFF],
      wallet: [SERVICE_ON, SERVICE_OFF],
      wireless_accessory: [SERVICE_ON, SERVICE_OFF],
      CarPlayAudioApp: [SERVICE_ON, SERVICE_OFF],
      CarPlayMessagingApp: [SERVICE_ON, SERVICE_OFF],
      CarPlayNavigationApp: [SERVICE_ON, SERVICE_OFF],
      CarPlayVoipCallingApp: [SERVICE_ON, SERVICE_OFF],
      CriticalAlerts: [SERVICE_ON, SERVICE_OFF],
      HotspotHelper: [SERVICE_ON, SERVICE_OFF],
    }

    def run
      login
      create_new_app
    end

    def create_new_app
      ENV["CREATED_NEW_APP_ID"] = Time.now.to_i.to_s
      if app_exists?
        UI.success("[DevCenter] App '#{Produce.config[:app_identifier]}' already exists, nothing to do on the Dev Center")
        ENV["CREATED_NEW_APP_ID"] = nil
        # Nothing to do here
      else
        app_name = Produce.config[:app_name]
        UI.message("Creating new app '#{app_name}' on the Apple Dev Center")

        app = Spaceship.app.create!(bundle_id: app_identifier,
                                         name: app_name,
                                         enable_services: enable_services,
                                         mac: platform == "osx")

        if app.name != Produce.config[:app_name]
          UI.important("Your app name includes non-ASCII characters, which are not supported by the Apple Developer Portal.")
          UI.important("To fix this a unique (internal) name '#{app.name}' has been created for you. Your app's real name '#{Produce.config[:app_name]}'")
          UI.important("will still show up correctly on App Store Connect and the App Store.")
        end

        UI.message("Created app #{app.app_id}")

        UI.crash!("Something went wrong when creating the new app - it's not listed in the apps list") unless app_exists?

        ENV["CREATED_NEW_APP_ID"] = Time.now.to_i.to_s

        UI.success("Finished creating new app '#{app_name}' on the Dev Center")
      end

      return true
    end

    def enable_services
      app_service = Spaceship.app_service
      enabled_clean_options = {}

      # "enabled_features" was deprecated in favor of "enable_services"
      config_enabled_services = Produce.config[:enable_services] || Produce.config[:enabled_features]

      config_enabled_services.each do |k, v|
        if k.to_sym == :data_protection
          case v
          when SERVICE_COMPLETE
            enabled_clean_options[app_service.data_protection.complete.service_id] = app_service.data_protection.complete
          when SERVICE_UNLESS_OPEN
            enabled_clean_options[app_service.data_protection.unlessopen.service_id] = app_service.data_protection.unlessopen
          when SERVICE_UNTIL_FIRST_LAUNCH
            enabled_clean_options[app_service.data_protection.untilfirstauth.service_id] = app_service.data_protection.untilfirstauth
          end
        elsif k.to_sym == :cloud
          case v
          when SERVICE_XCODE_5
            enabled_clean_options[app_service.cloud.xcode5_compatible.service_id] = app_service.cloud.xcode5_compatible
          when SERVICE_XCODE_6
            enabled_clean_options[app_service.cloud.xcode6_compatible.service_id] = app_service.cloud.xcode6_compatible
          end
        elsif k.to_sym == :game_center
          case v
          when SERVICE_GAME_CENTER_IOS
            enabled_clean_options[app_service.game_center.ios.service_id] = app_service.game_center.ios
          when SERVICE_GAME_CENTER_MACOS
            enabled_clean_options[app_service.game_center.macos.service_id] = app_service.game_center.macos
          end
        elsif k.to_sym == :sign_in_with_apple
          case v
          when SERVICE_GAME_CENTER_IOS
            enabled_clean_options[app_service.sign_in_with_apple.on.service_id] = app_service.sign_in_with_apple.on
          end
        else
          if v == SERVICE_ON
            enabled_clean_options[app_service.send(k.to_s).on.service_id] = app_service.send(k.to_s).on
          else
            enabled_clean_options[app_service.send(k.to_s).off.service_id] = app_service.send(k.to_s).off
          end
        end
      end
      enabled_clean_options
    end

    def app_identifier
      Produce.config[:app_identifier].to_s
    end

    private

    def platform
      # This was added to support creation of multiple platforms
      # Produce::ItunesConnect can take an array of platforms to create for App Store Connect
      # but the Developer Center is now platform agnostic so we choose any platform here
      #
      # Platform won't be needed at all in the future when this is change over to use Spaceship::ConnectAPI
      (Produce.config[:platforms] || []).first || Produce.config[:platform]
    end

    def app_exists?
      Spaceship.app.find(app_identifier, mac: platform == "osx") != nil
    end

    def login
      Spaceship.login(Produce.config[:username], nil)
      Spaceship.select_team
    end
  end
end
