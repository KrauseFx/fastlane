require 'plist'
require 'time'

require_relative '../module'
require_relative '../test_command_generator'
require_relative '../collector'
require_relative '../fixes/hardware_keyboard_fix'
require_relative '../fixes/simulator_zoom_fix'
require_relative '../fixes/simulator_shared_pasteboard'

module Snapshot
  class SimulatorLauncherBase
    attr_accessor :collected_errors

    # The number of times we failed on launching the simulator... sigh
    attr_accessor :current_number_of_retries_due_to_failing_simulator
    attr_accessor :launcher_config

    def initialize(launcher_configuration: nil)
      @launcher_config = launcher_configuration
      @device_boot_datetime = DateTime.now
    end

    def collected_errors
      @collected_errors ||= []
    end

    def current_number_of_retries_due_to_failing_simulator
      @current_number_of_retries_due_to_failing_simulator || 0
    end

    def prepare_for_launch(device_types, language, locale, launch_arguments)
      prepare_directories_for_launch(language: language, locale: locale, launch_arguments: launch_arguments)
      prepare_simulators_for_launch(device_types, language: language, locale: locale)
    end

    def prepare_directories_for_launch(language: nil, locale: nil, launch_arguments: nil)
      screenshots_path = TestCommandGenerator.derived_data_path
      FileUtils.rm_rf(File.join(screenshots_path, "Logs"))
      FileUtils.rm_rf(screenshots_path) if launcher_config.clean
      FileUtils.mkdir_p(screenshots_path)

      FileUtils.mkdir_p(CACHE_DIR)
      FileUtils.mkdir_p(SCREENSHOTS_DIR)

      File.write(File.join(CACHE_DIR, "language.txt"), language)
      File.write(File.join(CACHE_DIR, "locale.txt"), locale || "")
      File.write(File.join(CACHE_DIR, "snapshot-launch_arguments.txt"), launch_arguments.last)
    end

    def prepare_simulators_for_launch(device_types, language: nil, locale: nil)
      # Kill and shutdown all currently running simulators so that the following settings
      # changes will be picked up when they are started again.
      Snapshot.kill_simulator # because of https://github.com/fastlane/fastlane/issues/2533
      `xcrun simctl shutdown booted &> /dev/null`

      Fixes::SimulatorZoomFix.patch
      Fixes::HardwareKeyboardFix.patch
      Fixes::SharedPasteboardFix.patch

      device_types.each do |type|
        if launcher_config.erase_simulator || launcher_config.localize_simulator || !launcher_config.dark_mode.nil?
          if launcher_config.erase_simulator
            erase_simulator(type)
          end
          if launcher_config.localize_simulator
            localize_simulator(type, language, locale)
          end
          unless launcher_config.dark_mode.nil?
            interface_style(type, launcher_config.dark_mode)
          end
        end
        if launcher_config.reinstall_app && !launcher_config.erase_simulator
          # no need to reinstall if device has been erased
          uninstall_app(type)
        end
        if launcher_config.disable_slide_to_type
          disable_slide_to_type(type)
        end
      end

      unless launcher_config.headless
        simulator_path = File.join(Helper.xcode_path, 'Applications', 'Simulator.app')
        Helper.backticks("open -a #{simulator_path} -g", print: FastlaneCore::Globals.verbose?)
      end
    end

    # pass an array of device types
    def add_media(device_types, media_type, paths)
      media_type = media_type.to_s

      device_types.each do |device_type|
        UI.verbose("Adding #{media_type}s to #{device_type}...")
        device_udid = TestCommandGenerator.device_udid(device_type)

        UI.message("Launch Simulator #{device_type}")
        if FastlaneCore::Helper.xcode_at_least?("13")
          Helper.backticks("open -a Simulator.app --args -CurrentDeviceUDID #{device_udid} &> /dev/null")
        else
          Helper.backticks("xcrun instruments -w #{device_udid} &> /dev/null")
        end

        paths.each do |path|
          UI.message("Adding '#{path}'")

          # Attempting addmedia since addphoto and addvideo are deprecated
          output = Helper.backticks("xcrun simctl addmedia #{device_udid} #{path.shellescape} &> /dev/null")

          # Run legacy addphoto and addvideo if addmedia isn't found
          # Output will be empty string if it was a success
          # Output will contain "usage: simctl" if command not found
          if output.include?('usage: simctl')
            Helper.backticks("xcrun simctl add#{media_type} #{device_udid} #{path.shellescape} &> /dev/null")
          end
        end
      end
    end

    def override_status_bar(device_type, arguments = nil)
      device_udid = TestCommandGenerator.device_udid(device_type)

      UI.message("Launch Simulator #{device_type}")
      # Boot the simulator and wait for it to finish booting
      Helper.backticks("xcrun simctl bootstatus #{device_udid} -b &> /dev/null")

      # "Booted" status is not enough for to adjust the status bar
      # Simulator could still be booting with Apple logo
      # Need to wait "some amount of time" until home screen shows
      boot_sleep = ENV["SNAPSHOT_SIMULATOR_WAIT_FOR_BOOT_TIMEOUT"].to_i || 10
      UI.message("Waiting #{boot_sleep} seconds for device to fully boot before overriding status bar... Set 'SNAPSHOT_SIMULATOR_WAIT_FOR_BOOT_TIMEOUT' environment variable to adjust timeout")
      sleep(boot_sleep) if boot_sleep > 0

      UI.message("Overriding Status Bar")

      if arguments.nil? || arguments.empty?
        # The time needs to be passed as ISO8601 so the simulator formats it correctly
        time = Time.new(2007, 1, 9, 9, 41, 0)

        # If you don't override the operator name, you'll get "Carrier" in the status bar on no-notch devices such as iPhone 8. Pass an empty string to blank it out.
        # Some versions of `simctl` are quite picky about time format, and return an error if no fractional seconds are given

        arguments = "--time #{time.iso8601(1)} --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --operatorName '' --cellularBars 4 --batteryState charged --batteryLevel 100"
      end

      Helper.backticks("xcrun simctl status_bar #{device_udid} override #{arguments} &> /dev/null")
    end

    def clear_status_bar(device_type)
      device_udid = TestCommandGenerator.device_udid(device_type)

      UI.message("Clearing Status Bar Override")
      Helper.backticks("xcrun simctl status_bar #{device_udid} clear &> /dev/null")
    end

    def uninstall_app(device_type)
      launcher_config.app_identifier ||= UI.input("App Identifier: ")
      device_udid = TestCommandGenerator.device_udid(device_type)

      FastlaneCore::Simulator.uninstall_app(launcher_config.app_identifier, device_type, device_udid)
    end

    def erase_simulator(device_type)
      UI.verbose("Erasing #{device_type}...")
      device_udid = TestCommandGenerator.device_udid(device_type)

      UI.important("Erasing #{device_type}...")

      `xcrun simctl erase #{device_udid} &> /dev/null`
    end

    def localize_simulator(device_type, language, locale)
      device_udid = TestCommandGenerator.device_udid(device_type)
      if device_udid
        locale ||= language.sub("-", "_")
        plist = {
          AppleLocale: locale,
          AppleLanguages: [language]
        }
        UI.message("Localizing #{device_type} (AppleLocale=#{locale} AppleLanguages=[#{language}])")
        plist_path = "#{ENV['HOME']}/Library/Developer/CoreSimulator/Devices/#{device_udid}/data/Library/Preferences/.GlobalPreferences.plist"
        File.write(plist_path, Plist::Emit.dump(plist))
      end
    end

    def interface_style(device_type, dark_mode)
      device_udid = TestCommandGenerator.device_udid(device_type)
      if device_udid
        plist = {
          UserInterfaceStyleMode: (dark_mode ? 2 : 1)
        }
        UI.message("Setting interface style #{device_type} (UserInterfaceStyleMode=#{dark_mode})")
        plist_path = "#{ENV['HOME']}/Library/Developer/CoreSimulator/Devices/#{device_udid}/data/Library/Preferences/com.apple.uikitservices.userInterfaceStyleMode.plist"
        File.write(plist_path, Plist::Emit.dump(plist))
      end
    end

    def disable_slide_to_type(device_type)
      device_udid = TestCommandGenerator.device_udid(device_type)
      if device_udid
        UI.message("Disabling slide to type on #{device_type}")
        FastlaneCore::Simulator.disable_slide_to_type(udid: device_udid)
      end
    end

    def copy_simulator_logs(device_names, language, locale, launch_arguments)
      return unless launcher_config.output_simulator_logs

      detected_language = locale || language
      language_folder = File.join(launcher_config.output_directory, detected_language)

      device_names.each do |device_name|
        device = TestCommandGeneratorBase.find_device(device_name)
        components = [launch_arguments].delete_if { |a| a.to_s.length == 0 }

        UI.header("Collecting system logs #{device_name} - #{language}")
        log_identity = Digest::MD5.hexdigest(components.join("-"))
        FastlaneCore::Simulator.copy_logs(device, log_identity, language_folder, @device_boot_datetime)
      end
    end
  end
end
