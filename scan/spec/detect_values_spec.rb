describe Scan do
  describe Scan::DetectValues do
    describe 'Xcode project' do
      describe 'detects FastlaneCore::Project' do
        it 'with no :project or :package_path given', requires_xcodebuild: true do
          # Mocks input from detect_projects
          project = FastlaneCore::Project.new({
            project: "./scan/examples/standard/app.xcodeproj"
          })

          expect(FastlaneCore::Project).to receive(:detect_projects)
          expect(FastlaneCore::Project).to receive(:new).and_return(project)

          options = {}
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        end

        it 'with :project given', requires_xcodebuild: true do
          expect(FastlaneCore::Project).to receive(:detect_projects)
          expect(FastlaneCore::Project).to receive(:new).and_call_original

          options = { project: "./scan/examples/standard/app.xcodeproj" }
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        end
      end
    end

    describe 'SPM package' do
      describe 'does not attempt to detect FastlaneCore::Project' do
        it 'with :package_path given', requires_xcodebuild: true do
          expect(FastlaneCore::Project).to_not(receive(:detect_projects))

          options = { package_path: "./scan/examples/package/" }
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        end
      end
    end

    describe 'test without building' do
      describe 'does not attempt to detect FastlaneCore::Project' do
        it 'with :test_without_building true and :xctestrun given', requires_xcodebuild: true do
          options = {
            test_without_building: true,
            xctestrun: "./scan/examples/standard/DerivedData/Build/testplan.xctestrun"
          }

          expect(FastlaneCore::Project).to_not(receive(:detect_projects))

          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        end
      end

      describe 'detects FastlaneCore::Project' do
        before do
          # Mocks input from detect_projects
          @project = FastlaneCore::Project.new({
            project: "./scan/examples/standard/app.xcodeproj"
          })
        end

        it 'with :test_without_building true and no :xctestrun given', requires_xcodebuild: true do
          options = {
            test_without_building: true
          }

          expect(FastlaneCore::Project).to receive(:detect_projects)
          expect(FastlaneCore::Project).to receive(:new).and_return(@project)

          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        end

        it 'with :test_without_building false', requires_xcodebuild: true do
          options = {
            test_without_building: false
          }

          expect(FastlaneCore::Project).to receive(:detect_projects)
          expect(FastlaneCore::Project).to receive(:new).and_return(@project)

          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        end
      end
    end

    describe 'Xcode config handling' do
      before do
        options = { project: "./scan/examples/standard/app.xcodeproj" }
        FileUtils.mkdir_p("./scan/examples/standard/app.xcodeproj/project.xcworkspace/xcuserdata/#{ENV['USER']}.xcuserdatad/")
        FileUtils.copy("./scan/examples/standard/WorkspaceSettings.xcsettings", "./scan/examples/standard/app.xcodeproj/project.xcworkspace/xcuserdata/#{ENV['USER']}.xcuserdatad/WorkspaceSettings.xcsettings")
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        @project = FastlaneCore::Project.new(Scan.config)
      end

      it "fetches the path from the Xcode config", requires_xcodebuild: true do
        derived_data = Scan.config[:derived_data_path]
        expect(derived_data).to match(File.expand_path("./scan/examples/standard/"))
      end
    end

    describe "#default_os_version" do
      before do
        Scan::DetectValues.clear_cache
      end

      it 'informs users of unknown platform name' do
        expect do
          Scan::DetectValues.default_os_version('test')
        end.to raise_error(FastlaneCore::Interface::FastlaneCrash, "Unknown platform: test")
      end

      it 'returns an error if `xcrun simctl runtime -h` is broken' do
        help_output = 'garbage'
        allow(Open3).to receive(:capture3).with('xcrun simctl runtime -h').and_return([nil, help_output, nil])

        expect do
          Scan::DetectValues.default_os_version('iOS')
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it 'returns an error if `xcodebuild -showsdks -json` is broken' do
        help_output = 'Usage: simctl runtime <operation> <arguments> match list'
        allow(Open3).to receive(:capture3).with('xcrun simctl runtime -h').and_return([nil, help_output, nil])

        sdks_output = 'unexpected output'
        status = double('status', "success?": true)
        allow(Open3).to receive(:capture2).with('xcodebuild -showsdks -json').and_return([sdks_output, status])

        expect do
          Scan::DetectValues.default_os_version('iOS')
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it 'returns an error if `xcodebuild -showsdks -json` exits unsuccessfully' do
        help_output = 'Usage: simctl runtime <operation> <arguments> match list'
        allow(Open3).to receive(:capture3).with('xcrun simctl runtime -h').and_return([nil, help_output, nil])

        sdks_output = File.read('./scan/spec/fixtures/XcodebuildSdksOutput15')
        status = double('status', "success?": false)
        allow(Open3).to receive(:capture2).with('xcodebuild -showsdks -json').and_return([sdks_output, status])

        expect do
          Scan::DetectValues.default_os_version('iOS')
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it 'returns an error if `xcrun simctl runtime match list -j` is broken' do
        help_output = 'Usage: simctl runtime <operation> <arguments> match list'
        allow(Open3).to receive(:capture3).with('xcrun simctl runtime -h').and_return([nil, help_output, nil])

        sdks_output = File.read('./scan/spec/fixtures/XcodebuildSdksOutput15')
        status = double('status', "success?": true)
        allow(Open3).to receive(:capture2).with('xcodebuild -showsdks -json').and_return([sdks_output, status])

        runtime_output = 'unexpected output'
        allow(Open3).to receive(:capture2).with('xcrun simctl runtime match list -j').and_return([runtime_output, status])

        expect do
          Scan::DetectValues.default_os_version('iOS')
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it 'returns an error if `xcrun simctl runtime match list -j` exits unsuccessfully' do
        help_output = 'Usage: simctl runtime <operation> <arguments> match list'
        allow(Open3).to receive(:capture3).with('xcrun simctl runtime -h').and_return([nil, help_output, nil])

        sdks_output = File.read('./scan/spec/fixtures/XcodebuildSdksOutput15')
        success_status = double('status', "success?": true)
        allow(Open3).to receive(:capture2).with('xcodebuild -showsdks -json').and_return([sdks_output, success_status])

        fail_status = double('fail_status', "success?": false)
        runtime_output = File.read('./scan/spec/fixtures/XcrunSimctlRuntimeMatchListOutput15')
        allow(Open3).to receive(:capture2).with('xcrun simctl runtime match list -j').and_return([runtime_output, fail_status])

        expect do
          Scan::DetectValues.default_os_version('iOS')
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      build_os_versions = { "21J353" => "17.0", "21R355" => "10.0", "21A342" => "17.0.1" }
      actual_os_versions = { "tvOS" => "17.0", "watchOS" => "10.0", "iOS" => "17.0.1" }
      %w[iOS tvOS watchOS].each do |os_type|
        it "retrieves the correct runtime build for #{os_type}" do
          help_output = 'Usage: simctl runtime <operation> <arguments> match list'
          allow(Open3).to receive(:capture3).with('xcrun simctl runtime -h').and_return([nil, help_output, nil])

          sdks_output = File.read('./scan/spec/fixtures/XcodebuildSdksOutput15')
          status = double('status', "success?": true)
          allow(Open3).to receive(:capture2).with('xcodebuild -showsdks -json').and_return([sdks_output, status])

          runtime_output = File.read('./scan/spec/fixtures/XcrunSimctlRuntimeMatchListOutput15')
          allow(Open3).to receive(:capture2).with('xcrun simctl runtime match list -j').and_return([runtime_output, status])

          allow(FastlaneCore::DeviceManager).to receive(:runtime_build_os_versions).and_return(build_os_versions)

          expect(Scan::DetectValues.default_os_version(os_type)).to eq(Gem::Version.new(actual_os_versions[os_type]))
        end
      end
    end

    describe "#detect_simulator" do
      it 'returns simulators for requested devices', requires_xcodebuild: true do
        simctl_list_devices_output = double('xcrun simctl list devices', read: File.read("./scan/spec/fixtures/XcrunSimctlListDevicesOutput15"))
        allow(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, simctl_list_devices_output, nil, nil)

        allow(Scan::DetectValues).to receive(:default_os_version).with('iOS').and_return(Gem::Version.new('17.0'))
        allow(Scan::DetectValues).to receive(:default_os_version).with('tvOS').and_return(Gem::Version.new('17.0'))
        allow(Scan::DetectValues).to receive(:default_os_version).with('watchOS').and_return(Gem::Version.new('10.0'))

        devices = ['iPhone 14 Pro Max', 'Apple TV 4K (3rd generation)', 'Apple Watch Ultra (49mm)']
        simulators = Scan::DetectValues.detect_simulator(devices, '', '', '', nil)

        expect(simulators.count).to eq(3)
        expect(simulators[0]).to have_attributes(
          name: "iPhone 14 Pro Max", os_type: "iOS", os_version: "17.0"
        )
        expect(simulators[1]).to have_attributes(
          name: "Apple TV 4K (3rd generation)", os_type: "tvOS", os_version: "17.0"
        )
        expect(simulators[2]).to have_attributes(
          name: "Apple Watch Ultra (49mm)", os_type: "watchOS", os_version: "10.0"
        )
      end

      it 'filters out simulators newer than what the current Xcode SDK supports', requires_xcodebuild: true do
        simctl_list_devices_output = double('xcrun simctl list devices', read: File.read("./scan/spec/fixtures/XcrunSimctlListDevicesOutput14"))
        allow(Open3).to receive(:popen3).with("xcrun simctl list devices").and_yield(nil, simctl_list_devices_output, nil, nil)

        allow(Scan::DetectValues).to receive(:default_os_version).with('iOS').and_return(Gem::Version.new('16.4'))
        allow(Scan::DetectValues).to receive(:default_os_version).with('tvOS').and_return(Gem::Version.new('16.4'))
        allow(Scan::DetectValues).to receive(:default_os_version).with('watchOS').and_return(Gem::Version.new('9.4'))

        devices = ['iPhone 14 Pro Max', 'iPad Pro (12.9-inch) (6th generation) (16.1)', 'Apple TV 4K (3rd generation)', 'Apple Watch Ultra (49mm)']
        simulators = Scan::DetectValues.detect_simulator(devices, '', '', '', nil)

        expect(simulators.count).to eq(4)
        expect(simulators[0]).to have_attributes(
          name: "iPhone 14 Pro Max", os_type: "iOS", os_version: "16.4"
        )
        expect(simulators[1]).to have_attributes(
          name: "iPad Pro (12.9-inch) (6th generation)", os_type: "iOS", os_version: "16.1"
        )
        expect(simulators[2]).to have_attributes(
          name: "Apple TV 4K (3rd generation)", os_type: "tvOS", os_version: "16.4"
        )
        expect(simulators[3]).to have_attributes(
          name: "Apple Watch Ultra (49mm)", os_type: "watchOS", os_version: "9.4"
        )
      end
    end

    describe "#detect_destination" do
      it "ios", requires_xcodebuild: true do
        options = { project: "./scan/examples/standard/app.xcodeproj" }
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        expect(Scan.config[:destination].first).to match(/platform=iOS/)
      end

      context "catalyst" do
        it "ios", requires_xcodebuild: true do
          options = { project: "./scan/examples/standard/app.xcodeproj" }
          expect_any_instance_of(FastlaneCore::Project).not_to receive(:supports_mac_catalyst?)
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
          expect(Scan.config[:destination].first).to match(/platform=iOS/)
        end

        it "mac", requires_xcodebuild: true do
          options = { project: "./scan/examples/standard/app.xcodeproj", catalyst_platform: "macos" }
          expect_any_instance_of(FastlaneCore::Project).to receive(:supports_mac_catalyst?).and_return(true)
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
          expect(Scan.config[:destination].first).to match(/platform=macOS,variant=Mac Catalyst/)
        end
      end

      context ":run_rosetta_simulator" do
        it "adds arch=x86_64 if true", requires_xcodebuild: true do
          options = { project: "./scan/examples/standard/app.xcodeproj", run_rosetta_simulator: true }
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
          expect(Scan.config[:destination].first).to match(/platform=iOS/)
          expect(Scan.config[:destination].first).to match(/,arch=x86_64/)
        end

        it "does not add arch=x86_64 if false", requires_xcodebuild: true do
          options = { project: "./scan/examples/standard/app.xcodeproj", run_rosetta_simulator: false }
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
          expect(Scan.config[:destination].first).to match(/platform=iOS/)
          expect(Scan.config[:destination].first).to_not(match(/,arch=x86_64/))
        end

        it "does not add arch=x86_64 by default", requires_xcodebuild: true do
          options = { project: "./scan/examples/standard/app.xcodeproj" }
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
          expect(Scan.config[:destination].first).to match(/platform=iOS/)
          expect(Scan.config[:destination].first).to_not(match(/,arch=x86_64/))
        end
      end
    end

    describe "validation" do
      before(:each) do
        allow(Fastlane::Helper::XcodebuildFormatterHelper).to receive(:xcbeautify_installed?).and_return(false)
      end

      it "advises of problems with multiple output_types and a custom_report_file_name", requires_xcodebuild: true do
        options = {
          project: "./scan/examples/standard/app.xcodeproj",
          # use default output types
          custom_report_file_name: 'report.xml'
        }
        expect(FastlaneCore::UI).to receive(:user_error!).with("Using a :custom_report_file_name with multiple :output_types (html,junit) will lead to unexpected results. Use :output_files instead.")
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
      end

      it "does not advise of a problem with one output_type and a custom_report_file_name", requires_xcodebuild: true do
        options = {
          project: "./scan/examples/standard/app.xcodeproj",
          output_types: 'junit',
          custom_report_file_name: 'report.xml'
        }
        expect(FastlaneCore::UI).not_to(receive(:user_error!))
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
      end
    end

    describe "value coercion" do
      it "coerces only_testing to be an array", requires_xcodebuild: true do
        options = {
          project: "./scan/examples/standard/app.xcodeproj",
          only_testing: "Bundle/SuiteA"
        }
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        expect(Scan.config[:only_testing]).to eq(["Bundle/SuiteA"])
      end

      it "coerces skip_testing to be an array", requires_xcodebuild: true do
        options = {
          project: "./scan/examples/standard/app.xcodeproj",
          skip_testing: "Bundle/SuiteA,Bundle/SuiteB"
        }
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        expect(Scan.config[:skip_testing]).to eq(["Bundle/SuiteA", "Bundle/SuiteB"])
      end

      it "leaves skip_testing as an array", requires_xcodebuild: true do
        options = {
          project: "./scan/examples/standard/app.xcodeproj",
          skip_testing: ["Bundle/SuiteA", "Bundle/SuiteB"]
        }
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        expect(Scan.config[:skip_testing]).to eq(["Bundle/SuiteA", "Bundle/SuiteB"])
      end

      it "coerces only_test_configurations to be an array", requires_xcodebuild: true do
        options = {
          project: "./scan/examples/standard/app.xcodeproj",
          only_test_configurations: "ConfigurationA"
        }
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        expect(Scan.config[:only_test_configurations]).to eq(["ConfigurationA"])
      end

      it "coerces skip_test_configurations to be an array", requires_xcodebuild: true do
        options = {
          project: "./scan/examples/standard/app.xcodeproj",
          skip_test_configurations: "ConfigurationA,ConfigurationB"
        }
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        expect(Scan.config[:skip_test_configurations]).to eq(["ConfigurationA", "ConfigurationB"])
      end

      it "leaves skip_test_configurations as an array", requires_xcodebuild: true do
        options = {
          project: "./scan/examples/standard/app.xcodeproj",
          skip_test_configurations: ["ConfigurationA", "ConfigurationB"]
        }
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, options)
        expect(Scan.config[:skip_test_configurations]).to eq(["ConfigurationA", "ConfigurationB"])
      end
    end
  end
end
