require 'open3'

describe FastlaneCore do
  describe FastlaneCore::DeviceManager do
    before(:all) do
      @simctl_output = File.read('./fastlane_core/spec/fixtures/DeviceManagerSimctlOutputXcode7')
      @system_profiler_output = File.read('./fastlane_core/spec/fixtures/DeviceManagerSystem_profilerOutput')
      @xctrace_output = File.read('./fastlane_core/spec/fixtures/DeviceManagerXCTraceOutput')
      @system_profiler_output_items_without_items = File.read('./fastlane_core/spec/fixtures/DeviceManagerSystem_profilerOutputItemsWithoutItems')
      @system_profiler_output_usb_hub = File.read('./fastlane_core/spec/fixtures/DeviceManagerSystem_profilerOutputUsbHub')

      FastlaneCore::Simulator.clear_cache
    end

    it 'raises an error if broken xcrun simctl list devices' do
      response = double('xcrun simctl list devices', read: 'garbage')
      expect(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, response, nil, nil)

      expect do
        devices = FastlaneCore::Simulator.all
      end.to raise_error("xcrun simctl not working.")
    end

    it 'raises an error if broken xcrun simctl list runtimes' do
      status = double('status', "success?": true)
      expect(Open3).to receive(:capture2).with("xcrun simctl list -j runtimes").and_return(['garbage', status])

      expect do
        FastlaneCore::DeviceManager.runtime_build_os_versions
      end.to raise_error(FastlaneCore::Interface::FastlaneError)
    end

    describe "properly parses the simctl output and generates Device objects for iOS simulator" do
      it "Xcode 7" do
        response = "response"
        expect(response).to receive(:read).and_return(@simctl_output)
        expect(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, response, nil, nil)

        devices = FastlaneCore::Simulator.all
        expect(devices.count).to eq(6)

        expect(devices[0]).to have_attributes(
          name: "iPhone 4s", os_type: "iOS", os_version: "8.1",
          udid: "DBABD2A2-0144-44B0-8F93-263EB656FC13",
          state: "Shutdown",
          is_simulator: true
        )
        expect(devices[1]).to have_attributes(
          name: "iPhone 5", os_type: "iOS", os_version: "8.1",
          udid: "0D80C781-8702-4156-855E-A9B737FF92D3",
          state: "Booted",
          is_simulator: true
        )
        expect(devices[2]).to have_attributes(
          name: "iPhone 6s Plus", os_type: "iOS", os_version: "9.1",
          udid: "BB65C267-FAE9-4CB7-AE31-A5D9BA393AF0",
          state: "Shutdown",
          is_simulator: true
        )
        expect(devices[3]).to have_attributes(
          name: "iPad Air", os_type: "iOS", os_version: "9.1",
          udid: "B61CB41D-354B-4991-992A-80AFFF1062E6",
          state: "Shutdown",
          is_simulator: true
        )
        expect(devices[4]).to have_attributes(
          name: "iPad Air 2", os_type: "iOS", os_version: "9.1",
          udid: "57836FE1-5443-4433-B164-A6C9EADAB3F9",
          state: "Shutdown",
          is_simulator: true
        )
        expect(devices[5]).to have_attributes(
          name: "iPad Pro", os_type: "iOS", os_version: "9.1",
          udid: "B1DDED8D-E449-461A-94A5-4146A1F58B20",
          state: "Shutdown",
          is_simulator: true
        )
      end

      it "Xcode 8" do
        response = "response"
        simctl_output = File.read('./fastlane_core/spec/fixtures/DeviceManagerSimctlOutputXcode8')
        expect(response).to receive(:read).and_return(simctl_output)
        expect(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, response, nil, nil)

        devices = FastlaneCore::Simulator.all
        expect(devices.count).to eq(12)

        expect(devices[-3]).to have_attributes(
          name: "iPad Air 2", os_type: "iOS", os_version: "10.0",
          udid: "0FDEB396-0582-438A-B09E-8F8F889DB632",
          state: "Shutdown",
          is_simulator: true
        )
        expect(devices[-2]).to have_attributes(
          name: "iPad Pro (9.7-inch)", os_type: "iOS", os_version: "10.0",
          udid: "C03658EC-1362-4D8D-A40A-45B1D7D5405E",
          state: "Shutdown",
          is_simulator: true
        )
        expect(devices[-1]).to have_attributes(
          name: "iPad Pro (12.9-inch)", os_type: "iOS", os_version: "10.0",
          udid: "CEF11EB3-79DF-43CB-896A-0F33916C8BDE",
          state: "Shutdown",
          is_simulator: true
        )
      end

      it 'Xcode 9' do
        response = "response"
        simctl_output = File.read('./fastlane_core/spec/fixtures/DeviceManagerSimctlOutputXcode9')
        expect(response).to receive(:read).and_return(simctl_output)
        expect(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, response, nil, nil)

        devices = FastlaneCore::Simulator.all
        expect(devices.count).to eq(15)

        expect(devices[-3]).to have_attributes(
          name: "iPad Pro (12.9-inch)", os_type: "iOS", os_version: "11.0",
          udid: "C7C55339-DE8F-4DA3-B94A-09879CB1E5B5",
          state: "Shutdown",
          is_simulator: true
        )
        expect(devices[-2]).to have_attributes(
          name: "iPad Pro (12.9-inch) (2nd generation)", os_type: "iOS", os_version: "11.0",
          udid: "D2408DE5-C74F-4AD1-93FA-CC083D438321",
          state: "Shutdown",
          is_simulator: true
        )
        expect(devices[-1]).to have_attributes(
          name: "iPad Pro (10.5-inch)", os_type: "iOS", os_version: "11.0",
          udid: "ED8B6B96-11CC-4848-93B8-4D5D627ABF7E",
          state: "Shutdown",
          is_simulator: true
        )
      end

      it 'Xcode 11' do
        response = "response"
        simctl_output = File.read('./fastlane_core/spec/fixtures/DeviceManagerSimctlOutputXcode11')
        expect(response).to receive(:read).and_return(simctl_output)
        expect(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, response, nil, nil)

        devices = FastlaneCore::Simulator.all
        expect(devices.count).to eq(29)

        expect(devices[-3]).to have_attributes(
          name: "iPad Pro (12.9-inch) (4th generation)", os_type: "iOS", os_version: "13.4",
          udid: "D311F577-F7B7-4487-9322-BF9A418F4EF3",
          state: "Shutdown",
          is_simulator: true
        )
        expect(devices[-2]).to have_attributes(
          name: "iPad Air (3rd generation)", os_type: "iOS", os_version: "13.4",
          udid: "B6EDB5A2-820D-4DBE-A4E2-06DFF06DCB20",
          state: "Shutdown",
          is_simulator: true
        )
        expect(devices[-1]).to have_attributes(
          name: "iPad Air (3rd generation) Dark", os_type: "iOS", os_version: "13.4",
          udid: "2B0E9B5D-3680-42B1-BC44-26B380921500",
          state: "Shutdown",
          is_simulator: true
        )
      end
    end

    it "properly parses the simctl output and generates Device objects for tvOS simulator" do
      response = "response"
      expect(response).to receive(:read).and_return(@simctl_output)
      expect(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, response, nil, nil)

      devices = FastlaneCore::SimulatorTV.all
      expect(devices.count).to eq(1)

      expect(devices[0]).to have_attributes(
        name: "Apple TV 1080p", os_type: "tvOS", os_version: "9.0",
        udid: "D239A51B-A61C-4B60-B4D6-B7EC16595128",
        state: "Shutdown",
        is_simulator: true
      )
    end

    it "properly parses the simctl output and generates Device objects for watchOS simulator" do
      response = "response"
      expect(response).to receive(:read).and_return(@simctl_output)
      expect(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, response, nil, nil)

      devices = FastlaneCore::SimulatorWatch.all
      expect(devices.count).to eq(2)

      expect(devices[0]).to have_attributes(
        name: "Apple Watch - 38mm", os_type: "watchOS", os_version: "2.0",
        udid: "FE0C82A5-CDD2-4062-A62C-21278EEE32BB",
        state: "Shutdown",
        is_simulator: true
      )
      expect(devices[1]).to have_attributes(
        name: "Apple Watch - 38mm", os_type: "watchOS", os_version: "2.0",
        udid: "66D1BF17-3003-465F-A165-E6E3A565E5EB",
        state: "Booted",
        is_simulator: true
      )
    end

    it "properly parses the simctl output and generates Device objects for all simulators" do
      response = "response"
      expect(response).to receive(:read).and_return(@simctl_output)
      expect(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, response, nil, nil)

      devices = FastlaneCore::DeviceManager.simulators
      expect(devices.count).to eq(9)

      expect(devices[0]).to have_attributes(
        name: "iPhone 4s", os_type: "iOS", os_version: "8.1",
        udid: "DBABD2A2-0144-44B0-8F93-263EB656FC13",
        state: "Shutdown",
        is_simulator: true
      )
      expect(devices[1]).to have_attributes(
        name: "iPhone 5", os_type: "iOS", os_version: "8.1",
        udid: "0D80C781-8702-4156-855E-A9B737FF92D3",
        state: "Booted",
        is_simulator: true
      )
      expect(devices[2]).to have_attributes(
        name: "iPhone 6s Plus", os_type: "iOS", os_version: "9.1",
        udid: "BB65C267-FAE9-4CB7-AE31-A5D9BA393AF0",
        state: "Shutdown",
        is_simulator: true
      )
      expect(devices[3]).to have_attributes(
        name: "iPad Air", os_type: "iOS", os_version: "9.1",
        udid: "B61CB41D-354B-4991-992A-80AFFF1062E6",
        state: "Shutdown",
        is_simulator: true
      )
      expect(devices[6]).to have_attributes(
        name: "Apple TV 1080p", os_type: "tvOS", os_version: "9.0",
        udid: "D239A51B-A61C-4B60-B4D6-B7EC16595128",
        state: "Shutdown",
        is_simulator: true
      )
      expect(devices[7]).to have_attributes(
        name: "Apple Watch - 38mm", os_type: "watchOS", os_version: "2.0",
        udid: "FE0C82A5-CDD2-4062-A62C-21278EEE32BB",
        state: "Shutdown",
        is_simulator: true
      )
      expect(devices[8]).to have_attributes(
        name: "Apple Watch - 38mm", os_type: "watchOS", os_version: "2.0",
        udid: "66D1BF17-3003-465F-A165-E6E3A565E5EB",
        state: "Booted",
        is_simulator: true
      )
    end

    it "properly parses the simctl output with unavailable devices and generates Device objects for all simulators" do
      response = "response"
      simctl_output = File.read('./fastlane_core/spec/fixtures/DeviceManagerSimctlOutputXcode10BootedUnavailable')
      expect(response).to receive(:read).and_return(simctl_output)
      expect(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, response, nil, nil)

      devices = FastlaneCore::DeviceManager.simulators
      expect(devices.count).to eq(3)

      expect(devices[0]).to have_attributes(
        name: "iPhone 5s", os_type: "iOS", os_version: "12.0",
        udid: "238C6D64-8720-4BFF-9DE9-FFBB9A1375D4",
        state: "Shutdown",
        is_simulator: true
      )
      expect(devices[1]).to have_attributes(
        name: "iPhone 6", os_type: "iOS", os_version: "12.0",
        udid: "C68031AE-E525-4065-9DB6-0D4450326BDA",
        state: "Shutdown",
        is_simulator: true
      )
      expect(devices[2]).to have_attributes(
        name: "Apple Watch Series 2 - 38mm", os_type: "watchOS", os_version: "5.0",
        udid: "34144812-F701-4A49-9210-4A226FE5E0A9",
        state: "Shutdown",
        is_simulator: true
      )
    end

    it "properly parses system_profiler and xctrace output and generates Device objects for iOS" do
      response = "response"
      expect(response).to receive(:read).and_return(@system_profiler_output)
      expect(Open3).to receive(:popen3).with("system_profiler SPUSBDataType -xml").and_yield(nil, response, nil, nil)

      expect(response).to receive(:read).and_return(@xctrace_output)
      expect(Open3).to receive(:popen3).with("xctrace list devices").and_yield(nil, response, nil, nil)

      devices = FastlaneCore::DeviceManager.connected_devices('iOS')
      expect(devices.count).to eq(2)

      expect(devices[0]).to have_attributes(
        name: "Matthew's iPhone", os_type: "iOS", os_version: "9.3",
        udid: "f0f9f44e7c2dafbae53d1a83fe27c37418ffffff",
        state: "Booted",
        is_simulator: false
      )

      expect(devices[1]).to have_attributes(
        name: "iPhone XS Max", os_type: "iOS", os_version: "12.0",
        udid: "00008020-0006302A0CFFFFFF",
        state: "Booted",
        is_simulator: false
      )
    end

    it "properly parses system_profiler output with entries that don't contain _items" do
      response = "response"
      expect(response).to receive(:read).and_return(@system_profiler_output_items_without_items)
      expect(Open3).to receive(:popen3).with("system_profiler SPUSBDataType -xml").and_yield(nil, response, nil, nil)

      devices = FastlaneCore::DeviceManager.connected_devices('iOS')
      expect(devices).to be_empty
    end

    it "properly finds devices in system_profiler output when connected via USB hubs" do
      response = "response"
      expect(response).to receive(:read).and_return(@system_profiler_output_usb_hub)
      expect(Open3).to receive(:popen3).with("system_profiler SPUSBDataType -xml").and_yield(nil, response, nil, nil)

      expect(response).to receive(:read).and_return(@xctrace_output)
      expect(Open3).to receive(:popen3).with("xctrace list devices").and_yield(nil, response, nil, nil)

      devices = FastlaneCore::DeviceManager.connected_devices('iOS')
      expect(devices.count).to eq(1)
      expect(devices[0]).to have_attributes(
        name: "Matthew's iPhone", os_type: "iOS", os_version: "9.3",
        udid: "f0f9f44e7c2dafbae53d1a83fe27c37418ffffff",
        state: "Booted",
        is_simulator: false
      )
    end

    it "properly parses system_profiler and xctrace output and generates Device objects for tvOS" do
      response = "response"
      expect(response).to receive(:read).and_return(@system_profiler_output)
      expect(Open3).to receive(:popen3).with("system_profiler SPUSBDataType -xml").and_yield(nil, response, nil, nil)

      expect(response).to receive(:read).and_return(@xctrace_output)
      expect(Open3).to receive(:popen3).with("xctrace list devices").and_yield(nil, response, nil, nil)

      devices = FastlaneCore::DeviceManager.connected_devices('tvOS')
      expect(devices.count).to eq(1)

      expect(devices[0]).to have_attributes(
        name: "Matthew's Apple TV", os_type: "tvOS", os_version: "9.1",
        udid: "82f1fb5c8362ee9eb89a9c2c6829fa0563ffffff",
        state: "Booted",
        is_simulator: false
      )
    end

    it "properly parses output for all iOS devices" do
      response = "response"
      expect(response).to receive(:read).and_return(@system_profiler_output)
      expect(Open3).to receive(:popen3).with("system_profiler SPUSBDataType -xml").and_yield(nil, response, nil, nil)

      expect(response).to receive(:read).and_return(@xctrace_output)
      expect(Open3).to receive(:popen3).with("xctrace list devices").and_yield(nil, response, nil, nil)

      expect(response).to receive(:read).and_return(@simctl_output)
      expect(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, response, nil, nil)

      devices = FastlaneCore::DeviceManager.all('iOS')
      expect(devices.count).to eq(8)

      expect(devices[0]).to have_attributes(
        name: "Matthew's iPhone", os_type: "iOS", os_version: "9.3",
        udid: "f0f9f44e7c2dafbae53d1a83fe27c37418ffffff",
        state: "Booted",
        is_simulator: false
      )
      expect(devices[1]).to have_attributes(
        name: "iPhone XS Max", os_type: "iOS", os_version: "12.0",
        udid: "00008020-0006302A0CFFFFFF",
        state: "Booted",
        is_simulator: false
      )
      expect(devices[2]).to have_attributes(
        name: "iPhone 4s", os_type: "iOS", os_version: "8.1",
        udid: "DBABD2A2-0144-44B0-8F93-263EB656FC13",
        state: "Shutdown",
        is_simulator: true
      )
      expect(devices[3]).to have_attributes(
        name: "iPhone 5", os_type: "iOS", os_version: "8.1",
        udid: "0D80C781-8702-4156-855E-A9B737FF92D3",
        state: "Booted",
        is_simulator: true
      )
      expect(devices[4]).to have_attributes(
        name: "iPhone 6s Plus", os_type: "iOS", os_version: "9.1",
        udid: "BB65C267-FAE9-4CB7-AE31-A5D9BA393AF0",
        state: "Shutdown",
        is_simulator: true
      )
      expect(devices[5]).to have_attributes(
        name: "iPad Air", os_type: "iOS", os_version: "9.1",
        udid: "B61CB41D-354B-4991-992A-80AFFF1062E6",
        state: "Shutdown",
        is_simulator: true
      )
    end

    it "properly parses output for all tvOS devices" do
      response = "response"
      expect(response).to receive(:read).and_return(@system_profiler_output)
      expect(Open3).to receive(:popen3).with("system_profiler SPUSBDataType -xml").and_yield(nil, response, nil, nil)

      expect(response).to receive(:read).and_return(@xctrace_output)
      expect(Open3).to receive(:popen3).with("xctrace list devices").and_yield(nil, response, nil, nil)

      expect(response).to receive(:read).and_return(@simctl_output)
      expect(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, response, nil, nil)

      devices = FastlaneCore::DeviceManager.all('tvOS')
      expect(devices.count).to eq(2)

      expect(devices[0]).to have_attributes(
        name: "Matthew's Apple TV", os_type: "tvOS", os_version: "9.1",
        udid: "82f1fb5c8362ee9eb89a9c2c6829fa0563ffffff",
        state: "Booted",
        is_simulator: false
      )
      expect(devices[1]).to have_attributes(
        name: "Apple TV 1080p", os_type: "tvOS", os_version: "9.0",
        udid: "D239A51B-A61C-4B60-B4D6-B7EC16595128",
        state: "Shutdown",
        is_simulator: true
      )
    end

    it 'properly parses `xcrun simctl list runtimes` to associate runtime builds with their exact OS version' do
      status = double('status', "success?": true)
      runtime_output = File.read('./fastlane_core/spec/fixtures/XcrunSimctlListRuntimesOutput')
      expect(Open3).to receive(:capture2).with("xcrun simctl list -j runtimes").and_return([runtime_output, status])

      expect(FastlaneCore::DeviceManager.runtime_build_os_versions['21A328']).to eq('17.0')
      expect(FastlaneCore::DeviceManager.runtime_build_os_versions['21A342']).to eq('17.0.1')
      expect(FastlaneCore::DeviceManager.runtime_build_os_versions['21R355']).to eq('10.0')
    end

    describe FastlaneCore::DeviceManager::Device do
      it "slide to type gets disabled if iOS 13.0 or greater" do
        device = FastlaneCore::DeviceManager::Device.new(os_type: "iOS", os_version: "13.0", is_simulator: true)

        expect(UI).to receive(:message).with("Disabling 'Slide to Type' #{device}")
        expect(FastlaneCore::Helper).to receive(:backticks).times.once

        device.disable_slide_to_type
      end

      it "bypass slide to type disabling if less than iOS 13.0" do
        device = FastlaneCore::DeviceManager::Device.new(os_type: "iOS", os_version: "12.4", is_simulator: true)

        expect(FastlaneCore::Helper).to_not(receive(:backticks))

        device.disable_slide_to_type
      end

      it "bypass slide to type disabling if not a simulator" do
        device = FastlaneCore::DeviceManager::Device.new(os_type: "iOS", os_version: "13.0", is_simulator: false)

        expect(FastlaneCore::Helper).to_not(receive(:backticks))

        device.disable_slide_to_type
      end

      it "bypass slide to type disabling if not iOS" do
        device = FastlaneCore::DeviceManager::Device.new(os_type: "somethingelse", os_version: "13.0", is_simulator: true)

        expect(FastlaneCore::Helper).to_not(receive(:backticks))

        device.disable_slide_to_type
      end

      it "boots the simulator" do
        device = FastlaneCore::DeviceManager::Device.new(os_type: "iOS", os_version: "13.0", is_simulator: true, state: nil)

        device.boot

        expect(device.state).to eq('Booted')
      end
    end
  end
end
