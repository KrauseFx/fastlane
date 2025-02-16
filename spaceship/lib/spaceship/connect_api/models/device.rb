require_relative '../../connect_api'

module Spaceship
  class ConnectAPI
    class Device
      include Spaceship::ConnectAPI::Model

      attr_accessor :device_class
      attr_accessor :model
      attr_accessor :name
      attr_accessor :platform
      attr_accessor :status
      attr_accessor :udid
      attr_accessor :added_date

      attr_mapping({
        "deviceClass" => "device_class",
        "model" => "model",
        "name" => "name",
        "platform" => "platform",
        "status" => "status",
        "udid" => "udid",
        "addedDate" => "added_date"
      })

      module DeviceClass
        APPLE_WATCH = "APPLE_WATCH"
        IPAD = "IPAD"
        IPHONE = "IPHONE"
        IPOD = "IPOD"
        APPLE_TV = "APPLE_TV"
        MAC = "MAC"
        APPLE_VISION_PRO = "APPLE_VISION_PRO"

        # As of 2024-03-08, this is not _officially_ supported by App Store Connect API (according to API docs)—yet still used in the API responses
        APPLE_SILICON_MAC = "APPLE_SILICON_MAC"
        INTEL_MAC = "INTEL_MAC"
      end

      module Status
        ENABLED = "ENABLED"
        DISABLED = "DISABLED"
      end

      def self.type
        return "devices"
      end

      def enabled?
        return status == Status::ENABLED
      end

      #
      # API
      #
      def self.all(client: nil, filter: {}, includes: nil, fields: nil, limit: Spaceship::ConnectAPI::MAX_OBJECTS_PER_PAGE_LIMIT, sort: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_devices(filter: filter, includes: includes, fields: fields, limit: limit, sort: sort).all_pages
        return resps.flat_map(&:to_models)
      end

      # @param platform [String] The provisioning profile's platform (i.e. ios, tvos, macos, catalyst).
      # @param include_mac_in_profiles [Bool] Whether to include macs in iOS provisioning profiles. false by default.
      # @param client [ConnectAPI] ConnectAPI client.
      # @return (Device) List of enabled devices.
      def self.devices_for_platform(platform: nil, include_mac_in_profiles: false, client: nil)
        platform = platform.to_sym
        include_mac_in_profiles &&= platform == :ios

        device_platform = case platform
                          when :osx, :macos, :mac
                            Spaceship::ConnectAPI::Platform::MAC_OS
                          when :ios, :tvos, :xros, :visionos
                            Spaceship::ConnectAPI::Platform::IOS
                          when :catalyst
                            Spaceship::ConnectAPI::Platform::MAC_OS
                          end

        device_platforms = [
          device_platform,
          'UNIVERSAL' # Universal Bundle ID platform is undocumented as of Oct 4, 2023.
        ]

        device_classes =
          case platform
          when :ios
            [
              Spaceship::ConnectAPI::Device::DeviceClass::IPAD,
              Spaceship::ConnectAPI::Device::DeviceClass::IPHONE,
              Spaceship::ConnectAPI::Device::DeviceClass::IPOD,
              Spaceship::ConnectAPI::Device::DeviceClass::APPLE_WATCH,
              Spaceship::ConnectAPI::Device::DeviceClass::APPLE_VISION_PRO
            ]
          when :tvos
            [
              Spaceship::ConnectAPI::Device::DeviceClass::APPLE_TV
            ]
          when :macos, :catalyst
            [
              Spaceship::ConnectAPI::Device::DeviceClass::MAC,
              Spaceship::ConnectAPI::Device::DeviceClass::APPLE_SILICON_MAC,
              Spaceship::ConnectAPI::Device::DeviceClass::INTEL_MAC
            ]
          else
            []
          end

        if include_mac_in_profiles
          device_classes << Spaceship::ConnectAPI::Device::DeviceClass::APPLE_SILICON_MAC
          device_platforms << Spaceship::ConnectAPI::Platform::MAC_OS
        end

        filter = {
          status: Spaceship::ConnectAPI::Device::Status::ENABLED
        }
        filter[:platform] = device_platforms.uniq.join(',') unless device_platforms.empty?

        devices = Spaceship::ConnectAPI::Device.all(
          client: client,
          filter: filter
        )

        unless device_classes.empty?
          devices.select! do |device|
            # App Store Connect API return MAC in device_class instead of APPLE_SILICON_MAC for Silicon Macs.
            # The difference between old MAC and APPLE_SILICON_MAC is provisioning uuid.
            # Intel-based provisioning UUID: 01234567-89AB-CDEF-0123-456789ABCDEF.
            # arm64-based provisioning UUID: 01234567-89ABCDEF12345678.
            # Workaround is to include macs having:
            #   * 25 chars length and only one hyphen in provisioning UUID.
            if include_mac_in_profiles &&
               device.device_class == Spaceship::ConnectAPI::Device::DeviceClass::MAC

              next device.udid.length == 25 && device.udid.count('-') == 1
            end

            device_classes.include?(device.device_class)
          end
        end

        devices
      end

      # @param udids [Array<String>] The set of UDIDs to restrict the devices lookup by
      # @return (Device) List of devices matching the criteria
      def self.devices_for_udids(udids)
        filter = { "udid": udids.join(",") }
        return Spaceship::ConnectAPI::Device.all(filter: filter)
      end

      # @param client [ConnectAPI] ConnectAPI client.
      # @param platform [String] The platform of the device.
      # @param include_disabled [Bool] Whether to include disable devices. false by default.
      # @return (Device) Find a device based on the UDID of the device. nil if no device was found.
      def self.find_by_udid(device_udid, client: nil, include_disabled: false)
        self.all(client: client).find do |device|
          device.udid.casecmp(device_udid) == 0 && (include_disabled ? true : device.enabled?)
        end
      end

      # @param client [ConnectAPI] ConnectAPI client.
      # @param name [String] The name to be assigned to the device, if it needs to be created.
      # @param platform [String] The platform of the device.
      # @return (Device) Find a device based on the UDID of the device. If no device was found,  nil if no device was found.
      def self.find_or_create(device_udid, client: nil, name: nil, platform: nil)
        existing = self.find_by_udid(device_udid, client: client)
        return existing if existing
        return self.create(client: client, name: name, platform: platform, udid: device_udid)
      end

      # @param client [ConnectAPI] ConnectAPI client.
      # @param name [String] The name to be assigned to the device.
      # @param platform [String] The platform of the device.
      # @param udid [String] The udid of the device being created.
      # @return (Device) Find a device based on the UDID of the device. nil if no device was found.
      def self.create(client: nil, name: nil, platform: nil, udid: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.post_device(name: name, platform: platform, udid: udid)
        return resp.to_models.first
      end

      # @param device_udid [String] Device Provisioning UDID that needs to be modified.
      # @param client [ConnectAPI] ConnectAPI client.
      # @param enabled [Boolean] New enabled value. true - if device must be enabled, `false` - to disable device. nil if no status change needed.
      # @param new_name [String] A new name for the device. nil if no name change needed.
      # @return (Device) Modified device based on the UDID of the device. nil if no device was found.
      def self.modify(device_udid, client: nil, enabled: nil, new_name: nil)
        client ||= Spaceship::ConnectAPI
        existing = self.find_by_udid(device_udid, client: client, include_disabled: true)
        return nil if existing.nil?

        enabled = existing.enabled? if enabled.nil?
        new_name ||= existing.name
        return existing if existing.name == new_name && existing.enabled? == enabled
        new_status = enabled ? Status::ENABLED : Status::DISABLED

        resp = client.patch_device(id: existing.id, new_name: new_name, status: new_status)
        return resp.to_models.first
      end

      # @param device_udid [String] Device Provisioning UDID that needs to be enabled.
      # @param client [ConnectAPI] ConnectAPI client.
      # @return (Device) Modified device based on the UDID of the device. nil if no device was found.
      def self.enable(device_udid, client: nil)
        self.modify(device_udid, client: client, enabled: true)
      end

      # @param device_udid [String] Device Provisioning UDID that needs to be disabled.
      # @param client [ConnectAPI] ConnectAPI client.
      # @return (Device) Modified device based on the UDID of the device. nil if no device was found.
      def self.disable(device_udid, client: nil)
        self.modify(device_udid, client: client, enabled: false)
      end

      # @param device_udid [String] Device Provisioning UDID that needs to be renamed.
      # @param new_name [String] A new name for the device.
      # @param client [ConnectAPI] ConnectAPI client.
      # @return (Device) Modified device based on the UDID of the device. nil if no device was found.
      def self.rename(device_udid, new_name, client: nil)
        self.modify(device_udid, client: client, new_name: new_name)
      end
    end
  end
end
