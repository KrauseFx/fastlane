describe Match do
  describe Match::Runner do
    let(:keychain) { 'login.keychain' }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('MATCH_KEYCHAIN_NAME').and_return(keychain)
      allow(ENV).to receive(:[]).with('MATCH_KEYCHAIN_PASSWORD').and_return(nil)

      # There is another test
      ENV.delete('FASTLANE_TEAM_ID')
      ENV.delete('FASTLANE_TEAM_NAME')
    end

    ["10", "11"].each do |xcode_version|
      context "Xcode #{xcode_version}" do
        let(:generate_apple_certs) { xcode_version == "11" }
        before do
          allow(FastlaneCore::Helper).to receive(:mac?).and_return(true)
          allow(FastlaneCore::Helper).to receive(:xcode_version).and_return(xcode_version)

          stub_const('ENV', { "MATCH_PASSWORD" => '2"QAHg@v(Qp{=*n^' })
        end

        it "creates a new profile and certificate if it doesn't exist yet", requires_security: true do
          git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
          values = {
            app_identifier: "tools.fastlane.app",
            type: "appstore",
            git_url: git_url,
            shallow_clone: true,
            username: "flapple@something.com"
          }

          config = FastlaneCore::Configuration.create(Match::Options.available_options, values)
          repo_dir = Dir.mktmpdir
          cert_path = File.join(repo_dir, "something.cer")
          profile_path = "./match/spec/fixtures/test.mobileprovision"
          keychain_path = FastlaneCore::Helper.keychain_path("login.keychain") # can be .keychain or .keychain-db
          destination = File.expand_path("~/Library/MobileDevice/Provisioning Profiles/98264c6b-5151-4349-8d0f-66691e48ae35.mobileprovision")

          fake_storage = "fake_storage"
          expect(Match::Storage::GitStorage).to receive(:configure).with(
            git_url: git_url,
            shallow_clone: true,
            skip_docs: false,
            git_branch: "master",
            git_full_name: nil,
            git_user_email: nil,
            clone_branch_directly: false,
            git_basic_authorization: nil,
            git_bearer_authorization: nil,
            git_private_key: nil,
            type: config[:type],
            generate_apple_certs: generate_apple_certs,
            platform: config[:platform],
            google_cloud_bucket_name: "",
            google_cloud_keys_file: "",
            google_cloud_project_id: "",
            s3_region: nil,
            s3_access_key: nil,
            s3_secret_access_key: nil,
            s3_bucket: nil,
            s3_object_prefix: nil,
            readonly: false,
            username: values[:username],
            team_id: nil,
            team_name: nil,
            api_key_path: nil,
            api_key: nil,
            identifiers: [values[:app_identifier]]
          ).and_return(fake_storage)

          expect(fake_storage).to receive(:download).and_return(nil)
          expect(fake_storage).to receive(:clear_changes).and_return(nil)
          allow(fake_storage).to receive(:working_directory).and_return(repo_dir)
          allow(fake_storage).to receive(:prefixed_working_directory).and_return(repo_dir)
          expect(Match::Generator).to receive(:generate_certificate).with(config, :distribution, fake_storage.working_directory, specific_cert_type: nil).and_return(cert_path)
          expect(Match::Generator).to receive(:generate_provisioning_profile).with(params: config,
                                                                                prov_type: :appstore,
                                                                           certificate_id: "something",
                                                                           app_identifier: values[:app_identifier],
                                                                                    force: false,
                                                                       working_directory: fake_storage.working_directory).and_return(profile_path)
          expect(FastlaneCore::ProvisioningProfile).to receive(:install).with(profile_path, keychain_path).and_return(destination)
          expect(fake_storage).to receive(:save_changes!).with(
            files_to_commit: [
              File.join(repo_dir, "something.cer"),
              File.join(repo_dir, "something.p12"), # this is important, as a cert consists out of 2 files
              "./match/spec/fixtures/test.mobileprovision"
            ]
          )

          spaceship = "spaceship"
          allow(spaceship).to receive(:team_id).and_return("")
          expect(Match::SpaceshipEnsure).to receive(:new).and_return(spaceship)
          expect(spaceship).to receive(:certificates_exists).and_return(true)
          expect(spaceship).to receive(:profile_exists).and_return(true)
          expect(spaceship).to receive(:bundle_identifier_exists).and_return(true)

          Match::Runner.new.run(config)

          expect(ENV[Match::Utils.environment_variable_name(app_identifier: "tools.fastlane.app",
                                                            type: "appstore")]).to eql('98264c6b-5151-4349-8d0f-66691e48ae35')
          expect(ENV[Match::Utils.environment_variable_name_team_id(app_identifier: "tools.fastlane.app",
                                                                    type: "appstore")]).to eql('439BBM9367')
          expect(ENV[Match::Utils.environment_variable_name_profile_name(app_identifier: "tools.fastlane.app",
                                                                         type: "appstore")]).to eql('tools.fastlane.app AppStore')
          profile_path = File.expand_path('~/Library/MobileDevice/Provisioning Profiles/98264c6b-5151-4349-8d0f-66691e48ae35.mobileprovision')
          expect(ENV[Match::Utils.environment_variable_name_profile_path(app_identifier: "tools.fastlane.app",
                                                                         type: "appstore")]).to eql(profile_path)
        end

        it "uses existing certificates and profiles if they exist", requires_security: true do
          git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
          values = {
            app_identifier: "tools.fastlane.app",
            type: "appstore",
            git_url: git_url,
            username: "flapple@something.com"
          }

          config = FastlaneCore::Configuration.create(Match::Options.available_options, values)
          repo_dir = "./match/spec/fixtures/existing"
          cert_path = "./match/spec/fixtures/existing/certs/distribution/E7P4EE896K.cer"
          key_path = "./match/spec/fixtures/existing/certs/distribution/E7P4EE896K.p12"

          fake_storage = "fake_storage"
          expect(Match::Storage::GitStorage).to receive(:configure).with(
            git_url: git_url,
            shallow_clone: false,
            skip_docs: false,
            git_branch: "master",
            git_full_name: nil,
            git_user_email: nil,
            clone_branch_directly: false,
            git_basic_authorization: nil,
            git_bearer_authorization: nil,
            git_private_key: nil,
            type: config[:type],
            generate_apple_certs: generate_apple_certs,
            platform: config[:platform],
            google_cloud_bucket_name: "",
            google_cloud_keys_file: "",
            google_cloud_project_id: "",
            s3_region: nil,
            s3_access_key: nil,
            s3_secret_access_key: nil,
            s3_bucket: nil,
            s3_object_prefix: nil,
            readonly: false,
            username: values[:username],
            team_id: nil,
            team_name: nil,
            api_key_path: nil,
            api_key: nil,
            identifiers: [values[:app_identifier]]
          ).and_return(fake_storage)

          expect(fake_storage).to receive(:download).and_return(nil)
          expect(fake_storage).to receive(:clear_changes).and_return(nil)
          allow(fake_storage).to receive(:git_url).and_return(git_url)
          allow(fake_storage).to receive(:working_directory).and_return(repo_dir)
          allow(fake_storage).to receive(:prefixed_working_directory).and_return(repo_dir)

          fake_encryption = "fake_encryption"
          expect(Match::Encryption::OpenSSL).to receive(:new).with(keychain_name: fake_storage.git_url, working_directory: fake_storage.working_directory).and_return(fake_encryption)
          expect(fake_encryption).to receive(:decrypt_files).and_return(nil)

          expect(Match::Utils).to receive(:import).with(key_path, keychain, password: nil).and_return(nil)
          expect(fake_storage).to_not(receive(:save_changes!))

          # To also install the certificate, fake that
          expect(FastlaneCore::CertChecker).to receive(:installed?).with(cert_path, in_keychain: nil).and_return(false)
          expect(Match::Utils).to receive(:import).with(cert_path, keychain, password: nil).and_return(nil)

          spaceship = "spaceship"
          allow(spaceship).to receive(:team_id).and_return("")
          expect(Match::SpaceshipEnsure).to receive(:new).and_return(spaceship)
          expect(spaceship).to receive(:certificates_exists).and_return(true)
          expect(spaceship).to receive(:profile_exists).and_return(true)
          expect(spaceship).to receive(:bundle_identifier_exists).and_return(true)

          allow(Match::Utils).to receive(:is_cert_valid?).and_return(true)

          Match::Runner.new.run(config)

          expect(ENV[Match::Utils.environment_variable_name(app_identifier: "tools.fastlane.app",
                                                            type: "appstore")]).to eql('736590c3-dfe8-4c25-b2eb-2404b8e65fb8')
          expect(ENV[Match::Utils.environment_variable_name_team_id(app_identifier: "tools.fastlane.app",
                                                                    type: "appstore")]).to eql('439BBM9367')
          expect(ENV[Match::Utils.environment_variable_name_profile_name(app_identifier: "tools.fastlane.app",
                                                                         type: "appstore")]).to eql('match AppStore tools.fastlane.app 1449198835')
          profile_path = File.expand_path('~/Library/MobileDevice/Provisioning Profiles/736590c3-dfe8-4c25-b2eb-2404b8e65fb8.mobileprovision')
          expect(ENV[Match::Utils.environment_variable_name_profile_path(app_identifier: "tools.fastlane.app",
                                                                         type: "appstore")]).to eql(profile_path)
        end

        it "fails because of an outdated certificate", requires_security: true do
          git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
          values = {
            app_identifier: "tools.fastlane.app",
            type: "appstore",
            git_url: git_url,
            username: "flapple@something.com"
          }

          config = FastlaneCore::Configuration.create(Match::Options.available_options, values)
          repo_dir = "./match/spec/fixtures/existing"
          cert_path = "./match/spec/fixtures/existing/certs/distribution/E7P4EE896K.cer"
          key_path = "./match/spec/fixtures/existing/certs/distribution/E7P4EE896K.p12"

          fake_storage = "fake_storage"
          expect(Match::Storage::GitStorage).to receive(:configure).with(
            git_url: git_url,
            shallow_clone: false,
            skip_docs: false,
            git_branch: "master",
            git_full_name: nil,
            git_user_email: nil,
            clone_branch_directly: false,
            git_basic_authorization: nil,
            git_bearer_authorization: nil,
            git_private_key: nil,
            type: config[:type],
            generate_apple_certs: generate_apple_certs,
            platform: config[:platform],
            google_cloud_bucket_name: "",
            google_cloud_keys_file: "",
            google_cloud_project_id: "",
            s3_region: nil,
            s3_access_key: nil,
            s3_secret_access_key: nil,
            s3_bucket: nil,
            s3_object_prefix: nil,
            readonly: false,
            username: values[:username],
            team_id: nil,
            team_name: nil,
            api_key_path: nil,
            api_key: nil,
            identifiers: [values[:app_identifier]]
          ).and_return(fake_storage)

          expect(fake_storage).to receive(:download).and_return(nil)
          expect(fake_storage).to receive(:clear_changes).and_return(nil)
          allow(fake_storage).to receive(:git_url).and_return(git_url)
          allow(fake_storage).to receive(:working_directory).and_return(repo_dir)
          allow(fake_storage).to receive(:prefixed_working_directory).and_return(repo_dir)

          fake_encryption = "fake_encryption"
          expect(Match::Encryption::OpenSSL).to receive(:new).with(keychain_name: fake_storage.git_url, working_directory: fake_storage.working_directory).and_return(fake_encryption)
          expect(fake_encryption).to receive(:decrypt_files).and_return(nil)

          spaceship = "spaceship"
          allow(spaceship).to receive(:team_id).and_return("")
          expect(Match::SpaceshipEnsure).to receive(:new).and_return(spaceship)
          expect(spaceship).to receive(:bundle_identifier_exists).and_return(true)

          expect(Match::Utils).to receive(:is_cert_valid?).and_return(false)

          expect do
            Match::Runner.new.run(config)
          end.to raise_error("Your certificate 'E7P4EE896K.cer' is not valid, please check end date and renew it if necessary")
        end

        it "skips provisioning profiles when skip_provisioning_profiles set to true", requires_security: true do
          git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
          values = {
            app_identifier: "tools.fastlane.app",
            type: "appstore",
            git_url: git_url,
            shallow_clone: true,
            username: "flapple@something.com",
            skip_provisioning_profiles: true
          }

          config = FastlaneCore::Configuration.create(Match::Options.available_options, values)
          repo_dir = Dir.mktmpdir
          cert_path = File.join(repo_dir, "something.cer")
          keychain_path = FastlaneCore::Helper.keychain_path("login.keychain") # can be .keychain or .keychain-db
          destination = File.expand_path("~/Library/MobileDevice/Provisioning Profiles/98264c6b-5151-4349-8d0f-66691e48ae35.mobileprovision")

          fake_storage = "fake_storage"
          expect(Match::Storage::GitStorage).to receive(:configure).with(
            git_url: git_url,
            shallow_clone: true,
            skip_docs: false,
            git_branch: "master",
            git_full_name: nil,
            git_user_email: nil,
            clone_branch_directly: false,
            git_basic_authorization: nil,
            git_bearer_authorization: nil,
            git_private_key: nil,
            type: config[:type],
            generate_apple_certs: generate_apple_certs,
            platform: config[:platform],
            google_cloud_bucket_name: "",
            google_cloud_keys_file: "",
            google_cloud_project_id: "",
            s3_region: nil,
            s3_access_key: nil,
            s3_secret_access_key: nil,
            s3_bucket: nil,
            s3_object_prefix: nil,
            readonly: false,
            username: values[:username],
            team_id: nil,
            team_name: nil,
            api_key_path: nil,
            api_key: nil,
            identifiers: [values[:app_identifier]]
          ).and_return(fake_storage)

          expect(fake_storage).to receive(:download).and_return(nil)
          expect(fake_storage).to receive(:clear_changes).and_return(nil)
          allow(fake_storage).to receive(:working_directory).and_return(repo_dir)
          allow(fake_storage).to receive(:prefixed_working_directory).and_return(repo_dir)
          expect(Match::Generator).to receive(:generate_certificate).with(config, :distribution, fake_storage.working_directory, specific_cert_type: nil).and_return(cert_path)
          expect(Match::Generator).to_not(receive(:generate_provisioning_profile))
          expect(FastlaneCore::ProvisioningProfile).to_not(receive(:install))
          expect(fake_storage).to receive(:save_changes!).with(
            files_to_commit: [
              File.join(repo_dir, "something.cer"),
              File.join(repo_dir, "something.p12") # this is important, as a cert consists out of 2 files
            ]
          )

          spaceship = "spaceship"
          allow(spaceship).to receive(:team_id).and_return("")
          expect(Match::SpaceshipEnsure).to receive(:new).and_return(spaceship)
          expect(spaceship).to receive(:certificates_exists).and_return(true)
          expect(spaceship).to_not(receive(:profile_exists))
          expect(spaceship).to receive(:bundle_identifier_exists).and_return(true)

          Match::Runner.new.run(config)
          # Nothing to check after the run
        end
      end
    end

    describe "#device_count_different?" do
      let(:profile_file) { double("profile file") }
      let(:uuid) { "1234-1234-1234-1234" }
      let(:parsed_profile) { { "UUID" => uuid } }
      let(:profile) { double("profile") }
      let(:profile_device) { double("profile_device") }

      before do
        allow(profile).to receive(:uuid).and_return(uuid)
        allow(profile).to receive(:fetch_all_devices).and_return([profile_device])
      end

      it "device is enabled" do
        expect(FastlaneCore::ProvisioningProfile).to receive(:parse).and_return(parsed_profile)
        expect(Spaceship::ConnectAPI::Profile).to receive(:all).and_return([profile])
        expect(Spaceship::ConnectAPI::Device).to receive(:all).and_return([profile_device])

        expect(profile_device).to receive(:device_class).and_return(Spaceship::ConnectAPI::Device::DeviceClass::IPOD)
        expect(profile_device).to receive(:enabled?).and_return(true)

        runner = Match::Runner.new
        expect(runner.device_count_different?(profile: profile_file, platform: :ios)).to be(false)
      end

      it "device is disabled" do
        expect(FastlaneCore::ProvisioningProfile).to receive(:parse).and_return(parsed_profile)
        expect(Spaceship::ConnectAPI::Profile).to receive(:all).and_return([profile])
        expect(Spaceship::ConnectAPI::Device).to receive(:all).and_return([profile_device])

        expect(profile_device).to receive(:device_class).and_return(Spaceship::ConnectAPI::Device::DeviceClass::IPOD)
        expect(profile_device).to receive(:enabled?).and_return(false)

        runner = Match::Runner.new
        expect(runner.device_count_different?(profile: profile_file, platform: :ios)).to be(true)
      end
    end
  end
end
