describe Gym do
  before(:all) do
    options = { project: "./gym/examples/multipleSchemes/Example.xcodeproj" }
    @config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
    @project = FastlaneCore::Project.new(@config)

    @output = %(
2015-12-15 13:00:57.177 xcodebuild[81544:4350404] [MT] IDEDistribution: -[IDEDistributionLogging _createLoggingBundleAtPath:]: Created bundle at path '/var/folders/88/l77k840955j0x55fkb3m6cdr0000gn/T/EventLink_2015-12-15_13-00-57.177.xcdistributionlogs'.
2015-12-15 13:00:57.318 xcodebuild[81544:4350404] [MT] IDEDistribution: Failed to generate distribution items with error: Error Domain=DVTMachOErrorDomain Code=0 "Found an unexpected Mach-O header code: 0x72613c21" UserInfo={NSLocalizedDescription=Found an unexpected Mach-O header code: 0x72613c21, NSLocalizedRecoverySuggestion=}
2015-12-15 13:00:57.318 xcodebuild[81544:4350404] [MT] IDEDistribution: Step failed: <IDEDistributionSigningAssetsStep: 0x7f9d94cb55a0>: Error Domain=DVTMachOErrorDomain Code=0 "Found an unexpected Mach-O header code: 0x72613c21" UserInfo={NSLocalizedDescription=Found an unexpected Mach-O header code: 0x72613c21, NSLocalizedRecoverySuggestion=}
%)
  end

  describe Gym::ErrorHandler, requires_xcodebuild: true do
    before(:each) { Gym.config = @config }

    def mock_gym_path(content)
      log_path = "log_path"
      expect(File).to receive(:exist?).with(log_path).and_return(true)
      allow(Gym::BuildCommandGenerator).to receive(:xcodebuild_log_path).and_return(log_path)
      expect(File).to receive(:read).with(log_path).and_return(content)
    end

    it "raises build error with error_info" do
      mock_gym_path(@output)
      expect(UI).to receive(:build_failure!).with("Error building the application - see the log above", error_info: @output)
      Gym::ErrorHandler.handle_build_error(@output)
    end

    it "raises package error with error_info" do
      mock_gym_path(@output)
      expect(UI).to receive(:build_failure!).with("Error packaging up the application", error_info: @output)
      Gym::ErrorHandler.handle_package_error(@output)
    end

    it "prints the last few lines of the raw output, as `xcpretty` doesn't render all error messages correctly" do
      code_signing_output = @output + %(
SetMode u+w,go-w,a+rX /Users/fkrause/Library/Developer/Xcode/DerivedData/Themoji-aanbocksacwzrydzjzjvnfrcqibb/Build/Intermediates.noindex/ArchiveIntermediates/Themoji/IntermediateBuildFilesPath/UninstalledProducts/iphoneos/Pods_Themoji.framework
    cd /Users/fkrause/Developer/hacking/themoji/Pods
    /bin/chmod -RH u+w,go-w,a+rX /Users/fkrause/Library/Developer/Xcode/DerivedData/Themoji-aanbocksacwzrydzjzjvnfrcqibb/Build/Intermediates.noindex/ArchiveIntermediates/Themoji/IntermediateBuildFilesPath/UninstalledProducts/iphoneos/Pods_Themoji.framework

=== BUILD TARGET Themoji OF PROJECT Themoji WITH CONFIGURATION Release ===

Check dependencies
No profile for team 'N8X438SEU2' matching 'match AppStore me.themoji.app.beta' found:  Xcode couldn't find any provisioning profiles matching 'N8X438SEU2/match AppStore me.themoji.app.beta'. Install the profile (by dragging and dropping it onto Xcode's dock item) or select a different one in the General tab of the target editor.
Code signing is required for product type 'Application' in SDK 'iOS 11.0'
)
      mock_gym_path(code_signing_output)
      expect(UI).to receive(:build_failure!).with("Error building the application - see the log above", error_info: code_signing_output)
      expect(UI).to receive(:command_output).with("No profile for team 'N8X438SEU2' matching 'match AppStore me.themoji.app.beta' found:  Xcode couldn't find any provisioning profiles matching 'N8X438SEU2/match AppStore me.themoji.app.beta'. " \
        "Install the profile (by dragging and dropping it onto Xcode's dock item) or select a different one in the General tab of the target editor.")
      expect(UI).to receive(:command_output).with("Code signing is required for product type 'Application' in SDK 'iOS 11.0'")
      expect(UI).to receive(:command_output).at_least(:once) # as this is called multiple times before

      Gym::ErrorHandler.handle_build_error(code_signing_output)
    end

    it "prints mismatch between the export_method and the selected profiles only once" do
      mock_gym_path(@output)
      expect(UI).to receive(:build_failure!).with("Error building the application - see the log above", error_info: @output)

      Gym.config[:export_method] = 'app-store-connect'
      Gym.config[:export_options][:provisioningProfiles] = {
        'com.sample.app' => 'In House Ad Hoc'
      }

      expect(UI).to receive(:error).with(/There seems to be a mismatch between/).once
      allow(UI).to receive(:error)

      Gym::ErrorHandler.handle_build_error(@output)
    end

    it "does not print mismatch if the export_method and the selected profiles matched" do
      mock_gym_path(@output)
      expect(UI).to receive(:build_failure!).with("Error building the application - see the log above", error_info: @output)

      Gym.config[:export_method] = 'enterprise'
      Gym.config[:export_options][:provisioningProfiles] = {
        'com.sample.app' => 'In House Ad Hoc' # `enterprise` take precedence over `ad-hoc`
      }

      expect(UI).to receive(:error).with(/There seems to be a mismatch between/).never
      allow(UI).to receive(:error)

      Gym::ErrorHandler.handle_build_error(@output)
    end
  end
end
