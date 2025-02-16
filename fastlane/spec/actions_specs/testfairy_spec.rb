describe Fastlane do
  describe Fastlane::FastFile do
    describe "TestFairy Integration" do
      it "raises an error if no parameters were given" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy()
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it "raises an error if no api key was given" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              ipa: './fastlane/spec/fixtures/fastfiles/Fastfile1',
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, /No API key/)
      end

      it "raises an error if no ipa, aab or apk path was given" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              api_key: 'thisistest',
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, /No ipa, aab or apk were given/)
      end

      it "raises an error if the given ipa path was not found" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              api_key: 'thisistest',
              ipa: './fastlane/nonexistent'
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "Couldn't find ipa file at path './fastlane/nonexistent'")
      end

      it "raises an error if the given aab path was not found" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              api_key: 'thisistest',
              aab: './fastlane/nonexistent'
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "Couldn't find aab file at path './fastlane/nonexistent'")
      end

      it "raises an error if the given apk path was not found" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              api_key: 'thisistest',
              apk: './fastlane/nonexistent'
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "Couldn't find apk file at path './fastlane/nonexistent'")
      end

      it "raises an error if unknown option given" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              api_key: 'thisistest',
              ipa_path: './fastlane/nonexistent'
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, /Could not find option 'ipa_path'/)
      end

      it "raises an error if conflicting ipa and aab parameters" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              api_key: 'thisistest',
              ipa: './fastlane/spec/fixtures/fastfiles/Fastfile1',
              aab: './fastlane/spec/fixtures/fastfiles/Fastfile1'
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "Unresolved conflict between options: 'ipa' and 'aab'")
      end

      it "raises an error if conflicting ipa and apk parameters" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              api_key: 'thisistest',
              ipa: './fastlane/spec/fixtures/fastfiles/Fastfile1',
              apk: './fastlane/spec/fixtures/fastfiles/Fastfile1'
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "Unresolved conflict between options: 'ipa' and 'apk'")
      end

      it "raises an error if conflicting aab and apk parameters" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              api_key: 'thisistest',
              aab: './fastlane/spec/fixtures/fastfiles/Fastfile1',
              apk: './fastlane/spec/fixtures/fastfiles/Fastfile1'
            })
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "Unresolved conflict between options: 'aab' and 'apk'")
      end

      it "works with valid required parameters with ipa" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              ipa: './fastlane/spec/fixtures/fastfiles/Fastfile1',
              api_key: 'thisistest',
            })
          end").runner.execute(:test)
        end.not_to(raise_error)
      end

      it "works with valid required parameters with aab" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              aab: './fastlane/spec/fixtures/fastfiles/Fastfile1',
              api_key: 'thisistest',
            })
          end").runner.execute(:test)
        end.not_to(raise_error)
      end

      it "works with valid required parameters with apk" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              apk: './fastlane/spec/fixtures/fastfiles/Fastfile1',
              api_key: 'thisistest',
            })
          end").runner.execute(:test)
        end.not_to(raise_error)
      end

      it "works with valid optional parameters" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            testfairy({
              ipa: './fastlane/spec/fixtures/fastfiles/Fastfile1',
              api_key: 'thisistest',
              upload_url: 'https://your-subdomain.testfairy.com',
              comment: 'Test Comment!',
              testers_groups: ['group1', 'group2'],
              custom: 'custom argument',
              tags: ['tag1', 'tag2', 'tag3']
            })
          end").runner.execute(:test)
        end.not_to(raise_error)
      end
    end
  end
end
