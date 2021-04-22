describe Fastlane::Helper::AdbHelper do
  around do |example|
    FastlaneSpec::Env.with_env_values(ANDROID_SDK_ROOT: '/usr/local/android-sdk') { example.run }
  end

  describe "#load_all_devices" do
    context 'adb host' do
      it 'no host specified' do
        devices = Fastlane::Helper::AdbHelper.new
        expect(devices.host_option).to eq(nil)
      end

      it 'host specified' do
        devices = Fastlane::Helper::AdbHelper.new(adb_host: 'device_farm')
        expect(devices.host_option).to eq("-H device_farm")
      end
    end

    context 'no devices' do
      it 'does not find any active devices' do
        adb_response = strip_heredoc(<<-ADB_OUTPUT)
        List of devices attached

        ADB_OUTPUT

        allow(Fastlane::Actions).to receive(:sh).and_return(adb_response)
        devices = Fastlane::Helper::AdbHelper.new.load_all_devices

        expect(devices.count).to eq(0)
      end
    end

    context 'one device with spurious ADB output mixed in' do
      it 'finds an active device' do
        adb_response = strip_heredoc(<<-ADB_OUTPUT)
          List of devices attached
          adb server version (39) doesn't match this client (36); killing...
          * daemon started successfully
          T065002LTT             device usb:437387264X product:ghost_retail model:XT1053 device:ghost


        ADB_OUTPUT

        allow(Fastlane::Actions).to receive(:sh).and_return(adb_response)
        devices = Fastlane::Helper::AdbHelper.new.load_all_devices

        expect(devices.count).to eq(1)
        expect(devices[0].serial).to eq("T065002LTT")
      end
    end

    context 'one device' do
      it 'finds an active device' do
        adb_response = strip_heredoc(<<-ADB_OUTPUT)
          List of devices attached
          T065002LTT             device usb:437387264X product:ghost_retail model:XT1053 device:ghost


        ADB_OUTPUT

        allow(Fastlane::Actions).to receive(:sh).and_return(adb_response)
        devices = Fastlane::Helper::AdbHelper.new.load_all_devices

        expect(devices.count).to eq(1)
        expect(devices[0].serial).to eq("T065002LTT")
      end
    end

    context 'multiple devices' do
      it 'finds an active device' do
        adb_response = strip_heredoc(<<-ADB_OUTPUT)
          List of devices attached
          emulator-5554          device product:sdk_phone_x86_64 model:Android_SDK_built_for_x86_64 device:generic_x86_64
          T065002LTT             device usb:437387264X product:ghost_retail model:XT1053 device:ghost

        ADB_OUTPUT

        allow(Fastlane::Actions).to receive(:sh).and_return(adb_response)
        devices = Fastlane::Helper::AdbHelper.new.load_all_devices

        expect(devices.count).to eq(2)
        expect(devices[0].serial).to eq("emulator-5554")
        expect(devices[1].serial).to eq("T065002LTT")
      end
    end

    context 'one device booting' do
      it 'finds an active device' do
        adb_response = strip_heredoc(<<-ADB_OUTPUT)
          List of devices attached
          emulator-5554 offline
          T065002LTT  device usb:437387264X product:ghost_retail model:XT1053 device:ghost

        ADB_OUTPUT

        allow(Fastlane::Actions).to receive(:sh).and_return(adb_response)
        devices = Fastlane::Helper::AdbHelper.new.load_all_devices

        expect(devices.count).to eq(1)
        expect(devices[0].serial).to eq("T065002LTT")
      end
    end
  end
end
