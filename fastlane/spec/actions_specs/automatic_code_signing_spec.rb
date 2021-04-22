require "xcodeproj"
# 771D79501D9E69C900D840FA = demo
# 77C503031DD3175E00AC8FF0 = today
describe Fastlane do
  describe "Automatic Code Signing" do
    before do
      allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
    end

    around do |example|
      Dir.mktmpdir do |tmpdir|
        FileUtils.copy_entry('./fastlane/spec/fixtures/xcodeproj/automatic_code_signing.xcodeproj', tmpdir)
        @xcodeproj_path = tmpdir
        example.run
      end
    end

    it "enable_automatic_code_signing" do
      allow(UI).to receive(:success)
      expect(UI).to receive(:success).with("Successfully updated project settings to use Code Sign Style = 'Automatic'")
      result = Fastlane::FastFile.new.parse("lane :test do
        enable_automatic_code_signing(path: '#{@xcodeproj_path}', team_id: 'XXXX')
      end").runner.execute(:test)
      expect(result).to eq(true)

      project = Xcodeproj::Project.open(@xcodeproj_path)
      root_attrs = project.root_object.attributes["TargetAttributes"]
      expect(root_attrs["771D79501D9E69C900D840FA"]["ProvisioningStyle"]).to eq("Automatic")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["ProvisioningStyle"]).to eq("Automatic")

      expect(root_attrs["771D79501D9E69C900D840FA"]["DevelopmentTeam"]).to eq("XXXX")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["DevelopmentTeam"]).to eq("XXXX")

      project.targets.each do |target|
        target.build_configuration_list.get_setting("CODE_SIGN_STYLE").map do |build_config, value|
          expect(value).to eq("Automatic")
        end
      end
    end

    it "disable_automatic_code_signing for specific target" do
      # Given both targets enable Automatic code signing
      Fastlane::FastFile.new.parse("lane :test do
        enable_automatic_code_signing(path: '#{@xcodeproj_path}')
      end").runner.execute(:test)

      allow(UI).to receive(:success)
      expect(UI).to receive(:success).with("Successfully updated project settings to use Code Sign Style = 'Manual'")
      expect(UI).to receive(:success).with("\t * today")
      expect(UI).to receive(:deprecated).with("The `automatic_code_signing` action has been deprecated,")
      expect(UI).to receive(:deprecated).with("Please use `update_code_signing_settings` action instead.")
      expect(UI).to receive(:important).with("Skipping demo not selected (today)")
      result = Fastlane::FastFile.new.parse("lane :test do
        disable_automatic_code_signing(path: '#{@xcodeproj_path}', targets: ['today'])
      end").runner.execute(:test)
      expect(result).to eq(false)

      project = Xcodeproj::Project.open(@xcodeproj_path)
      root_attrs = project.root_object.attributes["TargetAttributes"]
      expect(root_attrs["771D79501D9E69C900D840FA"]["ProvisioningStyle"]).to eq("Automatic")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["ProvisioningStyle"]).to eq("Manual")

      project.targets.each do |target|
        target.build_configuration_list.get_setting("CODE_SIGN_STYLE").map do |build_config, value|
          expect(value).to eq(target.name == 'today' ? "Manual" : "Automatic")
        end
      end
    end

    it "disable_automatic_code_signing" do
      allow(UI).to receive(:success)
      expect(UI).to receive(:success).with("Successfully updated project settings to use Code Sign Style = 'Manual'")
      result = Fastlane::FastFile.new.parse("lane :test do
        disable_automatic_code_signing(path: '#{@xcodeproj_path}')
      end").runner.execute(:test)
      expect(result).to eq(false)

      project = Xcodeproj::Project.open(@xcodeproj_path)
      root_attrs = project.root_object.attributes["TargetAttributes"]
      expect(root_attrs["771D79501D9E69C900D840FA"]["ProvisioningStyle"]).to eq("Manual")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["ProvisioningStyle"]).to eq("Manual")

      project.targets.each do |target|
        target.build_configuration_list.get_setting("CODE_SIGN_STYLE").map do |build_config, value|
          expect(value).to eq("Manual")
        end
      end
    end

    it "sets team id" do
      # G3KGXDXQL9
      allow(UI).to receive(:success)
      expect(UI).to receive(:success).with("Successfully updated project settings to use Code Sign Style = 'Manual'")
      expect(UI).to receive(:deprecated).with("The `automatic_code_signing` action has been deprecated,")
      expect(UI).to receive(:deprecated).with("Please use `update_code_signing_settings` action instead.")
      expect(UI).to receive(:important).with("Set Team id to: G3KGXDXQL9 for target: demo")
      expect(UI).to receive(:important).with("Set Team id to: G3KGXDXQL9 for target: today")
      result = Fastlane::FastFile.new.parse("lane :test do
        disable_automatic_code_signing(path: '#{@xcodeproj_path}', team_id: 'G3KGXDXQL9')
      end").runner.execute(:test)
      expect(result).to eq(false)

      project = Xcodeproj::Project.open(@xcodeproj_path)
      root_attrs = project.root_object.attributes["TargetAttributes"]

      expect(root_attrs["771D79501D9E69C900D840FA"]["ProvisioningStyle"]).to eq("Manual")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["ProvisioningStyle"]).to eq("Manual")

      expect(root_attrs["771D79501D9E69C900D840FA"]["DevelopmentTeam"]).to eq("G3KGXDXQL9")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["DevelopmentTeam"]).to eq("G3KGXDXQL9")

      project.targets.each do |target|
        target.build_configuration_list.get_setting("CODE_SIGN_STYLE").map do |build_config, value|
          expect(value).to eq("Manual")
        end
      end
    end

    it "sets code sign identity" do
      # G3KGXDXQL9
      allow(UI).to receive(:success)
      expect(UI).to receive(:success).with("Successfully updated project settings to use Code Sign Style = 'Manual'")
      expect(UI).to receive(:deprecated).with("The `automatic_code_signing` action has been deprecated,")
      expect(UI).to receive(:deprecated).with("Please use `update_code_signing_settings` action instead.")
      expect(UI).to receive(:important).with("Set Team id to: G3KGXDXQL9 for target: demo")
      expect(UI).to receive(:important).with("Set Team id to: G3KGXDXQL9 for target: today")
      expect(UI).to receive(:important).with("Set Code Sign identity to: iPhone Distribution for target: demo")
      expect(UI).to receive(:important).with("Set Code Sign identity to: iPhone Distribution for target: today")
      result = Fastlane::FastFile.new.parse("lane :test do
        disable_automatic_code_signing(path: '#{@xcodeproj_path}', team_id: 'G3KGXDXQL9', code_sign_identity: 'iPhone Distribution')
      end").runner.execute(:test)
      expect(result).to eq(false)

      project = Xcodeproj::Project.open(@xcodeproj_path)
      root_attrs = project.root_object.attributes["TargetAttributes"]

      expect(root_attrs["771D79501D9E69C900D840FA"]["ProvisioningStyle"]).to eq("Manual")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["ProvisioningStyle"]).to eq("Manual")

      expect(root_attrs["771D79501D9E69C900D840FA"]["DevelopmentTeam"]).to eq("G3KGXDXQL9")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["DevelopmentTeam"]).to eq("G3KGXDXQL9")

      project.targets.each do |target|
        target.build_configuration_list.get_setting("CODE_SIGN_STYLE").map do |build_config, value|
          expect(value).to eq("Manual")
        end
        target.build_configuration_list.get_setting("CODE_SIGN_IDENTITY").map do |build_config, value|
          expect(value).to eq("iPhone Distribution")
        end
        next unless target.name == 'demo'
        target.build_configuration_list.get_setting("CODE_SIGN_IDENTITY[sdk=iphoneos*]").map do |build_config, value|
          expect(value).to eq("iPhone Distribution")
        end
      end
    end

    it "sets profile name" do
      # G3KGXDXQL9
      allow(UI).to receive(:success)
      expect(UI).to receive(:success).with("Successfully updated project settings to use Code Sign Style = 'Manual'")
      expect(UI).to receive(:deprecated).with("The `automatic_code_signing` action has been deprecated,")
      expect(UI).to receive(:deprecated).with("Please use `update_code_signing_settings` action instead.")
      expect(UI).to receive(:important).with("Set Team id to: G3KGXDXQL9 for target: demo")
      expect(UI).to receive(:important).with("Set Team id to: G3KGXDXQL9 for target: today")
      expect(UI).to receive(:important).with("Set Provisioning Profile name to: Mindera for target: demo")
      expect(UI).to receive(:important).with("Set Provisioning Profile name to: Mindera for target: today")
      result = Fastlane::FastFile.new.parse("lane :test do
        disable_automatic_code_signing(path: '#{@xcodeproj_path}', team_id: 'G3KGXDXQL9', profile_name: 'Mindera')
      end").runner.execute(:test)
      expect(result).to eq(false)

      project = Xcodeproj::Project.open(@xcodeproj_path)
      root_attrs = project.root_object.attributes["TargetAttributes"]

      expect(root_attrs["771D79501D9E69C900D840FA"]["ProvisioningStyle"]).to eq("Manual")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["ProvisioningStyle"]).to eq("Manual")

      expect(root_attrs["771D79501D9E69C900D840FA"]["DevelopmentTeam"]).to eq("G3KGXDXQL9")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["DevelopmentTeam"]).to eq("G3KGXDXQL9")

      project.targets.each do |target|
        target.build_configuration_list.get_setting("CODE_SIGN_STYLE").map do |build_config, value|
          expect(value).to eq("Manual")
        end
        target.build_configuration_list.get_setting("PROVISIONING_PROFILE_SPECIFIER").map do |build_config, value|
          expect(value).to eq("Mindera")
        end
      end
    end

    it "sets profile uuid" do
      # G3KGXDXQL9
      allow(UI).to receive(:success)
      expect(UI).to receive(:success).with("Successfully updated project settings to use Code Sign Style = 'Manual'")
      expect(UI).to receive(:deprecated).with("The `automatic_code_signing` action has been deprecated,")
      expect(UI).to receive(:deprecated).with("Please use `update_code_signing_settings` action instead.")
      expect(UI).to receive(:important).with("Set Team id to: G3KGXDXQL9 for target: demo")
      expect(UI).to receive(:important).with("Set Team id to: G3KGXDXQL9 for target: today")
      expect(UI).to receive(:important).with("Set Provisioning Profile UUID to: 1337 for target: demo")
      expect(UI).to receive(:important).with("Set Provisioning Profile UUID to: 1337 for target: today")
      result = Fastlane::FastFile.new.parse("lane :test do
        disable_automatic_code_signing(path: '#{@xcodeproj_path}', team_id: 'G3KGXDXQL9', profile_uuid: '1337')
      end").runner.execute(:test)
      expect(result).to eq(false)

      project = Xcodeproj::Project.open(@xcodeproj_path)
      root_attrs = project.root_object.attributes["TargetAttributes"]

      expect(root_attrs["771D79501D9E69C900D840FA"]["ProvisioningStyle"]).to eq("Manual")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["ProvisioningStyle"]).to eq("Manual")

      expect(root_attrs["771D79501D9E69C900D840FA"]["DevelopmentTeam"]).to eq("G3KGXDXQL9")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["DevelopmentTeam"]).to eq("G3KGXDXQL9")

      project.targets.each do |target|
        target.build_configuration_list.get_setting("CODE_SIGN_STYLE").map do |build_config, value|
          expect(value).to eq("Manual")
        end
        target.build_configuration_list.get_setting("PROVISIONING_PROFILE").map do |build_config, value|
          expect(value).to eq("1337")
        end
      end
    end

    it "sets bundle identifier" do
      # G3KGXDXQL9
      allow(UI).to receive(:success)
      expect(UI).to receive(:success).with("Successfully updated project settings to use Code Sign Style = 'Manual'")
      expect(UI).to receive(:deprecated).with("The `automatic_code_signing` action has been deprecated,")
      expect(UI).to receive(:deprecated).with("Please use `update_code_signing_settings` action instead.")
      expect(UI).to receive(:important).with("Set Team id to: G3KGXDXQL9 for target: demo")
      expect(UI).to receive(:important).with("Set Team id to: G3KGXDXQL9 for target: today")
      expect(UI).to receive(:important).with("Set Bundle identifier to: com.fastlane.mindera.cosigner for target: demo")
      expect(UI).to receive(:important).with("Set Bundle identifier to: com.fastlane.mindera.cosigner for target: today")
      result = Fastlane::FastFile.new.parse("lane :test do
        disable_automatic_code_signing(path: '#{@xcodeproj_path}', team_id: 'G3KGXDXQL9', bundle_identifier: 'com.fastlane.mindera.cosigner')
      end").runner.execute(:test)
      expect(result).to eq(false)

      project = Xcodeproj::Project.open(@xcodeproj_path)
      root_attrs = project.root_object.attributes["TargetAttributes"]

      expect(root_attrs["771D79501D9E69C900D840FA"]["ProvisioningStyle"]).to eq("Manual")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["ProvisioningStyle"]).to eq("Manual")

      expect(root_attrs["771D79501D9E69C900D840FA"]["DevelopmentTeam"]).to eq("G3KGXDXQL9")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["DevelopmentTeam"]).to eq("G3KGXDXQL9")

      project.targets.each do |target|
        target.build_configuration_list.get_setting("CODE_SIGN_STYLE").map do |build_config, value|
          expect(value).to eq("Manual")
        end
        target.build_configuration_list.get_setting("PRODUCT_BUNDLE_IDENTIFIER").map do |build_config, value|
          expect(value).to eq("com.fastlane.mindera.cosigner")
        end
      end
    end

    it "targets not found notice" do
      allow(UI).to receive(:important)
      expect(UI).to receive(:deprecated).with("The `automatic_code_signing` action has been deprecated,")
      expect(UI).to receive(:deprecated).with("Please use `update_code_signing_settings` action instead.")
      expect(UI).to receive(:important).with("None of the specified targets has been modified")
      result = Fastlane::FastFile.new.parse("lane :test do
        disable_automatic_code_signing(path: '#{@xcodeproj_path}', targets: ['not_found'])
      end").runner.execute(:test)
      expect(result).to eq(false)
    end

    it "raises exception on old projects" do
      expect(UI).to receive(:user_error!).with("Seems to be a very old project file format - please open your project file in a more recent version of Xcode")
      result = Fastlane::FastFile.new.parse("lane :test do
        disable_automatic_code_signing(path: './fastlane/spec/fixtures/xcodeproj/automatic-code-signing-old.xcodeproj')
      end").runner.execute(:test)
      expect(result).to eq(false)
    end
  end
end
