describe Fastlane do
  describe Fastlane::FastFile do
    describe "Get Version Number Integration" do
      require 'shellwords'

      xcodeproj_dir = File.absolute_path("./fastlane/spec/fixtures/actions/get_version_number/")
      xcodeproj_filename = "get_version_number.xcodeproj"

      it "gets the correct version number for 'TargetA'", requires_xcodeproj: true do
        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetA')
        end").runner.execute(:test)
        expect(result).to eq("4.3.2")
      end

      it "gets the correct version number for 'TargetA' using xcodeproj_filename with extension", requires_xcodeproj: true do
        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{File.join(xcodeproj_dir, xcodeproj_filename)}', target: 'TargetA')
        end").runner.execute(:test)
        expect(result).to eq("4.3.2")
      end

      context "Target Settings" do
        it "gets the correct version number for AggTarget without INFO_PLIST build option", requires_xcodeproj: true do
          result = Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: '#{File.join(xcodeproj_dir, xcodeproj_filename)}', target: 'AggTarget')
          end").runner.execute(:test)
          expect(result).to eq("7.6.6")
        end

        it "gets the correct version number for 'TargetVariableParentheses'", requires_xcodeproj: true do
          result = Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetVariableParentheses')
          end").runner.execute(:test)
          expect(result).to eq("4.3.2")
        end

        it "gets the correct version number for 'TargetVariableCurlyBraces'", requires_xcodeproj: true do
          result = Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetVariableCurlyBraces')
          end").runner.execute(:test)
          expect(result).to eq("4.3.2")
        end
      end

      context "Project Settings" do
        it "gets the correct version number for 'TargetVariableParenthesesBuildSettings'", requires_xcodeproj: true do
          result = Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetVariableParenthesesBuildSettings')
          end").runner.execute(:test)
          expect(result).to eq("7.6.5")
        end

        it "gets the correct version number for 'TargetVariableCurlyBracesBuildSettings'", requires_xcodeproj: true do
          result = Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetVariableCurlyBracesBuildSettings')
          end").runner.execute(:test)
          expect(result).to eq("7.6.5")
        end
      end

      context "xcconfig defined version" do
        it "gets the correct version number for 'TargetConfigVersion'", requires_xcodeproj: true do
          result = Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetConfigVersion')
          end").runner.execute(:test)
          expect(result).to eq("4.2.1")
        end
      end

      it "gets the correct version number for 'TargetATests'", requires_xcodeproj: true do
        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetATests')
        end").runner.execute(:test)
        expect(result).to eq("4.3.2")
      end

      it "gets the correct version number for 'TargetB'", requires_xcodeproj: true do
        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetB')
        end").runner.execute(:test)
        expect(result).to eq("5.4.3")
      end

      it "gets the correct version number for 'TargetBTests'", requires_xcodeproj: true do
        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetBTests')
        end").runner.execute(:test)
        expect(result).to eq("5.4.3")
      end

      it "gets the correct version number for 'TargetC_internal'", requires_xcodeproj: true do
        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetC_internal')
        end").runner.execute(:test)
        expect(result).to eq("7.5.2")
      end

      it "gets the correct version number for 'TargetC_production'", requires_xcodeproj: true do
        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetC_production')
        end").runner.execute(:test)
        expect(result).to eq("6.4.9")
      end

      it "gets the correct version number for 'SampleProject_tests'", requires_xcodeproj: true do
        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'SampleProject_tests')
        end").runner.execute(:test)
        expect(result).to eq("1.0")
      end

      it "gets the correct version number with no target specified (and one target that isn't test)", requires_xcodeproj: true do
        allow_any_instance_of(Xcodeproj::Project).to receive(:targets).and_wrap_original do |m, *args|
          targets = m.call(*args)
          targets.select do |target|
            target.name == "TargetA"
          end
        end

        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}')
        end").runner.execute(:test)
        expect(result).to eq("4.3.2")
      end

      it "gets the correct version number with no target specified (and one target that isn't test and multiple test targets)", requires_xcodeproj: true do
        allow_any_instance_of(Xcodeproj::Project).to receive(:targets).and_wrap_original do |m, *args|
          targets = m.call(*args)
          targets.select do |target|
            target.name == "TargetATests" || target.name == "TargetB" || target.name == "TargetBTests"
          end
        end

        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}')
        end").runner.execute(:test)
        expect(result).to eq("5.4.3")
      end

      it "gets the correct version with $(SRCROOT)", requires_xcodeproj: true do
        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetSRC')
        end").runner.execute(:test)
        expect(result).to eq("1.5.9")
      end

      it "gets the correct version when info-plist is relative path", requires_xcodeproj: true do
        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetRelativePath')
        end").runner.execute(:test)
        expect(result).to eq("3.37.0")
      end

      it "gets the correct version when info-plist is absolute path", requires_xcodeproj: true do
        begin
          # given
          # copy TargetAbsolutePath-Info.plist to /tmp/fastlane_get_version_number_action_spec/
          info_plist = File.absolute_path("./fastlane/spec/fixtures/actions/get_version_number/TargetAbsolutePath-Info.plist")
          temp_folder_for_test = "/tmp/fastlane_get_version_number_action_spec/"
          FileUtils.mkdir_p(temp_folder_for_test)
          FileUtils.cp_r(info_plist, temp_folder_for_test)
          temp_info_plist = File.path(temp_folder_for_test + "TargetAbsolutePath-Info.plist")
          expect(File.file?(temp_info_plist)).not_to(be false)

          # when
          result = Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetAbsolutePath')
          end").runner.execute(:test)

          # then
          expect(result).to eq("3.37.4")
        ensure
          # after
          # remove /tmp/fastlane_get_version_number_action_spec/
          FileUtils.rm_r(temp_folder_for_test)
          expect(File.file?(temp_info_plist)).to be false
        end
      end

      it "raises if one target and specified wrong target name", requires_xcodeproj: true do
        allow_any_instance_of(Xcodeproj::Project).to receive(:targets).and_wrap_original do |m, *args|
          [m.call(*args).first]
        end

        expect do
          result = Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'ThisIsNotATarget')
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "Cannot find target named 'ThisIsNotATarget'")
      end

      it "raises if in non-interactive mode with no target", requires_xcodeproj: true do
        expect do
          result = Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: '#{xcodeproj_dir}')
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneCrash, /non-interactive mode/)
      end

      it "raises if in non-interactive mode if cannot infer configuration", requires_xcodeproj: true do
        expect do
          result = Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetDifferentConfigurations')
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneCrash, /non-interactive mode/)
      end

      it "gets correct version for different configurations", requires_xcodeproj: true do
        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetDifferentConfigurations', configuration: 'Debug')
        end").runner.execute(:test)
        expect(result).to eq("1.2.3")

        result = Fastlane::FastFile.new.parse("lane :test do
          get_version_number(xcodeproj: '#{xcodeproj_dir}', target: 'TargetDifferentConfigurations', configuration: 'Release')
        end").runner.execute(:test)
        expect(result).to eq("3.2.1")
      end

      it "raises an exception when user passes workspace as the xcodeproj" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: 'project.xcworkspace')
          end").runner.execute(:test)
        end.to raise_error("Please pass the path to the project or its containing directory, not the workspace path")
      end

      it "raises an exception when user passes nonexistent directory" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: '/path/to/random/directory')
          end").runner.execute(:test)
        end.to raise_error(/Could not find file or directory at path/)
      end

      it "raises an exception when user passes existent directory with no Xcode project inside" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            get_version_number(xcodeproj: '#{File.dirname(xcodeproj_dir)}')
          end").runner.execute(:test)
        end.to raise_error(/Could not find Xcode project in directory at path/)
      end
    end
  end
end
