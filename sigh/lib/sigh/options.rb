require 'fastlane_core/configuration/configuration'
require 'credentials_manager/appfile_config'
require_relative 'module'
require 'spaceship/connect_api/models/device'
require 'spaceship/connect_api/models/certificate'
require 'spaceship/connect_api/models/bundle_id'
require 'spaceship/connect_api/models/profile'

module Sigh
  class Options
    def self.available_options
      user = CredentialsManager::AppfileConfig.try_fetch_value(:apple_dev_portal_id)
      user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)

      [
        FastlaneCore::ConfigItem.new(key: :adhoc,
                                     env_name: "SIGH_AD_HOC",
                                     description: "Setting this flag will generate AdHoc profiles instead of App Store Profiles",
                                     is_string: false,
                                     default_value: false,
                                     conflicting_options: [:developer_id, :development],
                                     conflict_block: proc do |option|
                                       UI.user_error!("You can't enable both :#{option.key} and :adhoc")
                                     end),
        FastlaneCore::ConfigItem.new(key: :developer_id,
                                     env_name: "SIGH_DEVELOPER_ID",
                                     description: "Setting this flag will generate Developer ID profiles instead of App Store Profiles",
                                     is_string: false,
                                     default_value: false,
                                     conflicting_options: [:adhoc, :development],
                                     conflict_block: proc do |option|
                                       UI.user_error!("You can't enable both :#{option.key} and :developer_id")
                                     end),
        FastlaneCore::ConfigItem.new(key: :development,
                                     env_name: "SIGH_DEVELOPMENT",
                                     description: "Renew the development certificate instead of the production one",
                                     is_string: false,
                                     default_value: false,
                                     conflicting_options: [:adhoc, :developer_id],
                                     conflict_block: proc do |option|
                                       UI.user_error!("You can't enable both :#{option.key} and :development")
                                     end),
        FastlaneCore::ConfigItem.new(key: :skip_install,
                                     env_name: "SIGH_SKIP_INSTALL",
                                     description: "By default, the certificate will be added to your local machine. Setting this flag will skip this action",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :force,
                                     env_name: "SIGH_FORCE",
                                     description: "Renew provisioning profiles regardless of its state - to automatically add all devices for ad hoc profiles",
                                     is_string: false,
                                     short_option: "-f",
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :include_mac_in_profiles,
                                     env_name: "SIGH_INCLUDE_MAC_IN_PROFILES",
                                     description: "Include Apple Silicon Mac devices in provisioning profiles for iOS/iPadOS apps",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :app_identifier,
                                     short_option: "-a",
                                     env_name: "SIGH_APP_IDENTIFIER",
                                     description: "The bundle identifier of your app",
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier),
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :offline_profile,
                                     env_name: "SIGH_OFFLINE_PROFILE",
                                     description: "Enable profile with 'Offline Support' (7 day validity)",
                                     is_string: false,
                                     default_value: false),

        # App Store Connect API
        FastlaneCore::ConfigItem.new(key: :api_key_path,
                                     env_names: ["SIGH_API_KEY_PATH", "APP_STORE_CONNECT_API_KEY_PATH"],
                                     description: "Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)",
                                     optional: true,
                                     conflicting_options: [:api_key],
                                     verify_block: proc do |value|
                                       UI.user_error!("Couldn't find API key JSON file at path '#{value}'") unless File.exist?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :api_key,
                                     env_names: ["SIGH_API_KEY", "APP_STORE_CONNECT_API_KEY"],
                                     description: "Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)",
                                     type: Hash,
                                     optional: true,
                                     sensitive: true,
                                     conflicting_options: [:api_key_path]),

        # Apple ID
        FastlaneCore::ConfigItem.new(key: :username,
                                     short_option: "-u",
                                     env_name: "SIGH_USERNAME",
                                     description: "Your Apple ID Username",
                                     optional: true,
                                     default_value: user,
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :team_id,
                                     short_option: "-b",
                                     env_name: "SIGH_TEAM_ID",
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
                                     env_name: "SIGH_TEAM_NAME",
                                     description: "The name of your Developer Portal team if you're in multiple teams",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_name),
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_TEAM_NAME"] = value.to_s
                                     end),

        # Other options
        FastlaneCore::ConfigItem.new(key: :provisioning_name,
                                     short_option: "-n",
                                     env_name: "SIGH_PROVISIONING_PROFILE_NAME",
                                     description: "The name of the profile that is used on the Apple Developer Portal",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :ignore_profiles_with_different_name,
                                     env_name: "SIGH_IGNORE_PROFILES_WITH_DIFFERENT_NAME",
                                     description: "Use in combination with :provisioning_name - when true only profiles matching this exact name will be downloaded",
                                     optional: true,
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :output_path,
                                     short_option: "-o",
                                     env_name: "SIGH_OUTPUT_PATH",
                                     description: "Directory in which the profile should be stored",
                                     default_value: "."),
        FastlaneCore::ConfigItem.new(key: :cert_id,
                                     short_option: "-i",
                                     env_name: "SIGH_CERTIFICATE_ID",
                                     description: "The ID of the code signing certificate to use (e.g. 78ADL6LVAA) ",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :cert_owner_name,
                                     short_option: "-c",
                                     env_name: "SIGH_CERTIFICATE",
                                     description: "The certificate name to use for new profiles, or to renew with. (e.g. \"Felix Krause\")",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :filename,
                                     short_option: "-q",
                                     env_name: "SIGH_PROFILE_FILE_NAME",
                                     optional: true,
                                     description: "Filename to use for the generated provisioning profile (must include .mobileprovision)",
                                     verify_block: proc do |value|
                                       UI.user_error!("The output name must end with .mobileprovision") unless value.end_with?(".mobileprovision")
                                     end),
        FastlaneCore::ConfigItem.new(key: :skip_fetch_profiles,
                                     env_name: "SIGH_SKIP_FETCH_PROFILES",
                                     description: "Skips the verification of existing profiles which is useful if you have thousands of profiles",
                                     is_string: false,
                                     default_value: false,
                                     short_option: "-w"),
        FastlaneCore::ConfigItem.new(key: :include_all_certificates,
                                     env_name: "SIGH_INCLUDE_ALL_CERTIFICATES",
                                     description: "Include all matching certificates in the provisioning profile. Works only for the 'development' provisioning profile type",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_certificate_verification,
                                     short_option: '-z',
                                     env_name: "SIGH_SKIP_CERTIFICATE_VERIFICATION",
                                     description: "Skips the verification of the certificates for every existing profiles. This will make sure the provisioning profile can be used on the local machine",
                                     is_string: false,
                                     default_value: !FastlaneCore::Helper.mac?,
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :platform,
                                     short_option: '-p',
                                     env_name: "SIGH_PLATFORM",
                                     description: "Set the provisioning profile's platform (i.e. ios, tvos, macos, catalyst)",
                                     is_string: false,
                                     default_value: "ios",
                                     verify_block: proc do |value|
                                       value = value.to_s
                                       pt = %w(macos tvos ios catalyst)
                                       UI.user_error!("Unsupported platform, must be: #{pt}") unless pt.include?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :readonly,
                                     env_name: "SIGH_READONLY",
                                     description: "Only fetch existing profile, don't generate new ones",
                                     optional: true,
                                     is_string: false,
                                     default_value: false,
                                     conflicting_options: [:force],
                                     conflict_block: proc do |value|
                                       UI.user_error!("You can't enable both :force and :readonly")
                                     end),
        FastlaneCore::ConfigItem.new(key: :template_name,
                                     env_name: "SIGH_PROVISIONING_PROFILE_TEMPLATE_NAME",
                                     description: "The name of provisioning profile template. If the developer account has provisioning profile templates (aka: custom entitlements), the template name can be found by inspecting the Entitlements drop-down while creating/editing a provisioning profile (e.g. \"Apple Pay Pass Suppression Development\")",
                                     optional: true,
                                     default_value: nil),
        FastlaneCore::ConfigItem.new(key: :fail_on_name_taken,
                                     env_name: "SIGH_FAIL_ON_NAME_TAKEN",
                                     description: "Should the command fail if it was about to create a duplicate of an existing provisioning profile. It can happen due to issues on Apple Developer Portal, when profile to be recreated was not properly deleted first",
                                     optional: true,
                                     is_string: false,
                                     default_value: false),

        # Cache
        FastlaneCore::ConfigItem.new(key: :cached_certificates,
                                     description: "A list of cached certificates",
                                     optional: true,
                                     is_string: false,
                                     default_value: nil,
                                     verify_block: proc do |value|
                                       next if value.nil?
                                       if !value.kind_of?(Array) ||
                                         !value.all?(Spaceship::ConnectAPI::Certificate)
                                         UI.user_error!("cached_certificates parameter must be an array of Spaceship::ConnectAPI::Certificate") unless value.kind_of?(Array)
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :cached_devices,
                                     description: "A list of cached devices",
                                     optional: true,
                                     is_string: false,
                                     default_value: nil,
                                     verify_block: proc do |value|
                                       next if value.nil?
                                       if !value.kind_of?(Array) ||
                                         !value.all?(Spaceship::ConnectAPI::Device)
                                         UI.user_error!("cached_devices parameter must be an array of Spaceship::ConnectAPI::Device")
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :cached_bundle_ids,
                                     description: "A list of cached bundle ids",
                                     optional: true,
                                     is_string: false,
                                     default_value: nil,
                                     verify_block: proc do |value|
                                       next if value.nil?
                                       if !value.kind_of?(Array) ||
                                         !value.all?(Spaceship::ConnectAPI::BundleId)
                                         UI.user_error!("cached_bundle_ids parameter must be an array of Spaceship::ConnectAPI::BundleId")
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :cached_profiles,
                                      description: "A list of cached bundle ids",
                                      optional: true,
                                      is_string: false,
                                      default_value: nil,
                                      verify_block: proc do |value|
                                        next if value.nil?
                                        if !value.kind_of?(Array) ||
                                          !value.all?(Spaceship::ConnectAPI::Profile)
                                          UI.user_error!("cached_profiles parameter must be an array of Spaceship::ConnectAPI::Profile")
                                        end
                                      end)
      ]
    end
  end
end
