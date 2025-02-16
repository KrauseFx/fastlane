describe FastlaneCore do
  describe FastlaneCore::Project do
    describe 'project and workspace detection' do
      def within_a_temp_dir
        Dir.mktmpdir do |dir|
          FileUtils.cd(dir) do
            yield(dir) if block_given?
          end
        end
      end

      let(:options) do
        [
          FastlaneCore::ConfigItem.new(key: :project, description: "Project", optional: true),
          FastlaneCore::ConfigItem.new(key: :workspace, description: "Workspace", optional: true)
        ]
      end

      it 'raises if both project and workspace are specified' do
        expect do
          config = FastlaneCore::Configuration.new(options, { project: 'yup', workspace: 'yeah' })
          FastlaneCore::Project.detect_projects(config)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "You can only pass either a workspace or a project path, not both")
      end

      it 'keeps the specified project' do
        config = FastlaneCore::Configuration.new(options, { project: 'yup' })
        FastlaneCore::Project.detect_projects(config)

        expect(config[:project]).to eq('yup')
        expect(config[:workspace]).to be_nil
      end

      it 'keeps the specified workspace' do
        config = FastlaneCore::Configuration.new(options, { workspace: 'yeah' })
        FastlaneCore::Project.detect_projects(config)

        expect(config[:project]).to be_nil
        expect(config[:workspace]).to eq('yeah')
      end

      it 'picks the only workspace file present' do
        within_a_temp_dir do |dir|
          workspace = './Something.xcworkspace'
          FileUtils.mkdir_p(workspace)

          config = FastlaneCore::Configuration.new(options, {})
          FastlaneCore::Project.detect_projects(config)

          expect(config[:workspace]).to eq(workspace)
        end
      end

      it 'picks the only project file present' do
        within_a_temp_dir do |dir|
          project = './Something.xcodeproj'
          FileUtils.mkdir_p(project)

          config = FastlaneCore::Configuration.new(options, {})
          FastlaneCore::Project.detect_projects(config)

          expect(config[:project]).to eq(project)
        end
      end

      it 'prompts to select among multiple workspace files' do
        within_a_temp_dir do |dir|
          workspaces = ['./Something.xcworkspace', './SomethingElse.xcworkspace']
          FileUtils.mkdir_p(workspaces)

          expect(FastlaneCore::Project).to receive(:choose).and_return(workspaces.last)
          expect(FastlaneCore::Project).not_to(receive(:select_project))

          config = FastlaneCore::Configuration.new(options, {})
          FastlaneCore::Project.detect_projects(config)

          expect(config[:workspace]).to eq(workspaces.last)
        end
      end

      it 'prompts to select among multiple project files' do
        within_a_temp_dir do |dir|
          projects = ['./Something.xcodeproj', './SomethingElse.xcodeproj']
          FileUtils.mkdir_p(projects)

          expect(FastlaneCore::Project).to receive(:choose).and_return(projects.last)
          expect(FastlaneCore::Project).not_to(receive(:select_project))

          config = FastlaneCore::Configuration.new(options, {})
          FastlaneCore::Project.detect_projects(config)

          expect(config[:project]).to eq(projects.last)
        end
      end

      it 'asks the user to specify a project when none are found' do
        within_a_temp_dir do |dir|
          project = './subdir/Something.xcodeproj'
          FileUtils.mkdir_p(project)

          expect(FastlaneCore::UI).to receive(:input).and_return(project)

          config = FastlaneCore::Configuration.new(options, {})
          FastlaneCore::Project.detect_projects(config)

          expect(config[:project]).to eq(project)
        end
      end

      it 'asks the user to specify a workspace when none are found' do
        within_a_temp_dir do |dir|
          workspace = './subdir/Something.xcworkspace'
          FileUtils.mkdir_p(workspace)

          expect(FastlaneCore::UI).to receive(:input).and_return(workspace)

          config = FastlaneCore::Configuration.new(options, {})
          FastlaneCore::Project.detect_projects(config)

          expect(config[:workspace]).to eq(workspace)
        end
      end

      it 'explains when a provided path is not found' do
        within_a_temp_dir do |dir|
          workspace = './subdir/Something.xcworkspace'
          FileUtils.mkdir_p(workspace)

          expect(FastlaneCore::UI).to receive(:input).and_return("something wrong")
          expect(FastlaneCore::UI).to receive(:error).with(/Couldn't find/)
          expect(FastlaneCore::UI).to receive(:input).and_return(workspace)

          config = FastlaneCore::Configuration.new(options, {})
          FastlaneCore::Project.detect_projects(config)

          expect(config[:workspace]).to eq(workspace)
        end
      end

      it 'explains when a provided path is not valid' do
        within_a_temp_dir do |dir|
          workspace = './subdir/Something.xcworkspace'
          FileUtils.mkdir_p(workspace)
          FileUtils.mkdir_p('other-directory')

          expect(FastlaneCore::UI).to receive(:input).and_return('other-directory')
          expect(FastlaneCore::UI).to receive(:error).with(/Path must end with/)
          expect(FastlaneCore::UI).to receive(:input).and_return(workspace)

          config = FastlaneCore::Configuration.new(options, {})
          FastlaneCore::Project.detect_projects(config)

          expect(config[:workspace]).to eq(workspace)
        end
      end
    end

    it "raises an exception if path was not found" do
      tmp_path = Dir.mktmpdir
      path = "#{tmp_path}/notHere123"
      expect do
        FastlaneCore::Project.new(project: path)
      end.to raise_error("Could not find project at path '#{path}'")
    end

    describe "Valid Standard Project" do
      before do
        options = { project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj" }
        @project = FastlaneCore::Project.new(options)
      end

      it "#path" do
        expect(@project.path).to eq(File.expand_path("./fastlane_core/spec/fixtures/projects/Example.xcodeproj"))
      end

      it "#is_workspace" do
        expect(@project.is_workspace).to eq(false)
      end

      it "#workspace" do
        expect(@project.workspace).to be_nil
      end

      it "#project" do
        expect(@project.project).to_not(be_nil)
      end

      it "#project_name" do
        expect(@project.project_name).to eq("Example")
      end

      it "#schemes returns all available schemes" do
        expect(@project.schemes).to eq(["Example"])
      end

      it "#configurations returns all available configurations" do
        expect(@project.configurations).to eq(["Debug", "Release", "SpecialConfiguration"])
      end

      it "#app_name", requires_xcode: true do
        expect(@project.app_name).to eq("ExampleProductName")
      end

      it "#mac?", requires_xcode: true do
        expect(@project.mac?).to eq(false)
      end

      it "#ios?", requires_xcode: true do
        expect(@project.ios?).to eq(true)
      end

      it "#multiplatform?", requires_xcode: true do
        expect(@project.multiplatform?).to eq(false)
      end

      it "#tvos?", requires_xcode: true do
        expect(@project.tvos?).to eq(false)
      end
    end

    describe "Valid CocoaPods Project" do
      before do
        options = {
          workspace: "./fastlane_core/spec/fixtures/projects/cocoapods/Example.xcworkspace",
          scheme: "Example"
        }
        @workspace = FastlaneCore::Project.new(options)
      end

      it "#schemes returns all schemes" do
        expect(@workspace.schemes).to eq(["Example"])
      end

      it "#schemes returns all configurations" do
        expect(@workspace.configurations).to eq(["Debug", "Release"])
      end
    end

    describe "Mac Project" do
      before do
        options = { project: "./fastlane_core/spec/fixtures/projects/Mac.xcodeproj" }
        @project = FastlaneCore::Project.new(options)
      end

      it "#mac?", requires_xcode: true do
        expect(@project.mac?).to eq(true)
      end

      it "#ios?", requires_xcode: true do
        expect(@project.ios?).to eq(false)
      end

      it "#tvos?", requires_xcode: true do
        expect(@project.tvos?).to eq(false)
      end

      it "#multiplatform?", requires_xcode: true do
        expect(@project.multiplatform?).to eq(false)
      end

      it "schemes", requires_xcodebuild: true do
        expect(@project.schemes).to eq(["Mac"])
      end
    end

    describe "TVOS Project" do
      before do
        options = { project: "./fastlane_core/spec/fixtures/projects/ExampleTVOS.xcodeproj" }
        @project = FastlaneCore::Project.new(options)
      end

      it "#mac?", requires_xcode: true do
        expect(@project.mac?).to eq(false)
      end

      it "#ios?", requires_xcode: true do
        expect(@project.ios?).to eq(false)
      end

      it "#tvos?", requires_xcode: true do
        expect(@project.tvos?).to eq(true)
      end

      it "#multiplatform?", requires_xcode: true do
        expect(@project.multiplatform?).to eq(false)
      end

      it "schemes", requires_xcodebuild: true do
        expect(@project.schemes).to eq(["ExampleTVOS"])
      end
    end

    describe "Cross-Platform Project" do
      before do
        options = { project: "./fastlane_core/spec/fixtures/projects/Cross-Platform.xcodeproj" }
        @project = FastlaneCore::Project.new(options)
      end

      it "supported_platforms", requires_xcode: true do
        expect(@project.supported_platforms).to eq([:macOS, :iOS, :tvOS, :watchOS])
      end

      it "#mac?", requires_xcode: true do
        expect(@project.mac?).to eq(true)
      end

      it "#ios?", requires_xcode: true do
        expect(@project.ios?).to eq(true)
      end

      it "#tvos?", requires_xcode: true do
        expect(@project.tvos?).to eq(true)
      end

      it "#multiplatform?", requires_xcode: true do
        expect(@project.multiplatform?).to eq(true)
      end

      it "schemes", requires_xcodebuild: true do
        expect(@project.schemes).to eq(["CrossPlatformFramework"])
      end
    end

    describe "Valid Workspace with workspace contained schemes" do
      before do
        options = {
          workspace: "./fastlane_core/spec/fixtures/projects/workspace_schemes/WorkspaceSchemes.xcworkspace",
          scheme: "WorkspaceSchemesScheme"
        }
        @workspace = FastlaneCore::Project.new(options)
      end

      it "#schemes returns all schemes" do
        expect(@workspace.schemes).to eq(["WorkspaceSchemesFramework", "WorkspaceSchemesApp", "WorkspaceSchemesScheme"])
      end

      it "#schemes returns all configurations" do
        expect(@workspace.configurations).to eq(["Debug", "Release", "Debug", "Release"])
      end
    end

    describe "build_settings() can handle empty lines" do
      it "SUPPORTED_PLATFORMS should be iphonesimulator iphoneos on Xcode >= 8.3" do
        options = { project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj" }
        @project = FastlaneCore::Project.new(options)
        allow(FastlaneCore::Helper).to receive(:xcode_at_least?).with("11.0").and_return(false)
        allow(FastlaneCore::Helper).to receive(:xcode_at_least?).with("13").and_return(false)
        expect(FastlaneCore::Helper).to receive(:xcode_at_least?).with("8.3").and_return(true)
        command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj 2>&1"
        expect(FastlaneCore::Project).to receive(:run_command).with(command, { timeout: 3, retries: 3, print: true }).and_return(File.read("./fastlane_core/spec/fixtures/projects/build_settings_with_toolchains"))
        expect(@project.build_settings(key: "SUPPORTED_PLATFORMS")).to eq("iphonesimulator iphoneos")
      end

      it "SUPPORTED_PLATFORMS should be iphonesimulator iphoneos on Xcode < 8.3" do
        options = { project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj" }
        @project = FastlaneCore::Project.new(options)
        allow(FastlaneCore::Helper).to receive(:xcode_at_least?).with("11.0").and_return(false)
        allow(FastlaneCore::Helper).to receive(:xcode_at_least?).with("13").and_return(false)
        expect(FastlaneCore::Helper).to receive(:xcode_at_least?).with("8.3").and_return(false)
        command = "xcodebuild clean -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj 2>&1"
        expect(FastlaneCore::Project).to receive(:run_command).with(command, { timeout: 3, retries: 3, print: true }).and_return(File.read("./fastlane_core/spec/fixtures/projects/build_settings_with_toolchains"))
        expect(@project.build_settings(key: "SUPPORTED_PLATFORMS")).to eq("iphonesimulator iphoneos")
      end
    end

    describe "Build Settings with default configuration" do
      before do
        options = { project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj" }
        @project = FastlaneCore::Project.new(options)
      end

      it "IPHONEOS_DEPLOYMENT_TARGET should be 9.0", requires_xcode: true do
        expect(@project.build_settings(key: "IPHONEOS_DEPLOYMENT_TARGET")).to eq("9.0")
      end

      it "PRODUCT_BUNDLE_IDENTIFIER should be tools.fastlane.app", requires_xcode: true do
        expect(@project.build_settings(key: "PRODUCT_BUNDLE_IDENTIFIER")).to eq("tools.fastlane.app")
      end
    end

    describe "Build Settings with specific configuration" do
      before do
        options = {
          project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
          configuration: "SpecialConfiguration"
        }
        @project = FastlaneCore::Project.new(options)
      end

      it "IPHONEOS_DEPLOYMENT_TARGET should be 9.0", requires_xcode: true do
        expect(@project.build_settings(key: "IPHONEOS_DEPLOYMENT_TARGET")).to eq("9.0")
      end

      it "PRODUCT_BUNDLE_IDENTIFIER should be tools.fastlane.app.special", requires_xcode: true do
        expect(@project.build_settings(key: "PRODUCT_BUNDLE_IDENTIFIER")).to eq("tools.fastlane.app.special")
      end
    end

    describe 'Project.xcode_build_settings_timeout' do
      before do
        ENV['FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT'] = nil
      end
      it "returns default value" do
        expect(FastlaneCore::Project.xcode_build_settings_timeout).to eq(3)
      end
      it "returns specified value" do
        ENV['FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT'] = '5'
        expect(FastlaneCore::Project.xcode_build_settings_timeout).to eq(5)
      end
      it "returns 0 if empty" do
        ENV['FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT'] = ''
        expect(FastlaneCore::Project.xcode_build_settings_timeout).to eq(0)
      end
      it "returns 0 if garbage" do
        ENV['FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT'] = 'hiho'
        expect(FastlaneCore::Project.xcode_build_settings_timeout).to eq(0)
      end
    end

    describe 'Project.xcode_build_settings_retries' do
      before do
        ENV['FASTLANE_XCODEBUILD_SETTINGS_RETRIES'] = nil
      end
      it "returns default value" do
        expect(FastlaneCore::Project.xcode_build_settings_retries).to eq(3)
      end
      it "returns specified value" do
        ENV['FASTLANE_XCODEBUILD_SETTINGS_RETRIES'] = '5'
        expect(FastlaneCore::Project.xcode_build_settings_retries).to eq(5)
      end
      it "returns 0 if empty" do
        ENV['FASTLANE_XCODEBUILD_SETTINGS_RETRIES'] = ''
        expect(FastlaneCore::Project.xcode_build_settings_retries).to eq(0)
      end
      it "returns 0 if garbage" do
        ENV['FASTLANE_XCODEBUILD_SETTINGS_RETRIES'] = 'hiho'
        expect(FastlaneCore::Project.xcode_build_settings_retries).to eq(0)
      end
    end

    describe "Project.run_command" do
      def count_processes(text)
        `ps -aef | grep #{text} | grep -v grep | wc -l`.to_i
      end

      it "runs simple commands" do
        cmd = 'echo HO' # note: this command is deliberately not using `"` around `HO` as `echo` would echo those back on Windows
        expect(FastlaneCore::Project.run_command(cmd)).to eq("HO\n")
      end

      it "runs more complicated commands" do
        cmd = "ruby -e 'sleep 0.1; puts \"HI\"'"
        expect(FastlaneCore::Project.run_command(cmd)).to eq("HI\n")
      end

      it "should timeouts and kills" do
        text = "FOOBAR" # random text
        count = count_processes(text)
        cmd = "ruby -e 'sleep 3; puts \"#{text}\"'"
        expect do
          FastlaneCore::Project.run_command(cmd, timeout: 1)
        end.to raise_error(Timeout::Error)

        # on mac this before only partially works as expected
        if FastlaneCore::Helper.mac?
          # this shows the current implementation issue
          # Timeout doesn't kill the running process
          # i.e. see fastlane/fastlane_core#102
          expect(count_processes(text)).to eq(count + 1)
          sleep(5)
          expect(count_processes(text)).to eq(count)
          # you would be expected to be able to see the number of processes go back to count right away.
        end
      end

      it "retries and kills" do
        text = "NEEDSRETRY"
        cmd = "ruby -e 'sleep 3; puts \"#{text}\"'"

        expect(FastlaneCore::Project).to receive(:`).and_call_original.exactly(4).times

        expect do
          FastlaneCore::Project.run_command(cmd, timeout: 0.2, retries: 3)
        end.to raise_error(Timeout::Error)
      end
    end

    describe "xcodebuild derived_data_path" do
      it 'generates an xcodebuild -showBuildSettings command that includes derived_data_path if provided in options', requires_xcode: true do
        project = FastlaneCore::Project.new({
          project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
          derived_data_path: "./special/path/DerivedData"
        })
        command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj -derivedDataPath ./special/path/DerivedData 2>&1"
        expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
      end
    end

    describe "xcodebuild disable_package_automatic_updates" do
      it 'generates xcodebuild -showBuildSettings command with disabled automatic package resolution' do
        allow(FastlaneCore::Helper).to receive(:xcode_at_least?).and_return(true)
        project = FastlaneCore::Project.new({
          project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
          disable_package_automatic_updates: true
        })
        command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj -disableAutomaticPackageResolution 2>&1"
        expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
      end
    end

    describe "xcodebuild package_authorization_provider" do
      it 'generates an xcodebuild -showBuildSettings command that includes package_authorization_provider if provided in options', requires_xcode: true do
        project = FastlaneCore::Project.new({
          project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
          package_authorization_provider: "keychain"
        })
        command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj -packageAuthorizationProvider keychain 2>&1"
        expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
      end
    end

    describe 'xcodebuild_xcconfig option', requires_xcode: true do
      it 'generates an xcodebuild -showBuildSettings command without xcconfig by default' do
        project = FastlaneCore::Project.new({ project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj" })
        command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj 2>&1"
        expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
      end

      it 'generates an xcodebuild -showBuildSettings command that includes xcconfig if provided in options', requires_xcode: true do
        project = FastlaneCore::Project.new({
          project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
          xcconfig: "/path/to/some.xcconfig"
        })
        command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj -xcconfig /path/to/some.xcconfig 2>&1"
        expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
      end
    end

    describe "xcodebuild use_system_scm" do
      it 'generates an xcodebuild -showBuildSettings command that includes scmProvider if provided in options', requires_xcode: true do
        project = FastlaneCore::Project.new({
          project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
          use_system_scm: true
        })
        command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj -scmProvider system 2>&1"
        expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
      end

      it 'generates an xcodebuild -showBuildSettings command that does not include scmProvider when not provided in options', requires_xcode: true do
        project = FastlaneCore::Project.new({
          project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj"
        })
        command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj 2>&1"
        expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
      end

      it 'generates an xcodebuild -showBuildSettings command that does not include scmProvider when the option provided is false', requires_xcode: true do
        project = FastlaneCore::Project.new({
          project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
          use_system_scm: false
        })
        command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj 2>&1"
        expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
      end
    end

    describe 'xcodebuild command for SwiftPM', requires_xcode: true do
      it 'generates an xcodebuild -resolvePackageDependencies command with Xcode >= 11' do
        allow(FastlaneCore::Helper).to receive(:xcode_at_least?).and_return(true)
        project = FastlaneCore::Project.new({ project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj" })
        command = "xcodebuild -resolvePackageDependencies -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj"
        expect(project.build_xcodebuild_resolvepackagedependencies_command).to eq(command)
      end

      it 'generates an xcodebuild -resolvePackageDependencies command with a custom resolving path with Xcode >= 11' do
        allow(FastlaneCore::Helper).to receive(:xcode_at_least?).and_return(true)
        project = FastlaneCore::Project.new({
          project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
          cloned_source_packages_path: "./path/to/resolve"
        })
        command = "xcodebuild -resolvePackageDependencies -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj -clonedSourcePackagesDirPath ./path/to/resolve"
        expect(project.build_xcodebuild_resolvepackagedependencies_command).to eq(command)
      end

      it 'generates nil if skip_package_dependencies_resolution is true' do
        allow(FastlaneCore::Helper).to receive(:xcode_at_least?).and_return(true)
        project = FastlaneCore::Project.new({
          project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
          skip_package_dependencies_resolution: true
        })
        expect(project.build_xcodebuild_resolvepackagedependencies_command).to be_nil
      end

      it 'build_settings() should not add SPM path if Xcode < 11' do
        allow(FastlaneCore::Helper).to receive(:xcode_at_least?).with("8.3").and_return(true)
        expect(FastlaneCore::Helper).to receive(:xcode_at_least?).with("11.0").and_return(false)
        expect(FastlaneCore::Helper).to receive(:xcode_at_least?).with("13").and_return(false)
        project = FastlaneCore::Project.new({
          project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
          cloned_source_packages_path: "./path/to/resolve"
        })
        command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj 2>&1"
        expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
      end

      it 'generates even if given options do not support skip_package_dependencies_resolution' do
        config = FastlaneCore::Configuration.create(
          [
            FastlaneCore::ConfigItem.new(key: :workspace, optional: true),
            FastlaneCore::ConfigItem.new(key: :project, optional: true)
          ], {
            project: './fastlane_core/spec/fixtures/projects/Example.xcodeproj'
          }
        )
        project = FastlaneCore::Project.new(config)
        expect(project.build_xcodebuild_resolvepackagedependencies_command).to_not(be_nil)
        expect { project.build_xcodebuild_resolvepackagedependencies_command }.to_not(raise_error)
      end
    end

    describe "xcodebuild destination parameter" do
      context "when xcode version is at_least 13" do
        before(:each) do
          allow(FastlaneCore::Helper).to receive(:xcode_at_least?).with("8.3").and_return(true)
          allow(FastlaneCore::Helper).to receive(:xcode_at_least?).with("11.0").and_return(true)
          allow(FastlaneCore::Helper).to receive(:xcode_at_least?).with("13").and_return(true)
        end

        context "when destination parameter is provided in options" do
          it 'generates an xcodebuild -showBuildSettings command that includes destination', requires_xcode: true do
            project = FastlaneCore::Project.new({
              project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
              destination: "FakeDestination"
            })
            command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj -destination FakeDestination 2>&1"
            expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
          end

          it 'generates an xcodebuild -resolvePackageDependencies command that includes destination' do
            project = FastlaneCore::Project.new({
              project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
              destination: "FakeDestination"
              })
            command = "xcodebuild -resolvePackageDependencies -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj -destination FakeDestination"
            expect(project.build_xcodebuild_resolvepackagedependencies_command).to eq(command)
          end
        end

        context "when destination parameter is not provided in options" do
          it 'generates an xcodebuild -showBuildSettings command that does not include destination', requires_xcode: true do
            project = FastlaneCore::Project.new({
              project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj"
            })
            command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj 2>&1"
            expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
          end

          it 'generates an xcodebuild -resolvePackageDependencies command that does not include destination' do
            project = FastlaneCore::Project.new({
              project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj"
              })
            command = "xcodebuild -resolvePackageDependencies -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj"
            expect(project.build_xcodebuild_resolvepackagedependencies_command).to eq(command)
          end
        end
      end

      context "when xcode version is less than 13" do
        before(:each) do
          allow(FastlaneCore::Helper).to receive(:xcode_at_least?).with("8.3").and_return(true)
          allow(FastlaneCore::Helper).to receive(:xcode_at_least?).with("11.0").and_return(true)
          allow(FastlaneCore::Helper).to receive(:xcode_at_least?).with("13").and_return(false)
        end

        context "when destination parameter is provided in options" do
          it 'generates an xcodebuild -showBuildSettings command that does not include destination', requires_xcode: true do
            project = FastlaneCore::Project.new({
              project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
              destination: "FakeDestination"
            })
            command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj 2>&1"
            expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
          end

          it 'generates an xcodebuild -resolvePackageDependencies command that does not include destination' do
            project = FastlaneCore::Project.new({
              project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj",
              destination: "FakeDestination"
              })
            command = "xcodebuild -resolvePackageDependencies -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj"
            expect(project.build_xcodebuild_resolvepackagedependencies_command).to eq(command)
          end
        end

        context "when destination parameter is not provided in options" do
          it 'generates an xcodebuild -showBuildSettings command that does not include destination', requires_xcode: true do
            project = FastlaneCore::Project.new({
              project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj"
            })
            command = "xcodebuild -showBuildSettings -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj 2>&1"
            expect(project.build_xcodebuild_showbuildsettings_command).to eq(command)
          end

          it 'generates an xcodebuild -resolvePackageDependencies command that does not include destination' do
            project = FastlaneCore::Project.new({
              project: "./fastlane_core/spec/fixtures/projects/Example.xcodeproj"
              })
            command = "xcodebuild -resolvePackageDependencies -project ./fastlane_core/spec/fixtures/projects/Example.xcodeproj"
            expect(project.build_xcodebuild_resolvepackagedependencies_command).to eq(command)
          end
        end
      end
    end

    describe "#project_paths" do
      it "works with basic projects" do
        project = FastlaneCore::Project.new({
          project: "gym/lib"
        })

        expect(project.project_paths).to be_an(Array)
        expect(project.project_paths).to eq([File.expand_path("gym/lib")])
      end

      it "works with workspaces containing projects referenced relative by group" do
        workspace_path = "fastlane_core/spec/fixtures/projects/project_paths/groups/FooBar.xcworkspace"
        project = FastlaneCore::Project.new({
          workspace: workspace_path
        })

        expect(project.project_paths).to eq([
                                              File.expand_path(workspace_path.gsub("FooBar.xcworkspace", "FooBar/FooBar.xcodeproj"))
                                            ])
      end

      it "works with workspaces containing projects referenced relative by workspace" do
        workspace_path = "fastlane_core/spec/fixtures/projects/project_paths/containers/FooBar.xcworkspace"
        project = FastlaneCore::Project.new({
          workspace: workspace_path
        })

        expect(project.project_paths).to eq([
                                              File.expand_path(workspace_path.gsub("FooBar.xcworkspace", "FooBar/FooBar.xcodeproj"))
                                            ])
      end
    end
  end
end
