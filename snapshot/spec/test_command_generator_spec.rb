require 'tmpdir'

describe Snapshot do
  describe Snapshot::TestCommandGenerator do
    let(:os_version) { "9.3" }
    let(:iphone6_9_3) { FastlaneCore::DeviceManager::Device.new(name: "iPhone 6", os_version: os_version, udid: "11111", state: "Don't Care", is_simulator: true) }
    let(:iphone6_9_3_2) { FastlaneCore::DeviceManager::Device.new(name: "iPhone 6s", os_version: os_version, udid: "22222", state: "Don't Care", is_simulator: true) }
    let(:iphone6_9_0) { FastlaneCore::DeviceManager::Device.new(name: "iPhone 6", os_version: '9.0', udid: "11111", state: "Don't Care", is_simulator: true) }
    let(:iphone6_9_2) { FastlaneCore::DeviceManager::Device.new(name: "iPhone 6", os_version: '9.2', udid: "11111", state: "Don't Care", is_simulator: true) }
    let(:iphone6_10_1) { FastlaneCore::DeviceManager::Device.new(name: "iPhone 6 (10.1)", os_version: '10.1', udid: "33333", state: "Don't Care", is_simulator: true) }
    let(:iphone6s_10_1) { FastlaneCore::DeviceManager::Device.new(name: "iPhone 6s (10.1)", os_version: '10.1', udid: "98765", state: "Don't Care", is_simulator: true) }
    let(:iphone4s_9_0) { FastlaneCore::DeviceManager::Device.new(name: "iPhone 4s", os_version: '9.0', udid: "4444", state: "Don't Care", is_simulator: true) }
    let(:iphone8_9_1) { FastlaneCore::DeviceManager::Device.new(name: "iPhone 8", os_version: '9.1', udid: "55555", state: "Don't Care", is_simulator: true) }
    let(:ipad_air_9_1) { FastlaneCore::DeviceManager::Device.new(name: "iPad Air (4th generation)", os_version: '9.1', udid: "12345", state: "Don't Care", is_simulator: true) }
    let(:appleTV) { FastlaneCore::DeviceManager::Device.new(name: "Apple TV 1080p", os_version: os_version, udid: "22222", state: "Don't Care", is_simulator: true) }
    let(:appleWatch6_44mm_7_4) { FastlaneCore::DeviceManager::Device.new(name: "Apple Watch Series 6 - 44mm", os_version: '7.4', udid: "5555544", state: "Don't Care", is_simulator: true) }

    before do
      allow(Snapshot::LatestOsVersion).to receive(:version).and_return(os_version)
      allow(FastlaneCore::DeviceManager).to receive(:simulators).and_return([iphone6_9_0, iphone6_9_3, iphone6_9_2, appleTV, iphone6_9_3_2, iphone6_10_1, iphone6s_10_1, iphone4s_9_0, iphone8_9_1, ipad_air_9_1, appleWatch6_44mm_7_4])
      fake_out_xcode_project_loading
    end

    context "with xcpretty" do
      before(:each) do
        allow(Fastlane::Helper::XcodebuildFormatterHelper).to receive(:xcbeautify_installed?).and_return(false)
      end

      describe '#destination' do
        it "returns the highest version available for device if no match for the specified/latest os_version" do
          allow(Snapshot).to receive(:config).and_return({ ios_version: os_version })
          devices = ["iPhone 4s", "iPhone 6", "iPhone 6s"]
          result = Snapshot::TestCommandGenerator.destination(devices)
          expect(result).to eq([[
            "-destination 'platform=iOS Simulator,name=iPhone 4s,OS=9.0'",
            "-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.3'",
            "-destination 'platform=iOS Simulator,name=iPhone 6s,OS=9.3'"
          ].join(' ')])
        end
      end

      describe '#verify_devices_share_os' do
        before(:each) do
          @test_command_generator = Snapshot::TestCommandGenerator.new
        end
        it "returns true with only iOS devices" do
          devices = ["iPhone 8", "iPad Air 2", "iPhone X", "iPhone 8 plus", "iPod touch (7th generation)"]
          result = Snapshot::TestCommandGenerator.verify_devices_share_os(devices)
          expect(result).to be(true)
        end

        it "returns true with only Apple TV devices" do
          devices = ["Apple TV 1080p", "Apple TV 4K", "Apple TV 4K (at 1080p)"]
          result = Snapshot::TestCommandGenerator.verify_devices_share_os(devices)
          expect(result).to be(true)
        end

        it "returns true with only Apple Watch devices" do
          devices = ["Apple Watch Series 6 - 44mm"]
          result = Snapshot::TestCommandGenerator.verify_devices_share_os(devices)
          expect(result).to be(true)
        end

        it "returns false with mixed device OS of Apple TV and iPhone" do
          devices = ["Apple TV 1080p", "iPhone 8"]
          result = Snapshot::TestCommandGenerator.verify_devices_share_os(devices)
          expect(result).to be(false)
        end

        it "returns false with mixed device OS of Apple Watch and iPhone" do
          devices = ["Apple Watch Series 6 - 44mm", "iPhone 8"]
          result = Snapshot::TestCommandGenerator.verify_devices_share_os(devices)
          expect(result).to be(false)
        end

        it "returns false with mixed device OS of Apple TV and iPad" do
          devices = ["Apple TV 1080p", "iPad Air 2"]
          result = Snapshot::TestCommandGenerator.verify_devices_share_os(devices)
          expect(result).to be(false)
        end

        it "returns false with mixed device OS of Apple TV and iPod" do
          devices = ["Apple TV 1080p", "iPod touch (7th generation)"]
          result = Snapshot::TestCommandGenerator.verify_devices_share_os(devices)
          expect(result).to be(false)
        end

        it "returns true with custom named iOS devices" do
          devices = ["11.0 - iPhone X", "11.0 - iPad Air 2", "13.0 - iPod touch"]
          result = Snapshot::TestCommandGenerator.verify_devices_share_os(devices)
          expect(result).to be(true)
        end

        it "returns true with custom named Apple TV devices" do
          devices = ["11.0 - Apple TV 1080p", "11.0 - Apple TV 4K", "11.0 - Apple TV 4K (at 1080p)"]
          result = Snapshot::TestCommandGenerator.verify_devices_share_os(devices)
          expect(result).to be(true)
        end
      end

      describe '#find_device' do
        it 'finds a device that has a matching name and OS version' do
          found = Snapshot::TestCommandGenerator.find_device('iPhone 8', '9.0')
          expect(found).to eq(iphone8_9_1)
        end

        it 'does not find a device that has a different name' do
          found = Snapshot::TestCommandGenerator.find_device('iPhone 5', '9.0')
          expect(found).to be(nil)
        end

        it 'finds a device with the same name, but a different OS version, picking the highest available OS version' do
          found = Snapshot::TestCommandGenerator.find_device('iPhone 8', '10.0')
          expect(found).to eq(iphone8_9_1)
        end
      end

      describe 'copy_simulator_logs' do
        before (:each) do
          @config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, {
            output_directory: '/tmp/scan_results',
            output_simulator_logs: true,
            devices: ['iPhone 6 (10.1)', 'iPhone 6s'],
            project: './snapshot/example/Example.xcodeproj',
            scheme: 'ExampleUITests',
            namespace_log_files: true
          })
        end

        it 'copies all device log archives to the output directory on macOS 10.12 (Sierra)', requires_xcode: true do
          Snapshot.config = @config
          launcher_config = Snapshot::SimulatorLauncherConfiguration.new(snapshot_config: Snapshot.config)

          allow(FastlaneCore::CommandExecutor).
            to receive(:execute).
            with(command: "sw_vers -productVersion", print_all: false, print_command: false).
            and_return('10.12.1')

          expect(FastlaneCore::CommandExecutor).
            to receive(:execute).
            with(command: %r{xcrun simctl spawn 33333 log collect --start '\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d' --output /tmp/scan_results/de-DE/system_logs-cfcd208495d565ef66e7dff9f98764da.logarchive 2>/dev/null}, print_all: false, print_command: true)

          expect(FastlaneCore::CommandExecutor).
            to receive(:execute).
            with(command: %r{xcrun simctl spawn 98765 log collect --start '\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d' --output /tmp/scan_results/en-US/system_logs-cfcd208495d565ef66e7dff9f98764da.logarchive 2>/dev/null}, print_all: false, print_command: true)

          Snapshot::SimulatorLauncher.new(launcher_configuration: launcher_config).copy_simulator_logs(["iPhone 6 (10.1)"], "de-DE", nil, 0)
          Snapshot::SimulatorLauncher.new(launcher_configuration: launcher_config).copy_simulator_logs(["iPhone 6s (10.1)"], "en-US", nil, 0)
        end

        it 'copies all iOS 9 device log files to the output directory on macOS 10.12 (Sierra)', requires_xcode: true do
          Snapshot.config = @config
          launcher_config = Snapshot::SimulatorLauncherConfiguration.new(snapshot_config: Snapshot.config)

          allow(File).to receive(:exist?).with(/.*system\.log/).and_return(true)
          allow(FastlaneCore::CommandExecutor).to receive(:execute).with(command: "sw_vers -productVersion", print_all: false, print_command: false).and_return('10.12')

          expect(FileUtils).to receive(:rm_f).with(%r{#{Snapshot.config[:output_directory]}/de-DE/system-cfcd208495d565ef66e7dff9f98764da\.log}).and_return(true)
          expect(FileUtils).to receive(:cp).with(/.*/, %r{#{Snapshot.config[:output_directory]}/de-DE/system-cfcd208495d565ef66e7dff9f98764da\.log}).and_return(true)

          expect(FileUtils).to receive(:rm_f).with(%r{#{Snapshot.config[:output_directory]}/en-US/system-cfcd208495d565ef66e7dff9f98764da\.log}).and_return(true)
          expect(FileUtils).to receive(:cp).with(/.*/, %r{#{Snapshot.config[:output_directory]}/en-US/system-cfcd208495d565ef66e7dff9f98764da\.log}).and_return(true)

          Snapshot::SimulatorLauncher.new(launcher_configuration: launcher_config).copy_simulator_logs(["iPhone 6s"], "de-DE", nil, 0)
          Snapshot::SimulatorLauncher.new(launcher_configuration: launcher_config).copy_simulator_logs(["iPhone 6"], "en-US", nil, 0)
        end

        it 'copies all device log files to the output directory on macOS 10.11 (El Capitan)', requires_xcode: true do
          Snapshot.config = @config
          launcher_config = Snapshot::SimulatorLauncherConfiguration.new(snapshot_config: Snapshot.config)

          allow(File).to receive(:exist?).with(/.*system\.log/).and_return(true)
          allow(FastlaneCore::CommandExecutor).to receive(:execute).with(command: "sw_vers -productVersion", print_all: false, print_command: false).and_return('10.11.6')

          expect(FileUtils).to receive(:rm_f).with(%r{#{Snapshot.config[:output_directory]}/de-DE/system-cfcd208495d565ef66e7dff9f98764da\.log}).and_return(true)
          expect(FileUtils).to receive(:cp).with(/.*/, %r{#{Snapshot.config[:output_directory]}/de-DE/system-cfcd208495d565ef66e7dff9f98764da\.log}).and_return(true)

          expect(FileUtils).to receive(:rm_f).with(%r{#{Snapshot.config[:output_directory]}/en-US/system-cfcd208495d565ef66e7dff9f98764da\.log}).and_return(true)
          expect(FileUtils).to receive(:cp).with(/.*/, %r{#{Snapshot.config[:output_directory]}/en-US/system-cfcd208495d565ef66e7dff9f98764da\.log}).and_return(true)

          Snapshot::SimulatorLauncher.new(launcher_configuration: launcher_config).copy_simulator_logs(["iPhone 8"], "de-DE", nil, 0)
          Snapshot::SimulatorLauncher.new(launcher_configuration: launcher_config).copy_simulator_logs(["iPad Air (4th generation)"], "en-US", nil, 0)
        end
      end

      describe "Valid iOS Configuration" do
        let(:options) { { project: "./snapshot/example/Example.xcodeproj", scheme: "ExampleUITests", namespace_log_files: true } }

        def configure(options)
          Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, options)
        end

        context 'default options' do
          it "uses the default parameters", requires_xcode: true do
            configure(options)
            expect(Dir).to receive(:mktmpdir).with("snapshot_derived").and_return("/tmp/path/to/snapshot_derived")
            command = Snapshot::TestCommandGenerator.generate(
              devices: ["iPhone 8"],
              language: "en",
              locale: nil,
              log_path: '/path/to/logs'
            )
            name = command.join('').match(/name=(.+?),/)[1]
            ios = command.join('').match(/OS=(\d+.\d+)/)[1]
            expect(command).to eq(
              [
                "set -o pipefail &&",
                "xcodebuild",
                "-scheme ExampleUITests",
                "-project ./snapshot/example/Example.xcodeproj",
                "-derivedDataPath /tmp/path/to/snapshot_derived",
                "-destination 'platform=iOS Simulator,name=#{name},OS=#{ios}'",
                "FASTLANE_SNAPSHOT=YES",
                "FASTLANE_LANGUAGE=en",
                :build,
                :test,
                "| tee /path/to/logs",
                "| xcpretty "
              ]
            )
          end

          it "allows to supply custom xcargs", requires_xcode: true do
            configure(options.merge(xcargs: "-only-testing:TestBundle/TestSuite/Screenshots"))
            expect(Dir).to receive(:mktmpdir).with("snapshot_derived").and_return("/tmp/path/to/snapshot_derived")
            command = Snapshot::TestCommandGenerator.generate(
              devices: ["iPhone 8"],
              language: "en",
              locale: nil,
              log_path: '/path/to/logs'
            )
            name = command.join('').match(/name=(.+?),/)[1]
            ios = command.join('').match(/OS=(\d+.\d+)/)[1]
            expect(command).to eq(
              [
                "set -o pipefail &&",
                "xcodebuild",
                "-scheme ExampleUITests",
                "-project ./snapshot/example/Example.xcodeproj",
                "-derivedDataPath /tmp/path/to/snapshot_derived",
                "-only-testing:TestBundle/TestSuite/Screenshots",
                "-destination 'platform=iOS Simulator,name=#{name},OS=#{ios}'",
                "FASTLANE_SNAPSHOT=YES",
                "FASTLANE_LANGUAGE=en",
                :build,
                :test,
                "| tee /path/to/logs",
                "| xcpretty "
              ]
            )
          end

          it "uses the default parameters on tvOS too", requires_xcode: true do
            configure(options.merge(devices: ["Apple TV 1080p"]))
            expect(Dir).to receive(:mktmpdir).with("snapshot_derived").and_return("/tmp/path/to/snapshot_derived")
            command = Snapshot::TestCommandGenerator.generate(
              devices: ["Apple TV 1080p"],
              language: "en",
              locale: nil,
              log_path: '/path/to/logs'
            )
            name = command.join('').match(/name=(.+?),/)[1]
            os = command.join('').match(/OS=(\d+.\d+)/)[1]
            expect(command).to eq(
              [
                "set -o pipefail &&",
                "xcodebuild",
                "-scheme ExampleUITests",
                "-project ./snapshot/example/Example.xcodeproj",
                "-derivedDataPath /tmp/path/to/snapshot_derived",
                "-destination 'platform=tvOS Simulator,name=#{name},OS=#{os}'",
                "FASTLANE_SNAPSHOT=YES",
                "FASTLANE_LANGUAGE=en",
                :build,
                :test,
                "| tee /path/to/logs",
                "| xcpretty "
              ]
            )
          end

          it "uses the default parameters on watchOS too", requires_xcode: true do
            configure(options.merge(devices: ["Apple Watch Series 6 - 44mm"]))
            expect(Dir).to receive(:mktmpdir).with("snapshot_derived").and_return("/tmp/path/to/snapshot_derived")
            command = Snapshot::TestCommandGenerator.generate(
              devices: ["Apple Watch Series 6 - 44mm"],
              language: "en",
              locale: nil,
              log_path: '/path/to/logs'
            )
            name = command.join('').match(/name=(.+?),/)[1]
            os = command.join('').match(/OS=(\d+.\d+)/)[1]
            expect(command).to eq(
              [
                "set -o pipefail &&",
                "xcodebuild",
                "-scheme ExampleUITests",
                "-project ./snapshot/example/Example.xcodeproj",
                "-derivedDataPath /tmp/path/to/snapshot_derived",
                "-destination 'platform=watchOS Simulator,name=#{name},OS=#{os}'",
                "FASTLANE_SNAPSHOT=YES",
                "FASTLANE_LANGUAGE=en",
                :build,
                :test,
                "| tee /path/to/logs",
                "| xcpretty "
              ]
            )
          end
        end

        context 'fixed derivedDataPath' do
          let(:temp) { Dir.mktmpdir }

          before do
            configure(options.merge(derived_data_path: temp))
          end

          it 'uses the fixed derivedDataPath if given', requires_xcode: true do
            expect(Dir).not_to(receive(:mktmpdir))
            command = Snapshot::TestCommandGenerator.generate(devices: ["iPhone 8"], language: "en", locale: nil)
            expect(command.join('')).to include("-derivedDataPath #{temp}")
          end
        end

        context 'test-without-building' do
          let(:temp) { Dir.mktmpdir }

          before do
            configure(options.merge(derived_data_path: temp, test_without_building: true))
          end

          it 'uses the "test-without-building" command and not the default "build test"', requires_xcode: true do
            command = Snapshot::TestCommandGenerator.generate(devices: ["iPhone 8"], language: "en", locale: nil)
            expect(command.join('')).to include("test-without-building")
            expect(command.join('')).not_to(include("build test"))
          end
        end

        context 'test-plan' do
          it 'adds the testplan to the xcodebuild command', requires_xcode: true do
            configure(options.merge(testplan: 'simple'))

            command = Snapshot::TestCommandGenerator.generate(devices: ["iPhone 8"], language: "en", locale: nil)
            expect(command.join('')).to include("-testPlan 'simple'") if FastlaneCore::Helper.xcode_at_least?(11)
          end
        end

        context "only-testing" do
          it "only tests the test bundle/suite/cases specified in only_testing when the input is an array", requires_xcode: true do
            configure(options.merge(only_testing: %w(TestBundleA/TestSuiteB TestBundleC)))

            command = Snapshot::TestCommandGenerator.generate(devices: ["iPhone 8"], language: "en", locale: nil)
            expect(command.join('')).to include("-only-testing:TestBundleA/TestSuiteB")
            expect(command.join('')).to include("-only-testing:TestBundleC")
          end

          it "only tests the test bundle/suite/cases specified in only_testing when the input is a string", requires_xcode: true do
            configure(options.merge(only_testing: 'TestBundleA/TestSuiteB'))

            command = Snapshot::TestCommandGenerator.generate(devices: ["iPhone 8"], language: "en", locale: nil)
            expect(command.join('')).to include("-only-testing:TestBundleA/TestSuiteB")
            expect(command.join('')).not_to(include("-only-testing:TestBundleC"))
          end
        end

        context "skip-testing" do
          it "does not test the test bundle/suite/cases specified in skip_testing when the input is an array", requires_xcode: true do
            configure(options.merge(skip_testing: %w(TestBundleA/TestSuiteB TestBundleC)))

            command = Snapshot::TestCommandGenerator.generate(devices: ["iPhone 8"], language: "en", locale: nil)
            expect(command.join('')).to include("-skip-testing:TestBundleA/TestSuiteB")
            expect(command.join('')).to include("-skip-testing:TestBundleC")
          end

          it "does not test the test bundle/suite/cases specified in skip_testing when the input is a string", requires_xcode: true do
            configure(options.merge(skip_testing: 'TestBundleA/TestSuiteB'))

            command = Snapshot::TestCommandGenerator.generate(devices: ["iPhone 8"], language: "en", locale: nil)
            expect(command.join('')).to include("-skip-testing:TestBundleA/TestSuiteB")
            expect(command.join('')).not_to(include("-skip-testing:TestBundleC"))
          end
        end

        context "disable_xcpretty" do
          it "does not include xcpretty in the pipe command when true", requires_xcode: true do
            configure(options.merge(disable_xcpretty: true))

            command = Snapshot::TestCommandGenerator.generate(devices: ["iPhone 8"], language: "en", locale: nil)
            expect(command.join('')).to_not(include("| xcpretty "))
          end

          it "includes xcpretty in the pipe command when false", requires_xcode: true do
            configure(options.merge(disable_xcpretty: false))

            command = Snapshot::TestCommandGenerator.generate(devices: ["iPhone 8"], language: "en", locale: nil)
            expect(command.join('')).to include("| xcpretty ")
          end
        end

        context "suppress_xcode_output" do
          it "includes /dev/null in the pipe command when true", requires_xcode: true do
            configure(options.merge(suppress_xcode_output: true))

            command = Snapshot::TestCommandGenerator.generate(devices: ["iPhone 8"], language: "en", locale: nil)
            expect(command.join('')).to include("> /dev/null")
          end

          it "does not include /dev/null in the pipe command when false", requires_xcode: true do
            configure(options.merge(suppress_xcode_output: false))

            command = Snapshot::TestCommandGenerator.generate(devices: ["iPhone 8"], language: "en", locale: nil)
            expect(command.join('')).to_not(include("> /dev/null"))
          end
        end

        context "run_rosetta_simulator" do
          it "adds ARCHS=x86_64 when true", requires_xcodebuild: true do
            configure(options.merge(run_rosetta_simulator: true))

            command = Snapshot::TestCommandGenerator.generate(devices: ["iPhone 8"], language: "en", locale: nil)
            expect(command).to include("ARCHS=x86_64")
          end
        end
      end

      describe "Valid macOS Configuration" do
        let(:options) { { project: "./snapshot/example/Example.xcodeproj", scheme: "ExampleMacOS", namespace_log_files: true } }

        it "uses default parameters on macOS", requires_xcode: true do
          Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, options.merge(devices: ["Mac"]))
          expect(Dir).to receive(:mktmpdir).with("snapshot_derived").and_return("/tmp/path/to/snapshot_derived")
          command = Snapshot::TestCommandGenerator.generate(
            devices: ["Mac"],
            language: "en",
            locale: nil,
            log_path: '/path/to/logs'
          )
          expect(command).to eq(
            [
              "set -o pipefail &&",
              "xcodebuild",
              "-scheme ExampleMacOS",
              "-project ./snapshot/example/Example.xcodeproj",
              "-derivedDataPath /tmp/path/to/snapshot_derived",
              "-destination 'platform=macOS'",
              "FASTLANE_SNAPSHOT=YES",
              "FASTLANE_LANGUAGE=en",
              :build,
              :test,
              "| tee /path/to/logs",
              "| xcpretty "
            ]
          )
        end
      end

      describe "Unique logs" do
        let(:options) { { project: "./snapshot/example/Example.xcodeproj", scheme: "ExampleUITests", namespace_log_files: true } }
        let(:simulator_launcher) do
          Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, options)
          launcher_config = Snapshot::SimulatorLauncherConfiguration.new(snapshot_config: Snapshot.config)
          launcher_config.devices = ["iPhone 8"]
          return simulator_launcher = Snapshot::SimulatorLauncher.new(launcher_configuration: launcher_config)
        end

        it 'uses correct name and language', requires_xcode: true do
          log_path = simulator_launcher.xcodebuild_log_path(language: "pt", locale: nil)
          expect(log_path).to eq(
            File.expand_path("#{FastlaneCore::Helper.buildlog_path}/snapshot/Example-ExampleUITests-iPhone 8-pt.log").to_s
          )
        end

        it 'uses includes locale if specified', requires_xcode: true do
          log_path = simulator_launcher.xcodebuild_log_path(language: "pt", locale: "pt_BR")
          expect(log_path).to eq(
            File.expand_path("#{FastlaneCore::Helper.buildlog_path}/snapshot/Example-ExampleUITests-iPhone 8-pt-pt_BR.log").to_s
          )
        end

        it 'can work without parameters', requires_xcode: true do
          simulator_launcher.launcher_config.devices = []
          log_path = simulator_launcher.xcodebuild_log_path
          expect(log_path).to eq(
            File.expand_path("#{FastlaneCore::Helper.buildlog_path}/snapshot/Example-ExampleUITests.log").to_s
          )
        end
      end

      describe "Unique logs disabled" do
        let(:options) { { project: "./snapshot/example/Example.xcodeproj", scheme: "ExampleUITests" } }
        let(:simulator_launcher) do
          Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, options)
          launcher_config = Snapshot::SimulatorLauncherConfiguration.new(snapshot_config: Snapshot.config)
          launcher_config.devices = ["iPhone 8"]
          return simulator_launcher = Snapshot::SimulatorLauncher.new(launcher_configuration: launcher_config)
        end

        it 'uses correct file name', requires_xcode: true do
          log_path = simulator_launcher.xcodebuild_log_path(language: "pt", locale: nil)
          expect(log_path).to eq(
            File.expand_path("#{FastlaneCore::Helper.buildlog_path}/snapshot/Example-ExampleUITests.log").to_s
          )
        end
      end
    end

    describe "#pipe" do
      it "uses no pipe with disable_xcpretty", requires_xcodebuild: true do
        options = { project: "./snapshot/example/Example.xcodeproj", scheme: "ExampleUITests", disable_xcpretty: true }
        Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, options)

        pipe = Snapshot::TestCommandGenerator.pipe.join(" ")
        expect(pipe).not_to include("| xcpretty")
        expect(pipe).not_to include("| xcbeautify")
      end

      it "uses no pipe with xcodebuild_formatter with empty string", requires_xcodebuild: true do
        options = { project: "./snapshot/example/Example.xcodeproj", scheme: "ExampleUITests", xcodebuild_formatter: '' }
        Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, options)

        pipe = Snapshot::TestCommandGenerator.pipe.join(" ")
        expect(pipe).not_to include("| xcpretty")
        expect(pipe).not_to include("| xcbeautify")
      end

      describe "with xcodebuild_formatter" do
        describe "with no xcpretty options" do
          it "default when xcbeautify not installed", requires_xcodebuild: true do
            allow(Fastlane::Helper::XcodebuildFormatterHelper).to receive(:xcbeautify_installed?).and_return(false)

            options = { project: "./snapshot/example/Example.xcodeproj", scheme: "ExampleUITests" }
            Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, options)

            pipe = Snapshot::TestCommandGenerator.pipe.join(" ")
            expect(pipe).to include("| xcpretty")
          end

          it "default when xcbeautify installed", requires_xcodebuild: true do
            allow(Fastlane::Helper::XcodebuildFormatterHelper).to receive(:xcbeautify_installed?).and_return(true)

            options = { project: "./snapshot/example/Example.xcodeproj", scheme: "ExampleUITests" }
            Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, options)

            pipe = Snapshot::TestCommandGenerator.pipe.join(" ")
            expect(pipe).to include("| xcbeautify")
          end

          it "xcpretty override when xcbeautify installed", requires_xcodebuild: true do
            allow(Fastlane::Helper::XcodebuildFormatterHelper).to receive(:xcbeautify_installed?).and_return(true)

            options = { project: "./snapshot/example/Example.xcodeproj", scheme: "ExampleUITests", xcodebuild_formatter: 'xcpretty' }
            Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, options)

            pipe = Snapshot::TestCommandGenerator.pipe.join(" ")
            expect(pipe).to include("| xcpretty")
          end

          it "customer formatter", requires_xcodebuild: true do
            allow(Fastlane::Helper::XcodebuildFormatterHelper).to receive(:xcbeautify_installed?).and_return(true)

            options = { project: "./snapshot/example/Example.xcodeproj", scheme: "ExampleUITests", xcodebuild_formatter: "/path/to/xcbeautify" }
            Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, options)

            pipe = Snapshot::TestCommandGenerator.pipe.join(" ")
            expect(pipe).to include("| /path/to/xcbeautify")
          end
        end

        it "with xcpretty options when xcbeautify installed", requires_xcodebuild: true do
          allow(Fastlane::Helper::XcodebuildFormatterHelper).to receive(:xcbeautify_installed?).and_return(true)

          options = { project: "./snapshot/example/Example.xcodeproj", scheme: "ExampleUITests", xcpretty_args: "--rspec" }
          Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, options)

          pipe = Snapshot::TestCommandGenerator.pipe.join(" ")
          expect(pipe).to include("| xcpretty")
        end
      end

      describe "#legacy_xcpretty_options" do
        it "with xcpretty_args", requires_xcodebuild: true do
          options = { project: "./snapshot/example/Example.xcodeproj", scheme: "ExampleUITests", xcpretty_args: "--rspec" }
          Snapshot.config = FastlaneCore::Configuration.create(Snapshot::Options.plain_options, options)

          options = Snapshot::TestCommandGenerator.legacy_xcpretty_options
          expect(options).to eq(['xcpretty_args'])
        end
      end
    end
  end
end
