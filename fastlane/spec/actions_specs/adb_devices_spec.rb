describe Fastlane do
  describe Fastlane::FastFile do
    describe "adb_devices" do
      it "generates an empty list of devices" do
        result = Fastlane::FastFile.new.parse("lane :test do
          adb_devices(adb_path: '/some/path/to/adb')
        end").runner.execute(:test)

        expect(result).to match_array([])
      end

      it "generates an empty list of devices when ANDROID_SDK_ROOT is set" do
        FastlaneSpec::Env.with_env_values(ANDROID_SDK_ROOT: '/usr/local/android-sdk') do
          result = Fastlane::FastFile.new.parse("lane :test do
            adb_devices()
          end").runner.execute(:test)
          expect(result).to match_array([])
        end
      end
    end
  end
end
