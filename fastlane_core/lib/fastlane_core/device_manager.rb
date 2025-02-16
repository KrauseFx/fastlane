require 'open3'
require 'plist'

require_relative 'command_executor'
require_relative 'helper'

module FastlaneCore
  class DeviceManager
    class << self
      def all(requested_os_type = "")
        return connected_devices(requested_os_type) + simulators(requested_os_type)
      end

      def runtime_build_os_versions
        @runtime_build_os_versions ||= begin
          output, status = Open3.capture2('xcrun simctl list -j runtimes')
          raise status unless status.success?
          json = JSON.parse(output)
          json['runtimes'].map { |h| [h['buildversion'], h['version']] }.to_h
        rescue StandardError => e
          UI.error(e)
          UI.error('xcrun simctl CLI broken; cun `xcrun simctl list runtimes` and make sure it works')
          UI.user_error!('xcrun simctl not working')
        end
      end

      def simulators(requested_os_type = "")
        UI.verbose("Fetching available simulator devices")

        @devices = []
        os_type = 'unknown'
        os_version = 'unknown'
        output = ''
        Open3.popen3('xcrun simctl list devices') do |stdin, stdout, stderr, wait_thr|
          output = stdout.read
        end

        unless output.include?("== Devices ==")
          UI.error("xcrun simctl CLI broken, run `xcrun simctl list devices` and make sure it works")
          UI.user_error!("xcrun simctl not working.")
        end

        output.split(/\n/).each do |line|
          next if line =~ /unavailable/
          next if line =~ /^== /
          if line =~ /^-- /
            (os_type, os_version) = line.gsub(/-- (.*) --/, '\1').split
          else
            next if os_type =~ /^Unavailable/

            # "    iPad (5th generation) (852A5796-63C3-4641-9825-65EBDC5C4259) (Shutdown)"
            # This line will turn the above string into
            # ["iPad (5th generation)", "(852A5796-63C3-4641-9825-65EBDC5C4259)", "(Shutdown)"]
            matches = line.strip.scan(/^(.*?) (\([^)]*?\)) (\([^)]*?\))$/).flatten.reject(&:empty?)
            state = matches.pop.to_s.delete('(').delete(')')
            udid = matches.pop.to_s.delete('(').delete(')')
            name = matches.join(' ')

            if matches.count && (os_type == requested_os_type || requested_os_type == "")
              # This is disabled here because the Device is defined later in the file, and that's a problem for the cop
              @devices << Device.new(name: name, os_type: os_type, os_version: os_version, udid: udid, state: state, is_simulator: true)
            end
          end
        end

        return @devices
      end

      def connected_devices(requested_os_type)
        UI.verbose("Fetching available connected devices")

        device_types = if requested_os_type == "tvOS"
                         ["AppleTV"]
                       elsif requested_os_type == "iOS"
                         ["iPhone", "iPad", "iPod"]
                       else
                         []
                       end

        devices = [] # Return early if no supported devices are being searched for
        if device_types.count == 0
          return devices
        end

        usb_devices_output = ''
        Open3.popen3("system_profiler SPUSBDataType -xml") do |stdin, stdout, stderr, wait_thr|
          usb_devices_output = stdout.read
        end

        device_uuids = []
        result = Plist.parse_xml(usb_devices_output)

        discover_devices(result[0], device_types, device_uuids) if result[0]

        if device_uuids.count > 0 # xctrace takes a little while to return so skip it if we have no devices
          xctrace_devices_output = ''
          Open3.popen3("xctrace list devices") do |stdin, stdout, stderr, wait_thr|
            xctrace_devices_output = stdout.read
          end

          xctrace_devices_output.split(/\n/).each do |xctrace_device|
            device_uuids.each do |device_uuid|
              match = xctrace_device.match(/(.+) \(([0-9.]+)\) \((\h{40}|\h{8}-\h{16})\)?/)
              if match && match[3].delete("-") == device_uuid
                devices << Device.new(name: match[1], udid: match[3], os_type: requested_os_type, os_version: match[2], state: "Booted", is_simulator: false)
                UI.verbose("USB Device Found - \"" + match[1] + "\" (" + match[2] + ") UUID:" + match[3])
              end
            end
          end
        end

        return devices
      end

      # Recursively handle all USB items, discovering devices that match the
      # desired types.
      def discover_devices(usb_item, device_types, discovered_device_udids)
        (usb_item['_items'] || []).each do |child_item|
          discover_devices(child_item, device_types, discovered_device_udids)
        end

        is_supported_device = device_types.any?(usb_item['_name'])
        serial_num = usb_item['serial_num'] || ''
        has_serial_number = serial_num.length == 40 || serial_num.length == 24

        if is_supported_device && has_serial_number
          discovered_device_udids << serial_num
        end
      end

      def latest_simulator_version_for_device(device)
        simulators.select { |s| s.name == device }
                  .sort_by { |s| Gem::Version.create(s.os_version) }
                  .last
                  .os_version
      end

      # The code below works from Xcode 7 on
      # def all
      #   UI.verbose("Fetching available devices")

      #   @devices = []
      #   output = ''
      #   Open3.popen3('xcrun simctl list devices --json') do |stdin, stdout, stderr, wait_thr|
      #     output = stdout.read
      #   end

      #   begin
      #     data = JSON.parse(output)
      #   rescue => ex
      #     UI.error(ex)
      #     UI.error("xcrun simctl CLI broken, run `xcrun simctl list devices` and make sure it works")
      #     UI.user_error!("xcrun simctl not working.")
      #   end

      #   data["devices"].each do |os_version, l|
      #     l.each do |device|
      #       next if device['availability'].include?("unavailable")
      #       next unless os_version.include?(requested_os_type)

      #       os = os_version.gsub(requested_os_type + " ", "").strip
      #       @devices << Device.new(name: device['name'], os_type: requested_os_type, os_version: os, udid: device['udid'])
      #     end
      #   end

      #   return @devices
      # end
    end

    # Use the UDID for the given device when setting the destination
    # Why? Because we might get this error message
    # > The requested device could not be found because multiple devices matched the request.
    #
    # This happens when you have multiple simulators for a given device type / iOS combination
    #   { platform:iOS Simulator, id:1685B071-AFB2-4DC1-BE29-8370BA4A6EBD, OS:9.0, name:iPhone 5 }
    #   { platform:iOS Simulator, id:A141F23B-96B3-491A-8949-813B376C28A7, OS:9.0, name:iPhone 5 }
    #
    # We don't want to deal with that, so we just use the UDID

    class Device
      attr_accessor :name
      attr_accessor :udid
      attr_accessor :os_type
      attr_accessor :os_version
      attr_accessor :ios_version # Preserved for backwards compatibility
      attr_accessor :state
      attr_accessor :is_simulator

      def initialize(name: nil, udid: nil, os_type: nil, os_version: nil, state: nil, is_simulator: nil)
        self.name = name
        self.udid = udid
        self.os_type = os_type
        self.os_version = os_version
        self.ios_version = os_version
        self.state = state
        self.is_simulator = is_simulator
      end

      def to_s
        self.name
      end

      def boot
        return unless is_simulator
        return unless os_type == "iOS"
        return if self.state == 'Booted'

        # Boot the simulator and wait for it to finish booting
        UI.message("Booting #{self}")
        `xcrun simctl bootstatus #{self.udid} -b &> /dev/null`
        self.state = 'Booted'
      end

      def shutdown
        return unless is_simulator
        return unless os_type == "iOS"
        return if self.state != 'Booted'

        UI.message("Shutting down #{self.udid}")
        `xcrun simctl shutdown #{self.udid} 2>/dev/null`
        self.state = 'Shutdown'
      end

      def reset
        UI.message("Resetting #{self}")
        shutdown
        `xcrun simctl erase #{self.udid}`
      end

      def delete
        UI.message("Deleting #{self}")
        shutdown
        `xcrun simctl delete #{self.udid}`
      end

      def disable_slide_to_type
        return unless is_simulator
        return unless os_type == "iOS"
        return unless Gem::Version.new(os_version) >= Gem::Version.new('13.0')
        UI.message("Disabling 'Slide to Type' #{self}")

        plist_buddy = '/usr/libexec/PlistBuddy'
        plist_buddy_cmd = "-c \"Add :KeyboardContinuousPathEnabled bool false\""
        plist_path = File.expand_path("~/Library/Developer/CoreSimulator/Devices/#{self.udid}/data/Library/Preferences/com.apple.keyboard.ContinuousPath.plist")

        Helper.backticks("#{plist_buddy} #{plist_buddy_cmd} #{plist_path} >/dev/null 2>&1")
      end
    end
  end

  class Simulator
    class << self
      def all
        return DeviceManager.simulators('iOS')
      end

      # Reset all simulators of this type
      def reset_all
        all.each(&:reset)
      end

      def reset_all_by_version(os_version: nil)
        return false unless os_version
        all.select { |device| device.os_version == os_version }.each(&:reset)
      end

      # Reset simulator by UDID or name and OS version
      # Latter is useful when combined with -destination option of xcodebuild
      def reset(udid: nil, name: nil, os_version: nil)
        match = all.detect { |device| device.udid == udid || device.name == name && device.os_version == os_version }
        match.reset if match
      end

      # Delete all simulators of this type
      def delete_all
        all.each(&:delete)
      end

      def delete_all_by_version(os_version: nil)
        return false unless os_version
        all.select { |device| device.os_version == os_version }.each(&:delete)
      end

      # Disable 'Slide to Type' by UDID or name and OS version
      # Latter is useful when combined with -destination option of xcodebuild
      def disable_slide_to_type(udid: nil, name: nil, os_version: nil)
        match = all.detect { |device| device.udid == udid || device.name == name && device.os_version == os_version }
        match.disable_slide_to_type if match
      end

      def clear_cache
        @devices = nil
        @runtime_build_os_versions = nil
      end

      def launch(device)
        return unless device.is_simulator

        simulator_path = File.join(Helper.xcode_path, 'Applications', 'Simulator.app')

        UI.verbose("Launching #{simulator_path} for device: #{device.name} (#{device.udid})")

        Helper.backticks("open -a #{simulator_path} --args -CurrentDeviceUDID #{device.udid}", print: FastlaneCore::Globals.verbose?)
      end

      def copy_logs(device, log_identity, logs_destination_dir, log_collection_start_time)
        logs_destination_dir = File.expand_path(logs_destination_dir)
        os_version = FastlaneCore::CommandExecutor.execute(command: 'sw_vers -productVersion', print_all: false, print_command: false)

        host_computer_supports_logarchives = Gem::Version.new(os_version) >= Gem::Version.new('10.12.0')
        device_supports_logarchives = Gem::Version.new(device.os_version) >= Gem::Version.new('10.0')

        are_logarchives_supported = device_supports_logarchives && host_computer_supports_logarchives
        if are_logarchives_supported
          copy_logarchive(device, log_identity, logs_destination_dir, log_collection_start_time)
        else
          copy_logfile(device, log_identity, logs_destination_dir)
        end
      end

      def uninstall_app(app_identifier, device_type, device_udid)
        UI.verbose("Uninstalling app '#{app_identifier}' from #{device_type}...")

        UI.message("Launch Simulator #{device_type}")
        if FastlaneCore::Helper.xcode_at_least?("13")
          Helper.backticks("open -a Simulator.app --args -CurrentDeviceUDID #{device_udid} &> /dev/null")
        else
          Helper.backticks("xcrun instruments -w #{device_udid} &> /dev/null")
        end

        UI.message("Uninstall application #{app_identifier}")
        Helper.backticks("xcrun simctl uninstall #{device_udid} #{app_identifier} &> /dev/null")
      end

      private

      def copy_logfile(device, log_identity, logs_destination_dir)
        logfile_src = File.expand_path("~/Library/Logs/CoreSimulator/#{device.udid}/system.log")
        return unless File.exist?(logfile_src)

        FileUtils.mkdir_p(logs_destination_dir)
        logfile_dst = File.join(logs_destination_dir, "system-#{log_identity}.log")

        FileUtils.rm_f(logfile_dst)
        FileUtils.cp(logfile_src, logfile_dst)
        UI.success("Copying file '#{logfile_src}' to '#{logfile_dst}'...")
      end

      def copy_logarchive(device, log_identity, logs_destination_dir, log_collection_start_time)
        require 'shellwords'

        logarchive_dst = File.join(logs_destination_dir, "system_logs-#{log_identity}.logarchive")
        FileUtils.rm_rf(logarchive_dst)
        FileUtils.mkdir_p(File.expand_path("..", logarchive_dst))

        logs_collection_start = log_collection_start_time.strftime('%Y-%m-%d %H:%M:%S')
        command = "xcrun simctl spawn #{device.udid} log collect "
        command << "--start '#{logs_collection_start}' "
        command << "--output #{logarchive_dst.shellescape} 2>/dev/null"
        FastlaneCore::CommandExecutor.execute(command: command, print_all: false, print_command: true)
      end
    end
  end

  class SimulatorTV < Simulator
    class << self
      def all
        return DeviceManager.simulators('tvOS')
      end
    end
  end

  class SimulatorWatch < Simulator
    class << self
      def all
        return DeviceManager.simulators('watchOS')
      end
    end
  end
end
