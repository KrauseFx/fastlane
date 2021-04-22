describe Gym do
  before(:all) do
    options = { project: "./gym/examples/standard/Example.xcodeproj" }
    config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
    @project = FastlaneCore::Project.new(config)
  end

  before(:each) do
    @project.options.delete(:use_system_scm)
    allow(Gym).to receive(:project).and_return(@project)
  end

  describe Gym::BuildCommandGenerator do
    it "raises an exception when project path wasn't found" do
      tmp_path = Dir.mktmpdir
      path = "#{tmp_path}/notExistent"
      expect do
        Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, { project: path })
      end.to raise_error("Project file not found at path '#{path}'")
    end

    it "supports additional parameters", requires_xcodebuild: true do
      log_path = File.expand_path("#{FastlaneCore::Helper.buildlog_path}/gym/ExampleProductName-Example.log")

      xcargs = { DEBUG: "1", BUNDLE_NAME: "Example App" }
      options = { project: "./gym/examples/standard/Example.xcodeproj", sdk: "9.0", toolchain: "com.apple.dt.toolchain.Swift_2_3", xcargs: xcargs, scheme: 'Example' }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::BuildCommandGenerator.generate
      expect(result).to eq([
                             "set -o pipefail &&",
                             "xcodebuild",
                             "-scheme Example",
                             "-project ./gym/examples/standard/Example.xcodeproj",
                             "-sdk '9.0'",
                             "-toolchain 'com.apple.dt.toolchain.Swift_2_3'",
                             "-destination 'generic/platform=iOS'",
                             "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                             "DEBUG=1 BUNDLE_NAME=Example\\ App",
                             :archive,
                             "| tee #{log_path.shellescape}",
                             "| xcpretty"
                           ])
    end

    it "disables xcpretty formatting", requires_xcodebuild: true do
      log_path = File.expand_path("#{FastlaneCore::Helper.buildlog_path}/gym/ExampleProductName-Example.log")

      xcargs = { DEBUG: "1", BUNDLE_NAME: "Example App" }
      options = { project: "./gym/examples/standard/Example.xcodeproj", sdk: "9.0", xcargs: xcargs, scheme: 'Example', disable_xcpretty: true }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::BuildCommandGenerator.generate
      expect(result).to eq([
                             "set -o pipefail &&",
                             "xcodebuild",
                             "-scheme Example",
                             "-project ./gym/examples/standard/Example.xcodeproj",
                             "-sdk '9.0'",
                             "-destination 'generic/platform=iOS'",
                             "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                             "DEBUG=1 BUNDLE_NAME=Example\\ App",
                             :archive,
                             "| tee #{log_path.shellescape}"
                           ])
    end

    it "enables unicode", requires_xcodebuild: true do
      log_path = File.expand_path("#{FastlaneCore::Helper.buildlog_path}/gym/ExampleProductName-Example.log")

      xcargs = { DEBUG: "1", BUNDLE_NAME: "Example App" }
      options = { project: "./gym/examples/standard/Example.xcodeproj", sdk: "9.0", xcargs: xcargs, scheme: 'Example', xcpretty_utf: true }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::BuildCommandGenerator.generate
      expect(result).to eq([
                             "set -o pipefail &&",
                             "xcodebuild",
                             "-scheme Example",
                             "-project ./gym/examples/standard/Example.xcodeproj",
                             "-sdk '9.0'",
                             "-destination 'generic/platform=iOS'",
                             "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                             "DEBUG=1 BUNDLE_NAME=Example\\ App",
                             :archive,
                             "| tee #{log_path.shellescape}",
                             "| xcpretty",
                             "--utf"
                           ])
    end

    it "uses system scm", requires_xcodebuild: true do
      options = { project: "./gym/examples/standard/Example.xcodeproj", use_system_scm: true }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
      result = Gym::BuildCommandGenerator.generate
      expect(result).to include("-scmProvider system").once
    end

    it "uses system scm via project options", requires_xcodebuild: true do
      options = { project: "./gym/examples/standard/Example.xcodeproj" }
      @project.options[:use_system_scm] = true
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
      result = Gym::BuildCommandGenerator.generate
      expect(result).to include("-scmProvider system").once
    end

    it "uses system scm options exactly once", requires_xcodebuild: true do
      options = { project: "./gym/examples/standard/Example.xcodeproj", use_system_scm: true }
      @project.options[:use_system_scm] = true
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
      result = Gym::BuildCommandGenerator.generate
      expect(result).to include("-scmProvider system").once
    end

    it "defaults to Xcode scm when option is not provided", requires_xcodebuild: true do
      options = { project: "./gym/examples/standard/Example.xcodeproj" }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
      result = Gym::BuildCommandGenerator.generate
      expect(result).to_not(include("-scmProvider system"))
    end

    it "uses the correct build command when `skip_archive` is used", requires_xcodebuild: true do
      log_path = File.expand_path("#{FastlaneCore::Helper.buildlog_path}/gym/ExampleProductName-Example.log")

      options = { project: "./gym/examples/standard/Example.xcodeproj", scheme: 'Example', skip_archive: true }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::BuildCommandGenerator.generate
      expect(result).to eq([
                             "set -o pipefail &&",
                             "xcodebuild",
                             "-scheme Example",
                             "-project ./gym/examples/standard/Example.xcodeproj",
                             "-destination 'generic/platform=iOS'",
                             :build,
                             "| tee #{log_path.shellescape}",
                             "| xcpretty"
                           ])
    end

    describe "Standard Example" do
      before do
        options = { project: "./gym/examples/standard/Example.xcodeproj", scheme: 'Example' }
        Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
      end

      it "uses the correct build command with the example project with no additional parameters", requires_xcodebuild: true do
        log_path = File.expand_path("#{FastlaneCore::Helper.buildlog_path}/gym/ExampleProductName-Example.log")

        result = Gym::BuildCommandGenerator.generate
        expect(result).to eq([
                               "set -o pipefail &&",
                               "xcodebuild",
                               "-scheme Example",
                               "-project ./gym/examples/standard/Example.xcodeproj",
                               "-destination 'generic/platform=iOS'",
                               "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                               :archive,
                               "| tee #{log_path.shellescape}",
                               "| xcpretty"
                             ])
      end

      it "#project_path_array", requires_xcodebuild: true do
        result = Gym::BuildCommandGenerator.project_path_array
        expect(result).to eq(["-scheme Example", "-project ./gym/examples/standard/Example.xcodeproj"])
      end

      it "default #build_path", requires_xcodebuild: true do
        result = Gym::BuildCommandGenerator.build_path
        regex = %r{Library/Developer/Xcode/Archives/\d\d\d\d\-\d\d\-\d\d}
        expect(result).to match(regex)
      end

      it "user provided #build_path", requires_xcodebuild: true do
        options = { project: "./gym/examples/standard/Example.xcodeproj", build_path: "/tmp/my/build_path", scheme: 'Example' }
        Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
        result = Gym::BuildCommandGenerator.build_path
        expect(result).to eq("/tmp/my/build_path")
      end

      it "#archive_path", requires_xcodebuild: true do
        result = Gym::BuildCommandGenerator.archive_path
        regex = %r{Library/Developer/Xcode/Archives/\d\d\d\d\-\d\d\-\d\d/ExampleProductName \d\d\d\d\-\d\d\-\d\d \d\d\.\d\d\.\d\d.xcarchive}
        expect(result).to match(regex)
      end

      it "#buildlog_path is used when provided", requires_xcodebuild: true do
        options = { project: "./gym/examples/standard/Example.xcodeproj", buildlog_path: "/tmp/my/path", scheme: 'Example' }
        Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
        result = Gym::BuildCommandGenerator.xcodebuild_log_path
        expect(result).to include("/tmp/my/path")
      end

      it "#buildlog_path is not used when not provided", requires_xcodebuild: true do
        result = Gym::BuildCommandGenerator.xcodebuild_log_path
        expect(result.to_s).to include(File.expand_path("#{FastlaneCore::Helper.buildlog_path}/gym"))
      end
    end

    describe "Derived Data Example" do
      before(:each) do
        options = { project: "./gym/examples/standard/Example.xcodeproj", derived_data_path: "/tmp/my/derived_data", scheme: 'Example' }
        config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
        @project = FastlaneCore::Project.new(config)
        Gym.config = config
        allow(Gym).to receive(:project).and_return(@project)
      end

      it "uses the correct build command with the example project", requires_xcodebuild: true do
        log_path = File.expand_path("#{FastlaneCore::Helper.buildlog_path}/gym/ExampleProductName-Example.log")

        result = Gym::BuildCommandGenerator.generate
        expect(result).to eq([
                               "set -o pipefail &&",
                               "xcodebuild",
                               "-scheme Example",
                               "-project ./gym/examples/standard/Example.xcodeproj",
                               "-derivedDataPath /tmp/my/derived_data",
                               "-destination 'generic/platform=iOS'",
                               "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                               :archive,
                               "| tee #{log_path.shellescape}",
                               "| xcpretty"
                             ])
      end
    end

    describe "Result Bundle Example" do
      it "uses the correct build command with the example project", requires_xcodebuild: true do
        log_path = File.expand_path("#{FastlaneCore::Helper.buildlog_path}/gym/ExampleProductName-Example.log")

        options = { project: "./gym/examples/standard/Example.xcodeproj", result_bundle: true, scheme: 'Example' }
        Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

        result = Gym::BuildCommandGenerator.generate
        expect(result).to eq([
                               "set -o pipefail &&",
                               "xcodebuild",
                               "-scheme Example",
                               "-project ./gym/examples/standard/Example.xcodeproj",
                               "-destination 'generic/platform=iOS'",
                               "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                               "-resultBundlePath './ExampleProductName.result'",
                               :archive,
                               "| tee #{log_path.shellescape}",
                               "| xcpretty"
                             ])
      end
    end

    describe "Result Bundle Path Example" do
      it "uses the correct build command with the example project", requires_xcodebuild: true do
        log_path = File.expand_path("#{FastlaneCore::Helper.buildlog_path}/gym/ExampleProductName-Example.log")

        options = { project: "./gym/examples/standard/Example.xcodeproj", scheme: 'Example', result_bundle: true,
          result_bundle_path: "result_bundle" }
        Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

        result = Gym::BuildCommandGenerator.generate
        expect(result).to eq([
                               "set -o pipefail &&",
                               "xcodebuild",
                               "-scheme Example",
                               "-project ./gym/examples/standard/Example.xcodeproj",
                               "-destination 'generic/platform=iOS'",
                               "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                               "-resultBundlePath 'result_bundle'",
                               :archive,
                               "| tee #{log_path.shellescape}",
                               "| xcpretty"
                             ])
      end

      it "does not use result_bundle_path if result_bundle is false", requires_xcodebuild: true do
        log_path = File.expand_path("#{FastlaneCore::Helper.buildlog_path}/gym/ExampleProductName-Example.log")

        options = { project: "./gym/examples/standard/Example.xcodeproj", scheme: 'Example', result_bundle: false,
          result_bundle_path: "result_bundle" }
        Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

        result = Gym::BuildCommandGenerator.generate
        expect(result).to eq([
                               "set -o pipefail &&",
                               "xcodebuild",
                               "-scheme Example",
                               "-project ./gym/examples/standard/Example.xcodeproj",
                               "-destination 'generic/platform=iOS'",
                               "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                               :archive,
                               "| tee #{log_path.shellescape}",
                               "| xcpretty"
                             ])
      end
    end

    describe "Analyze Build Time Example" do
      before do
        @log_path = File.expand_path("#{FastlaneCore::Helper.buildlog_path}/gym/ExampleProductName-Example.log")
      end

      it "uses the correct build command with the example project when option is enabled", requires_xcodebuild: true do
        options = { project: "./gym/examples/standard/Example.xcodeproj", analyze_build_time: true, scheme: 'Example' }
        Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

        result = Gym::BuildCommandGenerator.generate
        expect(result).to eq([
                               "set -o pipefail &&",
                               "xcodebuild",
                               "-scheme Example",
                               "-project ./gym/examples/standard/Example.xcodeproj",
                               "-destination 'generic/platform=iOS'",
                               "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                               "OTHER_SWIFT_FLAGS=\"-Xfrontend -debug-time-function-bodies\"",
                               :archive,
                               "| tee #{@log_path.shellescape}",
                               "| xcpretty"
                             ])

        result = Gym::BuildCommandGenerator.post_build
        expect(result).to eq([
                               "grep -E '^[0-9.]+ms' #{@log_path.shellescape} | grep -vE '^0\.[0-9]' | sort -nr > culprits.txt"
                             ])
      end

      it "uses the correct build command with the example project when option is disabled", requires_xcodebuild: true do
        options = { project: "./gym/examples/standard/Example.xcodeproj", analyze_build_time: false, scheme: 'Example' }
        Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

        result = Gym::BuildCommandGenerator.generate
        expect(result).to eq([
                               "set -o pipefail &&",
                               "xcodebuild",
                               "-scheme Example",
                               "-project ./gym/examples/standard/Example.xcodeproj",
                               "-destination 'generic/platform=iOS'",
                               "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                               :archive,
                               "| tee #{@log_path.shellescape}",
                               "| xcpretty"
                             ])

        result = Gym::BuildCommandGenerator.post_build
        expect(result).to be_empty
      end
    end
  end
end
