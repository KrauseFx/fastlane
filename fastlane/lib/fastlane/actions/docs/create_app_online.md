<p align="center">
  <img src="/img/actions/produce.png" width="250">
</p>

###### Create new iOS apps on App Store Connect and Apple Developer Portal using your command line

_produce_ creates new iOS apps on both the Apple Developer Portal and App Store Connect with the minimum required information.

-------

<p align="center">
    <a href="#features">Features</a> &bull;
    <a href="#usage">Usage</a> &bull;
    <a href="#how-does-it-work">How does it work?</a>
</p>

-------

# Features

- **Create** new apps on both App Store Connect and the Apple Developer Portal
- **Modify** Application Services on the Apple Developer Portal
- **Create** App Groups on the Apple Developer Portal
- **Associate** apps with App Groups on the Apple Developer Portal
- **Create** iCloud Containers on the Apple Developer Portal
- **Associate** apps with iCloud Containers on the Apple Developer Portal
- **Create** Merchant Identifiers on the Apple Developer Portal
- **Associate** apps with Merchant Identifiers on the Apple Developer Portal
- Support for **multiple Apple accounts**, storing your credentials securely in the Keychain

# Usage

## Creating a new application

```no-highlight
fastlane produce
```

To get a list of all available parameters:

```no-highlight
fastlane produce --help
```

```no-highlight
Commands: (* default)
  associate_group      Associate with a group, which is created if needed or simply located otherwise
  associate_merchant   Associate with a merchant for use with Apple Pay. Apple Pay will be enabled for this app
  create             * Creates a new app on App Store Connect and the Apple Developer Portal
  disable_services     Disable specific Application Services for a specific app on the Apple Developer Portal
  enable_services      Enable specific Application Services for a specific app on the Apple Developer Portal
  group                Ensure that a specific App Group exists
  cloud_container      Ensure that a specific iCloud Container exists
  help                 Display global or [command] help documentation
  merchant             Ensure that a specific Merchant exists

Global Options:
  --verbose
  -h, --help           Display help documentation
  -v, --version        Display version information

Options for create:
  -u, --username STRING Your Apple ID Username (PRODUCE_USERNAME)
  -a, --app_identifier STRING App Identifier (Bundle ID, e.g. com.krausefx.app) (PRODUCE_APP_IDENTIFIER)
  -e, --bundle_identifier_suffix STRING App Identifier Suffix (Ignored if App Identifier does not ends with .*) (PRODUCE_APP_IDENTIFIER_SUFFIX)
  -q, --app_name STRING App Name (PRODUCE_APP_NAME)
  -z, --app_version STRING Initial version number (e.g. '1.0') (PRODUCE_VERSION)
  -y, --sku STRING     SKU Number (e.g. '1234') (PRODUCE_SKU)
  -j, --platform STRING The platform to use (optional) (PRODUCE_PLATFORM)
  -m, --language STRING Primary Language (e.g. 'English', 'German') (PRODUCE_LANGUAGE)
  -c, --company_name STRING The name of your company. It's used to set company name on App Store Connect team's app pages. Only required if it's the first app you create (PRODUCE_COMPANY_NAME)
  -i, --skip_itc [VALUE] Skip the creation of the app on App Store Connect (PRODUCE_SKIP_ITC)
  -d, --skip_devcenter [VALUE] Skip the creation of the app on the Apple Developer Portal (PRODUCE_SKIP_DEVCENTER)
  -s, --itc_users ARRAY Array of App Store Connect users. If provided, you can limit access to this newly created app for users with the App Manager, Developer, Marketer or Sales roles (ITC_USERS)
  -b, --team_id STRING The ID of your Developer Portal team if you're in multiple teams (PRODUCE_TEAM_ID)
  -l, --team_name STRING The name of your Developer Portal team if you're in multiple teams (PRODUCE_TEAM_NAME)
  -k, --itc_team_id [VALUE] The ID of your App Store Connect team if you're in multiple teams (PRODUCE_ITC_TEAM_ID)
  -p, --itc_team_name STRING The name of your App Store Connect team if you're in multiple teams (PRODUCE_ITC_TEAM_NAME)
```

## Enabling / Disabling Application Services

If you want to enable Application Services for an App ID (HomeKit and HealthKit in this example):

```no-highlight
fastlane produce enable_services --homekit --healthkit
```

If you want to disable Application Services for an App ID (iCloud in this case):

```no-highlight
fastlane produce disable_services --icloud
```

If you want to create a new App Group:

```no-highlight
fastlane produce group -g group.krausefx -n "Example App Group"
```

If you want to associate an app with an App Group:

```no-highlight
fastlane produce associate_group -a com.krausefx.app group.krausefx
```

If you want to create a new iCloud Container:

```no-highlight
fastlane produce cloud_container -g iCloud.com.krausefx.app -n "Example iCloud Container"
```

If you want to associate an app with an iCloud Container:

```no-highlight
fastlane produce associate_cloud_container -a com.krausefx.app iCloud.com.krausefx.app
```

If you want to associate an app with multiple iCloud Containers:

```no-highlight
fastlane produce associate_cloud_container -a com.krausefx.app iCloud.com.krausefx.app1 iCloud.com.krausefx.app2
```

# Parameters

Get a list of all available options using

```no-highlight
fastlane produce enable_services --help
```

```no-highlight
--access-wifi                         Enable Access Wifi
--app-attest                          Enable App Attest
--app-group                           Enable App Group
--apple-pay                           Enable Apple Pay
--associated-domains                  Enable Associated Domains
--auto-fill-credential                Enable Auto Fill Credential
--class-kit                           Enable Class Kit
--icloud STRING                       Enable iCloud, suitable values are "legacy" and "cloudkit"
--custom-network-protocol             Enable Custom Network Protocol
--data-protection STRING              Enable Data Protection, suitable values are "complete", "unlessopen" and "untilfirstauth"
--extended-virtual-address-space      Enable Extended Virtual Address Space
--game-center STRING                  Enable Game Center, suitable values are "ios" and "macos
--health-kit                          Enable Health Kit
--hls-interstitial-preview            Enable Hls Interstitial Preview
--home-kit                            Enable Home Kit
--hotspot                             Enable Hotspot
--in-app-purchase                     Enable In App Purchase
--inter-app-audio                     Enable Inter App Audio
--low-latency-hls                     Enable Low Latency Hls
--managed-associated-domains          Enable Managed Associated Domains
--maps                                Enable Maps
--multipath                           Enable Multipath
--network-extension                   Enable Network Extension
--nfc-tag-reading                     Enable NFC Tag Reading
--personal-vpn                        Enable Personal VPN
--passbook                            Enable Passbook (deprecated)
--push-notification                   Enable Push Notification
--sign-in-with-apple                  Enable Sign In With Apple
--siri-kit                            Enable Siri Kit
--system-extension                    Enable System Extension
--user-management                     Enable User Management
--vpn-configuration                   Enable Vpn Configuration (deprecated)
--wallet                              Enable Wallet
--wireless-accessory                  Enable Wireless Accessory
--car-play-audio-app                  Enable Car Play Audio App
--car-play-messaging-app              Enable Car Play Messaging App
--car-play-navigation-app             Enable Car Play Navigation App
--car-play-voip-calling-app           Enable Car Play Voip Calling App
--critical-alerts                     Enable Critical Alerts
--hotspot-helper                      Enable Hotspot Helper
--driver-kit                          Enable DriverKit
--driver-kit-endpoint-security        Enable DriverKit Endpoint Security
--driver-kit-family-hid-device        Enable DriverKit Family HID Device
--driver-kit-family-networking        Enable DriverKit Family Networking
--driver-kit-family-serial            Enable DriverKit Family Serial
--driver-kit-hid-event-service        Enable DriverKit HID EventService
--driver-kit-transport-hid            Enable DriverKit Transport HID
--multitasking-camera-access          Enable Multitasking Camera Access
--sf-universal-link-api               Enable SFUniversalLink API
--vp9-decoder                         Enable VP9 Decoder
--music-kit                           Enable MusicKit
--shazam-kit                          Enable ShazamKit
--communication-notifications         Enable Communication Notifications
--group-activities                    Enable Group Activities
--health-kit-estimate-recalibration   Enable HealthKit Estimate Recalibration
--time-sensitive-notifications        Enable Time Sensitive Notifications
```

```no-highlight
fastlane produce disable_services --help
```

```no-highlight
--access-wifi                         Disable Access Wifi
--app-attest                          Disable App Attest
--app-group                           Disable App Group
--apple-pay                           Disable Apple Pay
--associated-domains                  Disable Associated Domains
--auto-fill-credential                Disable Auto Fill Credential
--class-kit                           Disable Class Kit
--icloud STRING                       Disable iCloud
--custom-network-protocol             Disable Custom Network Protocol
--data-protection STRING              Disable Data Protection
--extended-virtual-address-space      Disable Extended Virtual Address Space
--game-center STRING                  Disable Game Center
--health-kit                          Disable Health Kit
--hls-interstitial-preview            Disable Hls Interstitial Preview
--home-kit                            Disable Home Kit
--hotspot                             Disable Hotspot
--in-app-purchase                     Disable In App Purchase
--inter-app-audio                     Disable Inter App Audio
--low-latency-hls                     Disable Low Latency Hls
--managed-associated-domains          Disable Managed Associated Domains
--maps                                Disable Maps
--multipath                           Disable Multipath
--network-extension                   Disable Network Extension
--nfc-tag-reading                     Disable NFC Tag Reading
--personal-vpn                        Disable Personal VPN
--passbook                            Disable Passbook (deprecated)
--push-notification                   Disable Push Notification
--sign-in-with-apple                  Disable Sign In With Apple
--siri-kit                            Disable Siri Kit
--system-extension                    Disable System Extension
--user-management                     Disable User Management
--vpn-configuration                   Disable Vpn Configuration (deprecated)
--wallet                              Disable Wallet
--wireless-accessory                  Disable Wireless Accessory
--car-play-audio-app                  Disable Car Play Audio App
--car-play-messaging-app              Disable Car Play Messaging App
--car-play-navigation-app             Disable Car Play Navigation App
--car-play-voip-calling-app           Disable Car Play Voip Calling App
--critical-alerts                     Disable Critical Alerts
--hotspot-helper                      Disable Hotspot Helper
--driver-kit                          Disable DriverKit
--driver-kit-endpoint-security        Disable DriverKit Endpoint Security
--driver-kit-family-hid-device        Disable DriverKit Family HID Device
--driver-kit-family-networking        Disable DriverKit Family Networking
--driver-kit-family-serial            Disable DriverKit Family Serial
--driver-kit-hid-event-service        Disable DriverKit HID EventService
--driver-kit-transport-hid            Disable DriverKit Transport HID
--multitasking-camera-access          Disable Multitasking Camera Access
--sf-universal-link-api               Disable SFUniversalLink API
--vp9-decoder                         Disable VP9 Decoder
--music-kit                           Disable MusicKit
--shazam-kit                          Disable ShazamKit
--communication-notifications         Disable Communication Notifications
--group-activities                    Disable Group Activities
--health-kit-estimate-recalibration   Disable HealthKit Estimate Recalibration
--time-sensitive-notifications        Disable Time Sensitive Notifications
```

## Creating Apple Pay merchants and associating them with an App ID

If you want to create a new Apple Pay Merchant Identifier:

```no-highlight
fastlane produce merchant -o merchant.com.example.production -r "Example Merchant Production"
```

Use `--help` for more information about all available parameters

```no-highlight
fastlane produce merchant --help
```

If you want to associate an app with a Merchant Identifier:

```no-highlight
fastlane produce associate_merchant -a com.krausefx.app merchant.com.example.production
```

If you want to associate an app with multiple Merchant Identifiers:

```no-highlight
fastlane produce associate_merchant -a com.krausefx.app merchant.com.example.production merchant.com.example.sandbox
```

Use --help for more information about all available parameters

```no-highlight
fastlane produce associate_merchant --help
```

## Environment Variables

All available values can also be passed using environment variables, run `fastlane produce --help` to get a list of all available parameters.

## _fastlane_ Integration

Your `Fastfile` should look like this

```ruby
lane :release do
  produce(
    username: 'felix@krausefx.com',
    app_identifier: 'com.krausefx.app',
    app_name: 'MyApp',
    language: 'English',
    app_version: '1.0',
    sku: '123',
    team_name: 'SunApps GmbH', # only necessary when in multiple teams
    
    # Optional
    # App services can be enabled during app creation
    enable_services: {
      access_wifi: "on",                        # Valid values: "on", "off"
      app_attest: "on",                         # Valid values: "on", "off"
      app_group: "on",                          # Valid values: "on", "off"
      apple_pay: "on",                          # Valid values: "on", "off"
      associated_domains: "on",                 # Valid values: "on", "off"
      auto_fill_credential: "on",               # Valid values: "on", "off"
      car_play_audio_app: "on",                 # Valid values: "on", "off"
      car_play_messaging_app: "on",             # Valid values: "on", "off"
      car_play_navigation_app: "on",            # Valid values: "on", "off"
      car_play_voip_calling_app: "on",          # Valid values: "on", "off"
      class_kit: "on",                          # Valid values: "on", "off"
      icloud: "off",                            # Valid values: "legacy", "cloudkit", "off"
      critical_alerts: "on",                    # Valid values: "on", "off"
      custom_network_protocol: "on",            # Valid values: "on", "off"
      data_protection: "complete",              # Valid values: "complete", "unlessopen", "untilfirstauth", "off"
      extended_virtual_address_space: "on",     # Valid values: "on", "off"
      file_provider_testing_mode: "on",         # Valid values: "on", "off"
      fonts: "on",                              # Valid values: "on", "off"
      game_center: "ios",                       # Valid values: "ios", "macos", off"
      health_kit: "on",                         # Valid values: "on", "off"
      hls_interstitial_preview: "on",           # Valid values: "on", "off"
      home_kit: "on",                           # Valid values: "on", "off"
      hotspot: "on",                            # Valid values: "on", "off"
      hotspot_helper: "on",                     # Valid values: "on", "off"
      in_app_purchase: "on",                    # Valid values: "on", "off"
      inter_app_audio: "on",                    # Valid values: "on", "off"
      low_latency_hls: "on",                    # Valid values: "on", "off"
      managed_associated_domains: "on",         # Valid values: "on", "off"
      maps: "on",                               # Valid values: "on", "off"
      multipath: "on",                          # Valid values: "on", "off"
      network_extension: "on",                  # Valid values: "on", "off"
      nfc_tag_reading: "on",                    # Valid values: "on", "off"
      passbook: "on",                           # Valid values: "on", "off" (deprecated)
      personal_vpn: "on",                       # Valid values: "on", "off"
      push_notification: "on",                  # Valid values: "on", "off"
      sign_in_with_apple: "on",                 # Valid values: "on", "off"
      siri_kit: "on",                           # Valid values: "on", "off"
      system_extension: "on",                   # Valid values: "on", "off"
      user_management: "on",                    # Valid values: "on", "off"
      vpn_configuration: "on",                  # Valid values: "on", "off" (deprecated)
      wallet: "on",                             # Valid values: "on", "off"
      wireless_accessory: "on",                 # Valid values: "on", "off"
      driver_kit: "on",                         # Valid values: "on", "off"
      driver_kit_endpoint_security: "on",       # Valid values: "on", "off"
      driver_kit_family_hid_device: "on",       # Valid values: "on", "off"
      driver_kit_family_networking: "on",       # Valid values: "on", "off"
      driver_kit_family_serial: "on",           # Valid values: "on", "off"
      driver_kit_hid_event_service: "on",       # Valid values: "on", "off"
      driver_kit_transport_hid: "on",           # Valid values: "on", "off"
      multitasking_camera_access: "on",         # Valid values: "on", "off"
      sf_universal_link_api: "on",              # Valid values: "on", "off"
      vp9_decoder: "on",                        # Valid values: "on", "off"
      music_kit: "on",                          # Valid values: "on", "off"
      shazam_kit: "on",                         # Valid values: "on", "off"
      communication_notifications: "on",        # Valid values: "on", "off"
      group_activities: "on",                   # Valid values: "on", "off"
      health_kit_estimate_recalibration: "on",  # Valid values: "on", "off"
      time_sensitive_notifications: "on",       # Valid values: "on", "off"
    }
  )

  deliver
end
```

To use the newly generated app in _deliver_, you need to add this line to your `Deliverfile`:

```ruby-skip-tests
apple_id(ENV['PRODUCE_APPLE_ID'])
```

This will tell _deliver_, which `App ID` to use, since the app is not yet available in the App Store.

You'll still have to fill out the remaining information (like screenshots, app description and pricing). You can use [_deliver_](https://docs.fastlane.tools/actions/deliver/) to upload your app metadata using a CLI

## How is my password stored?

_produce_ uses the [password manager](https://github.com/fastlane/fastlane/tree/master/credentials_manager) from _fastlane_. Take a look the [CredentialsManager README](https://github.com/fastlane/fastlane/tree/master/credentials_manager) for more information.
