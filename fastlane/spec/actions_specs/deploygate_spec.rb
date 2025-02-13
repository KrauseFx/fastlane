describe Fastlane do
  describe Fastlane::FastFile do
    describe "DeployGate Integration" do
      it "raises an error if no parameters were given" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            deploygate()
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, /No API Token for DeployGate given/)
      end

      it "raises an error if no api token was given" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            deploygate({
              ipa: './fastlane/spec/fixtures/fastfiles/Fastfile1',
              user: 'deploygate',
            })
          end").runner.execute(:test)
        end.to raise_error("No API Token for DeployGate given, pass using `api_token: 'token'`")
      end

      it "raises an error if no target user was given" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            deploygate({
              ipa: './fastlane/spec/fixtures/fastfiles/Fastfile1',
              api_token: 'thisistest'
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, /No User for DeployGate given/)
      end

      it "raises an error if no binary path was given" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            deploygate({
              api_token: 'thisistest',
              user: 'deploygate'
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'missing `ipa`, `apk` and `aab`. deploygate action needs least one.')
      end

      it "raises an error if the given ipa path was not found" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            deploygate({
              api_token: 'thisistest',
              user: 'deploygate',
              ipa: './fastlane/nonexistent'
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "Couldn't find ipa file at path './fastlane/nonexistent'")
      end

      it "raises an error if the given apk path was not found" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            deploygate({
              api_token: 'testistest',
              user: 'deploygate',
              apk: './fastlane/nonexistent'
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "Couldn't find apk file at path './fastlane/nonexistent'")
      end

      it "raises an error if the given aab path was not found" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            deploygate({
              api_token: 'testistest',
              user: 'deploygate',
              aab: './fastlane/nonexistent'
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "Couldn't find aab file at path './fastlane/nonexistent'")
      end

      it "works with valid parameters" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            deploygate({
              ipa: './fastlane/spec/fixtures/fastfiles/Fastfile1',
              user: 'deploygate',
              api_token: 'thisistest',
            })
          end").runner.execute(:test)
        end.not_to(raise_error)
      end

      it "works with valid parameters include optionals" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            deploygate({
              ipa: './fastlane/spec/fixtures/fastfiles/Fastfile1',
              user: 'deploygate',
              api_token: 'thisistest',
              release_note: 'This is a test release.',
              disable_notify: true,
              distribution_name: 'test_name',
            })
          end").runner.execute(:test)
        end.not_to(raise_error)
      end
    end
  end
end
