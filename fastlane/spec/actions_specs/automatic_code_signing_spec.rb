require "xcodeproj"
# 771D79501D9E69C900D840FA = demo
# 77C503031DD3175E00AC8FF0 = today
describe Fastlane do
  describe "Automatic Code Signing" do
    it "enable_automatic_code_signing" do
      allow(UI).to receive(:success)
      expect(UI).to receive(:success).with("Successfully updated project settings to use ProvisioningStyle 'Automatic'")
      result = Fastlane::FastFile.new.parse("lane :test do
        enable_automatic_code_signing(path: './fastlane/spec/fixtures/xcodeproj/automatic_code_signing.xcodeproj', team_id: 'XXXX')
      end").runner.execute(:test)
      expect(result).to eq(true)

      project = Xcodeproj::Project.open("./fastlane/spec/fixtures/xcodeproj/automatic_code_signing.xcodeproj")
      root_attrs = project.root_object.attributes["TargetAttributes"]
      expect(root_attrs["771D79501D9E69C900D840FA"]["ProvisioningStyle"]).to eq("Automatic")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["ProvisioningStyle"]).to eq("Automatic")

      expect(root_attrs["771D79501D9E69C900D840FA"]["DevelopmentTeam"]).to eq("XXXX")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["DevelopmentTeam"]).to eq("XXXX")
    end
    
    it "disable_automatic_code_signing for specific target" do
      allow(UI).to receive(:success)
      expect(UI).to receive(:success).with("Successfully updated project settings to use ProvisioningStyle 'Manual'")
      expect(UI).to receive(:success).with("\t * today")
      expect(UI).to receive(:important).with("Skipping demo not selected (today)")
      result = Fastlane::FastFile.new.parse("lane :test do
        disable_automatic_code_signing(path: './fastlane/spec/fixtures/xcodeproj/automatic_code_signing.xcodeproj', targets: ['today'])
      end").runner.execute(:test)
      expect(result).to eq(false)

      project = Xcodeproj::Project.open("./fastlane/spec/fixtures/xcodeproj/automatic_code_signing.xcodeproj")
      root_attrs = project.root_object.attributes["TargetAttributes"]
      expect(root_attrs["771D79501D9E69C900D840FA"]["ProvisioningStyle"]).to eq("Automatic")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["ProvisioningStyle"]).to eq("Manual")
    end
    
    it "disable_automatic_code_signing" do
      allow(UI).to receive(:success)
      expect(UI).to receive(:success).with("Successfully updated project settings to use ProvisioningStyle 'Manual'")
      result = Fastlane::FastFile.new.parse("lane :test do
        disable_automatic_code_signing(path: './fastlane/spec/fixtures/xcodeproj/automatic_code_signing.xcodeproj')
      end").runner.execute(:test)
      expect(result).to eq(false)

      project = Xcodeproj::Project.open("./fastlane/spec/fixtures/xcodeproj/automatic_code_signing.xcodeproj")
      root_attrs = project.root_object.attributes["TargetAttributes"]
      expect(root_attrs["771D79501D9E69C900D840FA"]["ProvisioningStyle"]).to eq("Manual")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["ProvisioningStyle"]).to eq("Manual")
    end
    
    it "sets team id" do
      # G3KGXDXQL9
      allow(UI).to receive(:success)
      expect(UI).to receive(:success).with("Successfully updated project settings to use ProvisioningStyle 'Manual'")
      expect(UI).to receive(:important).with("Set Team id to: G3KGXDXQL9 for target: demo")
      expect(UI).to receive(:important).with("Set Team id to: G3KGXDXQL9 for target: today")
      result = Fastlane::FastFile.new.parse("lane :test do
        disable_automatic_code_signing(path: './fastlane/spec/fixtures/xcodeproj/automatic_code_signing.xcodeproj', team_id: 'G3KGXDXQL9')
      end").runner.execute(:test)
      expect(result).to eq(false)

      project = Xcodeproj::Project.open("./fastlane/spec/fixtures/xcodeproj/automatic_code_signing.xcodeproj")
      root_attrs = project.root_object.attributes["TargetAttributes"]

      expect(root_attrs["771D79501D9E69C900D840FA"]["ProvisioningStyle"]).to eq("Manual")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["ProvisioningStyle"]).to eq("Manual")

      expect(root_attrs["771D79501D9E69C900D840FA"]["DevelopmentTeam"]).to eq("G3KGXDXQL9")
      expect(root_attrs["77C503031DD3175E00AC8FF0"]["DevelopmentTeam"]).to eq("G3KGXDXQL9")
    end
  end
end
