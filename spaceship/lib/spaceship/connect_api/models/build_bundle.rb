require_relative '../model'
require_relative './build_bundle_file_sizes'
module Spaceship
  class ConnectAPI
    class BuildBundle
      include Spaceship::ConnectAPI::Model

      attr_accessor :bundle_id
      attr_accessor :bundle_type
      attr_accessor :sdk_build
      attr_accessor :platform_build
      attr_accessor :file_name
      attr_accessor :has_siri_kit
      attr_accessor :has_on_demand_resources
      attr_accessor :is_newsstand
      attr_accessor :has_prerendered_icon
      attr_accessor :uses_location_services
      attr_accessor :is_ios_build_mac_app_store_compatible
      attr_accessor :includes_symbols
      attr_accessor :dsym_url
      attr_accessor :supported_architectures
      attr_accessor :required_capabilities
      attr_accessor :device_protocols
      attr_accessor :locales
      attr_accessor :entitlements
      attr_accessor :tracks_users

      module BundleType
        APP = "APP"
        APP_CLIP = "APP_CLIP"
      end

      attr_mapping({
        "bundleId" => "bundle_id",
        "bundleType" => "bundle_type",
        "sdkBuild" => "sdk_build",
        "platformBuild" => "platform_build",
        "fileName" => "file_name",
        "hasSirikit" => "has_siri_kit",
        "hasOnDemandResources" => "has_on_demand_resources",
        "isNewsstand" => "is_newsstand",
        "hasPrerenderedIcon" => "has_prerendered_icon",
        "usesLocationServices" => "uses_location_services",
        "isIosBuildMacAppStoreCompatible" => "is_ios_build_mac_app_store_compatible",
        "includesSymbols" => "includes_symbols",
        "dSYMUrl" => "dsym_url",
        "supportedArchitectures" => "supported_architectures",
        "requiredCapabilities" => "required_capabilities",
        "deviceProtocols" => "device_protocols",
        "locales" => "locales",
        "entitlements" => "entitlements",
        "tracksUsers" => "tracks_users"
      })

      def self.type
        return "buildBundles"
      end

      #
      # API
      #

      def build_bundle_file_sizes(client: nil)
        @build_bundle_file_sizes ||= BuildBundleFileSizes.all(client: client, build_bundle_id: id)
      end
    end
  end
end
