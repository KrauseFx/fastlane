describe Gym do
  before(:all) do
    options = { project: "./gym/examples/standard/Example.xcodeproj" }
    config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
    @project = FastlaneCore::Project.new(config)
  end
  before(:each) do
    allow(Gym).to receive(:project).and_return(@project)
  end

  describe Gym::PackageCommandGeneratorXcode7, requires_xcodebuild: true do
    it "passes xcargs through to xcode build wrapper " do
      options = {
        project: "./gym/examples/standard/Example.xcodeproj",
        xcargs: "-allowProvisioningUpdates"
      }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::PackageCommandGeneratorXcode7.generate
      expect(result).to eq([
                             "/usr/bin/xcrun #{Gym::PackageCommandGeneratorXcode7.wrap_xcodebuild.shellescape} -exportArchive",
                             "-exportOptionsPlist '#{Gym::PackageCommandGeneratorXcode7.config_path}'",
                             "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                             "-exportPath '#{Gym::PackageCommandGeneratorXcode7.temporary_output_path}'",
                             "-allowProvisioningUpdates",
                             ""
                           ])
    end

    it "works with the example project with no additional parameters" do
      options = { project: "./gym/examples/standard/Example.xcodeproj" }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::PackageCommandGeneratorXcode7.generate
      expect(result).to eq([
                             "/usr/bin/xcrun #{Gym::PackageCommandGeneratorXcode7.wrap_xcodebuild.shellescape} -exportArchive",
                             "-exportOptionsPlist '#{Gym::PackageCommandGeneratorXcode7.config_path}'",
                             "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                             "-exportPath '#{Gym::PackageCommandGeneratorXcode7.temporary_output_path}'",
                             ""
                           ])
    end

    it "works with the example project and additional parameters" do
      xcargs = { DEBUG: "1", BUNDLE_NAME: "Example App" }

      options = { project: "./gym/examples/standard/Example.xcodeproj", export_xcargs: xcargs }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::PackageCommandGeneratorXcode7.generate
      expect(result).to eq([
                             "/usr/bin/xcrun #{Gym::PackageCommandGeneratorXcode7.wrap_xcodebuild.shellescape} -exportArchive",
                             "-exportOptionsPlist '#{Gym::PackageCommandGeneratorXcode7.config_path}'",
                             "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                             "-exportPath '#{Gym::PackageCommandGeneratorXcode7.temporary_output_path}'",
                             "DEBUG=1 BUNDLE_NAME=Example\\ App",
                             ""
                           ])
    end

    it "works with spaces in path name" do
      options = { project: "./gym/examples/standard/Example.xcodeproj" }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      allow(Gym::PackageCommandGeneratorXcode7).to receive(:wrap_xcodebuild).and_return("/tmp/path with spaces")

      result = Gym::PackageCommandGeneratorXcode7.generate
      expect(result).to eq([
                             "/usr/bin/xcrun /tmp/path\\ with\\ spaces -exportArchive",
                             "-exportOptionsPlist '#{Gym::PackageCommandGeneratorXcode7.config_path}'",
                             "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                             "-exportPath '#{Gym::PackageCommandGeneratorXcode7.temporary_output_path}'",
                             ""
                           ])
    end

    it "supports passing a toolchain to use" do
      options = {
        project: "./gym/examples/standard/Example.xcodeproj",
        toolchain: "com.apple.dt.toolchain.Swift_2_3"
      }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::PackageCommandGeneratorXcode7.generate
      expect(result).to eq([
                             "/usr/bin/xcrun #{Gym::PackageCommandGeneratorXcode7.wrap_xcodebuild.shellescape} -exportArchive",
                             "-exportOptionsPlist '#{Gym::PackageCommandGeneratorXcode7.config_path}'",
                             "-archivePath #{Gym::BuildCommandGenerator.archive_path.shellescape}",
                             "-exportPath '#{Gym::PackageCommandGeneratorXcode7.temporary_output_path}'",
                             "-toolchain '#{options[:toolchain]}'",
                             ""
                           ])
    end

    it "generates a valid plist file we need" do
      options = { project: "./gym/examples/standard/Example.xcodeproj" }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::PackageCommandGeneratorXcode7.generate
      config_path = Gym::PackageCommandGeneratorXcode7.config_path

      expect(Plist.parse_xml(config_path)).to eq({
        'method' => 'app-store-connect'
      })
    end

    it "reads user export plist" do
      options = { project: "./gym/examples/standard/Example.xcodeproj", export_options: "./gym/examples/standard/ExampleExport.plist" }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::PackageCommandGeneratorXcode7.generate
      config_path = Gym::PackageCommandGeneratorXcode7.config_path

      expect(Plist.parse_xml(config_path)).to eq({
        'embedOnDemandResourcesAssetPacksInBundle' => true,
        'manifest' => {
          'appURL' => 'https://www.example.com/Example.ipa',
          'displayImageURL' => 'https://www.example.com/display.png',
          'fullSizeImageURL' => 'https://www.example.com/fullSize.png'
        },
        'method' => 'release-testing'
      })
      expect(Gym.config[:export_method]).to eq('release-testing')
      expect(Gym.config[:include_symbols]).to be_nil
      expect(Gym.config[:include_bitcode]).to be_nil
      expect(Gym.config[:export_team_id]).to be_nil
    end

    it "defaults to the correct export type if :export_options parameter is provided" do
      options = {
        project: "./gym/examples/standard/Example.xcodeproj",
        export_options: {
          include_symbols: true
        }
      }

      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::PackageCommandGeneratorXcode7.generate
      config_path = Gym::PackageCommandGeneratorXcode7.config_path

      content = Plist.parse_xml(config_path)
      expect(content["include_symbols"]).to eq(true)
      expect(content['method']).to eq('app-store-connect')
    end

    it "reads user export plist and override some parameters" do
      options = {
        project: "./gym/examples/standard/Example.xcodeproj",
        export_options: "./gym/examples/standard/ExampleExport.plist",
        export_method: "app-store-connect",
        include_symbols: false,
        include_bitcode: true,
        export_team_id: "1234567890"
      }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::PackageCommandGeneratorXcode7.generate
      config_path = Gym::PackageCommandGeneratorXcode7.config_path

      expect(Plist.parse_xml(config_path)).to eq({
        'embedOnDemandResourcesAssetPacksInBundle' => true,
        'manifest' => {
          'appURL' => 'https://www.example.com/Example.ipa',
          'displayImageURL' => 'https://www.example.com/display.png',
          'fullSizeImageURL' => 'https://www.example.com/fullSize.png'
        },
        'method' => 'app-store-connect',
        'uploadSymbols' => false,
        'uploadBitcode' => true,
        'teamID' => '1234567890'
      })
    end

    it "reads export options from hash" do
      options = {
        project: "./gym/examples/standard/Example.xcodeproj",
        export_options: {
          embedOnDemandResourcesAssetPacksInBundle: false,
          manifest: {
            appURL: "https://example.com/My App.ipa",
            displayImageURL: "https://www.example.com/display image.png",
            fullSizeImageURL: "https://www.example.com/fullSize image.png"
          },
          method: "enterprise",
          uploadSymbols: false,
          uploadBitcode: true,
          teamID: "1234567890"
        },
        export_method: "app-store-connect",
        include_symbols: true,
        include_bitcode: false,
        export_team_id: "ASDFGHJK"
      }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::PackageCommandGeneratorXcode7.generate
      config_path = Gym::PackageCommandGeneratorXcode7.config_path

      expect(Plist.parse_xml(config_path)).to eq({
        'embedOnDemandResourcesAssetPacksInBundle' => false,
        'manifest' => {
          'appURL' => 'https://example.com/My%20App.ipa',
          'displayImageURL' => 'https://www.example.com/display%20image.png',
          'fullSizeImageURL' => 'https://www.example.com/fullSize%20image.png'
        },
        'method' => 'app-store-connect',
        'uploadSymbols' => true,
        'uploadBitcode' => false,
        'teamID' => 'ASDFGHJK'
      })
    end

    it "doesn't store bitcode/symbols information for non app-store-connect builds" do
      options = { project: './gym/examples/standard/Example.xcodeproj', export_method: 'release-testing' }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::PackageCommandGeneratorXcode7.generate
      config_path = Gym::PackageCommandGeneratorXcode7.config_path

      expect(Plist.parse_xml(config_path)).to eq({
        'method' => 'release-testing'
      })
    end

    it "uses a temporary folder to store the resulting ipa file" do
      options = { project: "./gym/examples/standard/Example.xcodeproj" }
      Gym.config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)

      result = Gym::PackageCommandGeneratorXcode7.generate
      expect(Gym::PackageCommandGeneratorXcode7.temporary_output_path).to match(%r{#{Dir.tmpdir}/gym_output.+})
      expect(Gym::PackageCommandGeneratorXcode7.manifest_path).to match(%r{#{Dir.tmpdir}/gym_output.+/manifest.plist})
      expect(Gym::PackageCommandGeneratorXcode7.app_thinning_path).to match(%r{#{Dir.tmpdir}/gym_output.+/app-thinning.plist})
      expect(Gym::PackageCommandGeneratorXcode7.app_thinning_size_report_path).to match(%r{#{Dir.tmpdir}/gym_output.+/App Thinning Size Report.txt})
      expect(Gym::PackageCommandGeneratorXcode7.apps_path).to match(%r{#{Dir.tmpdir}/gym_output.+/Apps})
      expect(Gym::PackageCommandGeneratorXcode7.appstore_info_path).to match(%r{#{Dir.tmpdir}/gym_output.+/AppStoreInfo.plist})
    end
  end
end
