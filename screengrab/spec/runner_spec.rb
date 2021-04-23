describe Screengrab::Runner do
  let(:config) { {} }
  let(:ui) { Screengrab::UI }
  let(:mock_android_environment) { double(Screengrab.android_environment) }
  let(:mock_executor) { class_double('FastlaneCore::CommandExecutor') }

  before do
    @runner = Screengrab::Runner.new(mock_executor, config, mock_android_environment)
  end

  def mock_adb_response_for_command(command, mock_response)
    expect(mock_executor).to receive(:execute)
      .with(hash_including(command: command))
      .and_return(mock_response)
  end

  def mock_adb_response(mock_response)
    expect(mock_executor).to receive(:execute)
      .and_return(mock_response)
  end

  describe :run_tests_for_locale do
    let(:device_serial) { 'device_serial' }
    let(:test_classes_to_use) { nil }
    let(:test_packages_to_use) { nil }

    before do
      expect(mock_android_environment).to receive(:adb_path).and_return("adb")
    end

    context "when launch arguments are specified" do
      before do
        config[:launch_arguments] = ["username hjanuschka", "build_type x500"]
        config[:locales] = %w(en-US)
        config[:ending_locale] = 'en-US'
        config[:use_timestamp_suffix] = true
      end
      it 'sets custom launch_arguments' do
        # Don't actually try to pull screenshot from device
        allow(@runner).to receive(:pull_screenshots_from_device)

        expect(mock_executor).to receive(:execute)
          .with(hash_including(command: "adb -s device_serial shell am instrument --no-window-animation -w \\\n-e testLocale en_US \\\n-e endingLocale en_US \\\n-e appendTimestamp true \\\n-e username hjanuschka -e build_type x500 \\\n/"))
        @runner.run_tests_for_locale('device', 'path', 'en-US', device_serial, test_classes_to_use, test_packages_to_use, config[:launch_arguments])
      end
    end

    context 'when a locale is specified' do
      before do
        config[:locales] = %w(en-US)
        config[:ending_locale] = 'en-US'
      end

      context 'when tests produce a failure' do
        before do
          mock_adb_response('FAILURES!!!')
        end

        context 'when exit_on_test_failure is true' do
          before do
            config[:exit_on_test_failure] = true
          end

          it 'prints an error and exits the program' do
            # Don't actually try to pull screenshot from device
            allow(@runner).to receive(:pull_screenshots_from_device)

            expect(ui).to receive(:test_failure!).with("Tests failed for locale en-US on device #{device_serial}").and_call_original

            expect { @runner.run_tests_for_locale('devie', 'path', 'en-US', device_serial, test_classes_to_use, test_packages_to_use, nil) }.to raise_fastlane_test_failure
          end
        end

        context 'when exit_on_test_failure is false' do
          before do
            config[:exit_on_test_failure] = false
          end

          it 'prints an error and does not exit the program' do
            # Don't actually try to pull screenshot from device
            allow(@runner).to receive(:pull_screenshots_from_device)

            expect(ui).to receive(:error).with("Tests failed").and_call_original

            @runner.run_tests_for_locale('device', 'path', 'en-US', device_serial, test_classes_to_use, test_packages_to_use, nil)
          end
        end
      end
    end

    context 'when using use_timestamp_suffix' do
      context 'when set to false' do
        before do
          @runner = Screengrab::Runner.new(
            mock_executor,
            FastlaneCore::Configuration.create(Screengrab::Options.available_options, { use_timestamp_suffix: false }),
            mock_android_environment
          )
        end
        it 'sets appendTimestamp as false' do
          # Don't actually try to pull screenshot from device
          allow(@runner).to receive(:pull_screenshots_from_device)

          expect(mock_executor).to receive(:execute)
            .with(hash_including(command: "adb -s device_serial shell am instrument --no-window-animation -w \\\n-e testLocale en_US \\\n-e endingLocale en_US \\\n-e appendTimestamp false \\\n/androidx.test.runner.AndroidJUnitRunner"))
          @runner.run_tests_for_locale('device', 'path', 'en-US', device_serial, test_classes_to_use, test_packages_to_use, nil)
        end
      end

      context 'use_timestamp_suffix is not specified' do
        before do
          @runner = Screengrab::Runner.new(
            mock_executor,
            FastlaneCore::Configuration.create(Screengrab::Options.available_options, {}),
            mock_android_environment
          )
        end
        it 'should set appendTimestamp by default' do
          # Don't actually try to pull screenshot from device
          allow(@runner).to receive(:pull_screenshots_from_device)

          expect(mock_executor).to receive(:execute)
            .with(hash_including(command: "adb -s device_serial shell am instrument --no-window-animation -w \\\n-e testLocale en_US \\\n-e endingLocale en_US \\\n-e appendTimestamp true \\\n/androidx.test.runner.AndroidJUnitRunner"))
          @runner.run_tests_for_locale('device', 'path', 'en-US', device_serial, test_classes_to_use, test_packages_to_use, nil)
        end
      end
    end
  end

  describe :validate_apk do
    context 'no aapt' do
      it 'prints an error unless aapt can be found' do
        expect(mock_android_environment).to receive(:aapt_path).and_return(nil)
        expect(mock_executor).not_to(receive(:execute))
        expect(ui).to receive(:important).with(/.*aapt.*could not be found/)

        @runner.validate_apk('fake_apk_path')
      end
    end

    context 'no permissions' do
      it 'prints if permissions are missing' do
        allow(mock_android_environment).to receive(:aapt_path).and_return('fake_aapt_path')
        mock_adb_response_for_command('fake_aapt_path dump permissions fake_apk_path', '')

        expect(ui).to receive(:user_error!).with(/permission.* could not be found/).and_call_original

        expect { @runner.validate_apk('fake_apk_path') }.to raise_fastlane_error
      end
    end
  end

  describe :uninstall_existing do
    let(:device_serial) { 'device_serial' }
    let(:app_package_name) { 'tools.fastlane.dev' }
    let(:test_package_name) { 'tools.fastlane.dev.test' }
    let(:adb_list_packages_command) { "adb -s #{device_serial} shell pm list packages" }

    context 'app and test package installed' do
      before do
        expect(mock_android_environment).to receive(:adb_path).and_return("adb").exactly(3).times

        adb_response = strip_heredoc(<<-ADB_OUTPUT)
          package:android
          package:com.android.contacts
          package:com.google.android.webview
          package:tools.fastlane.dev
          package:tools.fastlane.dev.test

        ADB_OUTPUT

        mock_adb_response_for_command(adb_list_packages_command, adb_response)
      end

      it 'uninstalls app and test package' do
        expect(mock_executor).to receive(:execute).with(hash_including(command: "adb -s #{device_serial} uninstall #{app_package_name}"))
        expect(mock_executor).to receive(:execute).with(hash_including(command: "adb -s #{device_serial} uninstall #{test_package_name}"))
        @runner.uninstall_apks(device_serial, app_package_name, test_package_name)
      end
    end

    context 'app and test package not installed' do
      before do
        expect(mock_android_environment).to receive(:adb_path).and_return("adb")

        adb_response = strip_heredoc(<<-ADB_OUTPUT)
          package:android
          package:com.android.contacts
          package:com.google.android.webview

        ADB_OUTPUT

        mock_adb_response_for_command(adb_list_packages_command, adb_response)
      end

      it 'skips uninstall of app' do
        expect(mock_executor).not_to(receive(:execute)).with(hash_including(command: "adb -s #{device_serial} uninstall #{app_package_name}"))
        expect(mock_executor).not_to(receive(:execute)).with(hash_including(command: "adb -s #{device_serial} uninstall #{test_package_name}"))
        @runner.uninstall_apks(device_serial, app_package_name, test_package_name)
      end
    end
  end

  describe :installed_packages do
    let(:device_serial) { 'device_serial' }
    let(:adb_list_packages_command) { "adb -s #{device_serial} shell pm list packages" }

    before do
      expect(mock_android_environment).to receive(:adb_path).and_return("adb")
    end

    it 'returns installed packages' do
      adb_response = strip_heredoc(<<-ADB_OUTPUT)
        package:android
        package:com.android.contacts
        package:com.google.android.webview
        package:tools.fastlane.dev
        package:tools.fastlane.dev.test

      ADB_OUTPUT

      mock_adb_response_for_command(adb_list_packages_command, adb_response)
      expect(@runner.installed_packages(device_serial)).to eq(['android', 'com.android.contacts', 'com.google.android.webview', 'tools.fastlane.dev', 'tools.fastlane.dev.test'])
    end
  end

  describe :run_adb_command do
    before do
      expect(mock_android_environment).to receive(:adb_path).and_return("adb")
    end

    it 'filters out lines which are ADB warnings' do
      adb_response = strip_heredoc(<<-ADB_OUTPUT)
            adb: /home/me/rubystack-2.3.1-4/common/lib/libcrypto.so.1.0.0: no version information available (required by adb)
            List of devices attached
            e1dbf228               device usb:1-1.2 product:a33gdd model:SM_A300H device:a33g

      ADB_OUTPUT

      mock_adb_response_for_command("adb test", adb_response)

      expect(@runner.run_adb_command("test").lines.any? { |line| line.start_with?('adb: ') }).to eq(false)
    end
  end

  describe :select_device do
    it 'connects to host if specified' do
      config[:adb_host] = "device_farm"

      mock_helper = double('mock helper')
      device = Fastlane::Helper::AdbDevice.new(serial: 'e1dbf228')

      expect(mock_android_environment).to receive(:adb_path).and_return("adb")
      expect(Fastlane::Helper::AdbHelper).to receive(:new).with(adb_path: 'adb', adb_host: 'device_farm').and_return(mock_helper)
      expect(mock_helper).to receive(:load_all_devices).and_return([device])

      expect(@runner.select_device).to eq('e1dbf228')
    end
  end
end
