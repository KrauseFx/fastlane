describe Fastlane do
  describe Fastlane::FastFile do
    describe "set_changelog" do
      context 'with invalid platform' do
        let(:invalidPlatform_lane) { "lane :test do set_changelog(app_identifier: 'x.y.z', platform: 'whatever', changelog: 'custom changelog', username: 'name@example.com') end" }

        it 'raises a Fastlane error' do
          expect { Fastlane::FastFile.new.parse(invalidPlatform_lane).runner.execute(:test) }.to(
            raise_error(FastlaneCore::Interface::FastlaneError) do |error|
              expect(error.message).to match(/Invalid platform 'whatever', must be ios, appletvos, mac/)
            end
          )
        end
      end

      context 'with invalid app_identifier' do
        let(:validPlatform_lane) { "lane :test do set_changelog(app_identifier: 'x.y.z', platform: 'ios', changelog: 'custom changelog', username: 'name@example.com') end" }

        it 'blabla' do
          allow(Spaceship::Tunes).to receive(:login).and_return(true)
          allow(Spaceship::Tunes).to receive(:select_team).and_return(true)
          allow(Spaceship::Application).to receive(:find).and_return(nil)

          expect { Fastlane::FastFile.new.parse(validPlatform_lane).runner.execute(:test) }.to(
            raise_error(FastlaneCore::Interface::FastlaneError) do |error|
              expect(error.message).to match(/Couldn't find app with identifier x.y.z/)
            end
          )
        end
      end
    end
  end
end
