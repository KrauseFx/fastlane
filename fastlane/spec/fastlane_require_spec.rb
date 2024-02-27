require 'fastlane/fastlane_require'

describe Fastlane do
  describe Fastlane::FastlaneRequire do
    it "formats gem require name for fastlane-plugin" do
      gem_name = "fastlane-plugin-test"
      gem_require_name = Fastlane::FastlaneRequire.format_gem_require_name(gem_name)
      expect(gem_require_name).to eq("fastlane/plugin/test")
    end

    it "formats gem require name for non-fastlane-plugin" do
      gem_name = "some-lib"
      gem_require_name = Fastlane::FastlaneRequire.format_gem_require_name(gem_name)
      expect(gem_require_name).to eq("some-lib")
    end

    describe "checks if a gem is installed" do
      it "true on known installed gem" do
        gem_name = "fastlane"
        gem_installed = Fastlane::FastlaneRequire.gem_installed?(gem_name)
        expect(gem_installed).to be(true)
      end

      it "false on known missing gem" do
        gem_name = "foobar"
        gem_installed = Fastlane::FastlaneRequire.gem_installed?(gem_name)
        expect(gem_installed).to be(false)
      end

      it "true on known preinstalled gem" do
        gem_name = "yaml"
        gem_installed = Fastlane::FastlaneRequire.gem_installed?(gem_name)
        expect(gem_installed).to be(true)
      end
    end
  end
end
