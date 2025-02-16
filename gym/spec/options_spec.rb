describe Gym do
  describe Gym::Options do
    it "raises an exception when project path wasn't found" do
      expect do
        options = { project: "./gym/examples/standard/Example.xcodeproj", workspace: "./gym/examples/cocoapods/Example.xcworkspace" }
        Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
      end.to raise_error("You can only pass either a 'project' or a 'workspace', not both")
    end

    it "removes the `ipa` from the output name if given", requires_xcodebuild: true do
      options = { output_name: "Example.ipa", project: "./gym/examples/standard/Example.xcodeproj" }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      expect(Gym.config[:output_name]).to eq("Example")
    end

    it "automatically chooses an existing scheme if the defined one is not available", requires_xcodebuild: true do
      options = { project: "./gym/examples/standard/Example.xcodeproj", scheme: "NotHere" }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      expect(Gym.config[:scheme]).to eq("Example")
    end

    it "replaces SEPARATOR (i.e. /) character with underscore(_) in output name", requires_xcodebuild: true do
      options = { output_name: "feature" + File::SEPARATOR + "Example.ipa", project: "./gym/examples/standard/Example.xcodeproj" }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      expect(Gym.config[:output_name]).to eq("feature_Example")
    end

    it "fallbacks to the 'Debug' configuration when skip build and archive are set", requires_xcodebuild: true do
      options = { project: "./gym/examples/multipleSchemes/Example.xcodeproj", skip_build_archive: true, skip_archive: true }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      configuration = Gym.config[:configuration]
      expect(configuration).to eq("Debug")
    end

    it "fallbacks to the 'Debug' configuration when skip archive is set", requires_xcodebuild: true do
      options = { project: "./gym/examples/multipleSchemes/Example.xcodeproj", skip_archive: true }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      configuration = Gym.config[:configuration]
      expect(configuration).to eq("Debug")
    end

    it "fallbacks to the 'Debug' configuration for development export method", requires_xcodebuild: true do
      options = { export_method: "development", project: "./gym/examples/multipleSchemes/Example.xcodeproj", skip_archive: false }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      configuration = Gym.config[:configuration]
      expect(configuration).to eq("Debug")
    end

    it "fallbacks to the Release configuration for ad-hoc export method", requires_xcodebuild: true do
      options = { export_method: "ad-hoc", project: "./gym/examples/multipleSchemes/Example.xcodeproj", skip_archive: false }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      configuration = Gym.config[:configuration]
      expect(configuration).to eq("Release")
    end

    it "fallbacks to the Release configuration for app-store export method", requires_xcodebuild: true do
      options = { export_method: "app-store", project: "./gym/examples/multipleSchemes/Example.xcodeproj", skip_archive: false }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      configuration = Gym.config[:configuration]
      expect(configuration).to eq("Release")
    end

    it "returns the specified configuration", requires_xcodebuild: true do
      options = { configuration: "Debug", project: "./gym/examples/multipleSchemes/Example.xcodeproj", skip_archive: false }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      configuration = Gym.config[:configuration]
      expect(configuration).to eq("Debug")
    end

    it "doesn't try to detect the export method when skip archive is set", requires_xcodebuild: true do
      options = { project: "./gym/examples/multipleSchemes/Example.xcodeproj", skip_archive: true }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      export_method = Gym.config[:export_method]
      expect(export_method).to be(nil)
    end

    it "fallbacks to the method in export options", requires_xcodebuild: true do
      options = { export_options: { method: "development" }, project: "./gym/examples/multipleSchemes/Example.xcodeproj", skip_archive: false }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      export_method = Gym.config[:export_method]
      expect(export_method).to eq(Gym::ExportMethod::DEVELOPMENT)
    end

    it "fallbacks to the default export method", requires_xcodebuild: true do
      options = { project: "./gym/examples/multipleSchemes/Example.xcodeproj", skip_archive: false }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      export_method = Gym.config[:export_method]
      expect(export_method).to eq(Gym::ExportMethod::APP_STORE)
    end

    it "returns the specified export method", requires_xcodebuild: true do
      options = { export_method: "ad-hoc", project: "./gym/examples/multipleSchemes/Example.xcodeproj", skip_archive: false }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      export_method = Gym.config[:export_method]
      expect(export_method).to eq(Gym::ExportMethod::AD_HOC)
    end
  end
end
