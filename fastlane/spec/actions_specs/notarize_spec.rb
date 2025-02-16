describe Fastlane do
  describe Fastlane::FastFile do
    describe "notarize" do
      let(:success_submit_response) do
        {
         'status': 'Accepted',
         'id': '1111-2222-3333-4444'
        }.to_json
      end
      let(:invalid_submit_response) do
        {
         'status': 'Invalid',
         'statusSummary': 'Archive contains critical validation errors',
         'id': '1111-2222-3333-4444'
        }.to_json
      end

      it "file at :api_key_path must exist" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            notarize(
              api_key_path: '/tmp/file_does_not_exist'
            )
          end").runner.execute(:test)
        end.to raise_error("API Key not found at '/tmp/file_does_not_exist'")
      end

      it "forbids to provide both :username and :api_key" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            notarize(
              username: 'myusername@example.com',
              api_key: {'anykey' => 'anyvalue'}
            )
          end").runner.execute(:test)
        end.to raise_error("Unresolved conflict between options: 'username' and 'api_key'")
      end

      it "forbids to provide both :username and :keychain_profile" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            notarize(
              username: 'myusername@example.com',
              keychain_profile: 'keychain profile name'
            )
          end").runner.execute(:test)
        end.to raise_error("Unresolved conflict between options: 'username' and 'keychain_profile'")
      end

      it "forbids to provide both :api_key and :keychain_profile" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            notarize(
              api_key: {'anykey' => 'anyvalue'},
              keychain_profile: 'keychain profile name'
            )
          end").runner.execute(:test)
        end.to raise_error("Unresolved conflict between options: 'api_key' and 'keychain_profile'")
      end

      it "forbids to provide both :skip_stapling and :try_early_stapling" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            notarize(
              skip_stapling: true,
              try_early_stapling: true
            )
          end").runner.execute(:test)
        end.to raise_error("Unresolved conflict between options: 'skip_stapling' and 'try_early_stapling'")
      end

      context "with notary tool" do
        let(:package) { Tempfile.new('app.ipa.zip') }
        let(:bundle_id) { 'com.some.app' }

        context "with Apple ID" do
          let(:username) { 'myusername@example.com' }
          let(:asc_provider) { '123456789' }
          let(:app_specific_password) { 'secretpass' }

          it "successful" do
            stub_const('ENV', { "FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD" => app_specific_password })

            expect(Fastlane::Actions).to receive(:sh).with("xcrun notarytool submit #{package.path} --output-format json --wait --apple-id #{username} --password #{app_specific_password} --team-id #{asc_provider}", { error_callback: anything, log: false }).and_return(success_submit_response)

            expect(Fastlane::Actions).to receive(:sh).with("xcrun stapler staple #{package.path}", { log: false })

            result = Fastlane::FastFile.new.parse("lane :test do
              notarize(
                use_notarytool: true,
                package: '#{package.path}',
                bundle_id: '#{bundle_id}',
                username: '#{username}',
                asc_provider: '#{asc_provider}',
              )
            end").runner.execute(:test)
          end

          it "successful with skip_stapling" do
            stub_const('ENV', { "FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD" => app_specific_password })

            expect(Fastlane::Actions).to receive(:sh).with("xcrun notarytool submit #{package.path} --output-format json --wait --apple-id #{username} --password #{app_specific_password} --team-id #{asc_provider}", { error_callback: anything, log: false }).and_return(success_submit_response)

            expect(Fastlane::Actions).not_to receive(:sh).with("xcrun stapler staple #{package.path}", { log: false })

            result = Fastlane::FastFile.new.parse("lane :test do
              notarize(
                use_notarytool: true,
                package: '#{package.path}',
                bundle_id: '#{bundle_id}',
                username: '#{username}',
                asc_provider: '#{asc_provider}',
                skip_stapling: true
              )
            end").runner.execute(:test)
          end

          it "invalid" do
            stub_const('ENV', { "FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD" => app_specific_password })

            expect(Fastlane::Actions).to receive(:sh).with("xcrun notarytool submit #{package.path} --output-format json --wait --apple-id #{username} --password #{app_specific_password} --team-id #{asc_provider}", { error_callback: anything, log: false }).and_return(invalid_submit_response)

            expect do
              result = Fastlane::FastFile.new.parse("lane :test do
                notarize(
                  use_notarytool: true,
                  package: '#{package.path}',
                  bundle_id: '#{bundle_id}',
                  username: '#{username}',
                  asc_provider: '#{asc_provider}',
                )
              end").runner.execute(:test)
            end.to raise_error(FastlaneCore::Interface::FastlaneError, "Could not notarize package. To see the error, please set 'print_log' to true.")
          end
        end

        context "with :keychain_profile" do
          let(:keychain_profile) { 'Keychain profile name' }
          let(:keychain_path) { '~/Library/My Keychains/name' }

          it "successful with specified :keychain" do
            expect(Fastlane::Actions).to receive(:sh).with("xcrun notarytool submit #{package.path} --output-format json --wait --keychain-profile #{keychain_profile.shellescape} --keychain #{keychain_path.shellescape}", { error_callback: anything, log: false }).and_return(success_submit_response)

            expect(Fastlane::Actions).to receive(:sh).with("xcrun stapler staple #{package.path}", { log: false })

            Fastlane::FastFile.new.parse("lane :test do
              notarize(
                use_notarytool: true,
                package: '#{package.path}',
                bundle_id: '#{bundle_id}',
                keychain: '#{keychain_path}',
                keychain_profile: '#{keychain_profile}'
              )
            end").runner.execute(:test)
          end

          it "successful w/o specified :keychain" do
            expect(Fastlane::Actions).to receive(:sh).with("xcrun notarytool submit #{package.path} --output-format json --wait --keychain-profile #{keychain_profile.shellescape}", { error_callback: anything, log: false }).and_return(success_submit_response)

            expect(Fastlane::Actions).to receive(:sh).with("xcrun stapler staple #{package.path}", { log: false })

            Fastlane::FastFile.new.parse("lane :test do
              notarize(
                use_notarytool: true,
                package: '#{package.path}',
                bundle_id: '#{bundle_id}',
                keychain_profile: '#{keychain_profile}'
              )
            end").runner.execute(:test)
          end

          it "uses :keychain_profile even if there is API key in a lane context" do
            allow(Spaceship::ConnectAPI::Token).to receive(:from).and_return('token')

            expect(Fastlane::Actions).to receive(:sh).with("xcrun notarytool submit #{package.path} --output-format json --wait --keychain-profile #{keychain_profile.shellescape}", { error_callback: anything, log: false }).and_return(success_submit_response)

            expect(Fastlane::Actions).to receive(:sh).with("xcrun stapler staple #{package.path}", { log: false })

            Fastlane::FastFile.new.parse("lane :test do
              notarize(
                use_notarytool: true,
                package: '#{package.path}',
                bundle_id: '#{bundle_id}',
                keychain_profile: '#{keychain_profile}'
              )
            end").runner.execute(:test)
          end
        end

      end
    end
  end
end
