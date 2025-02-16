require_relative 'spec_helper'

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

          fake_cache = create_fake_cache

          fake_storage = "fake_storage"
          expect(Match::Storage::GitStorage).to receive(:configure).with({
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
            platform: config[:platform]
          }).and_return(fake_storage)

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
                                                                                    cache: fake_cache,
                                                                       working_directory: fake_storage.working_directory).and_return(profile_path)
          expect(FastlaneCore::ProvisioningProfile).to receive(:install).with(profile_path, keychain_path).and_return(destination)
          expect(fake_storage).to receive(:save_changes!).with(
            files_to_commit: [
              File.join(repo_dir, "something.cer"),
              File.join(repo_dir, "something.p12"), # this is important, as a cert consists out of 2 files
              "./match/spec/fixtures/test.mobileprovision"
            ],
            files_to_delete: []
          )

          spaceship = "spaceship"
          allow(spaceship).to receive(:team_id).and_return("")
          expect(Match::SpaceshipEnsure).to receive(:new).and_return(spaceship)
          expect(spaceship).to receive(:certificates_exists).and_return(true)
          expect(spaceship).not_to receive(:profile_exists)
          expect(spaceship).to receive(:bundle_identifier_exists).and_return(true)
          expect(Match::Utils).to receive(:get_cert_info).and_return([["Common Name", "fastlane certificate name"]])

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
          expect(ENV[Match::Utils.environment_variable_name_certificate_name(app_identifier: "tools.fastlane.app",
                                                                             type: "appstore")]).to eql("fastlane certificate name")
        end

        it "uses existing certificates and profiles if they exist", requires_security: true do
          git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
          values = {
            app_identifier: "tools.fastlane.app",
            type: "appstore",
            git_url: git_url,
            username: "flapple@something.com"
          }

          create_fake_cache

          config = FastlaneCore::Configuration.create(Match::Options.available_options, values)
          repo_dir = "./match/spec/fixtures/existing"
          cert_path = "./match/spec/fixtures/existing/certs/distribution/E7P4EE896K.cer"
          key_path = "./match/spec/fixtures/existing/certs/distribution/E7P4EE896K.p12"

          fake_storage = "fake_storage"
          expect(Match::Storage::GitStorage).to receive(:configure).with({
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
            platform: config[:platform]
          }).and_return(fake_storage)

          expect(fake_storage).to receive(:download).and_return(nil)
          expect(fake_storage).to receive(:clear_changes).and_return(nil)
          allow(fake_storage).to receive(:git_url).and_return(git_url)
          allow(fake_storage).to receive(:working_directory).and_return(repo_dir)
          allow(fake_storage).to receive(:prefixed_working_directory).and_return(repo_dir)

          fake_encryption = "fake_encryption"
          expect(Match::Encryption::OpenSSL).to receive(:new).with(keychain_name: fake_storage.git_url, working_directory: fake_storage.working_directory, force_legacy_encryption: false).and_return(fake_encryption)
          expect(fake_encryption).to receive(:decrypt_files).and_return(nil)

          expect(Match::Utils).to receive(:import).with(key_path, keychain, password: nil, skip_set_partition_list: false).and_return(nil)
          expect(fake_storage).to_not(receive(:save_changes!))

          # To also install the certificate, fake that
          expect(FastlaneCore::CertChecker).to receive(:installed?).with(cert_path, in_keychain: nil).and_return(false)
          expect(Match::Utils).to receive(:import).with(cert_path, keychain, password: nil, skip_set_partition_list: false).and_return(nil)

          spaceship = "spaceship"
          allow(spaceship).to receive(:team_id).and_return("")
          expect(Match::SpaceshipEnsure).to receive(:new).and_return(spaceship)
          expect(spaceship).to receive(:certificates_exists).and_return(true)
          expect(spaceship).to receive(:profile_exists).and_return(true)
          expect(spaceship).to receive(:bundle_identifier_exists).and_return(true)
          expect(Match::Utils).to receive(:get_cert_info)
          expect(Match::Utils).to receive(:get_cert_info).and_return([["Common Name", "fastlane certificate name"]])

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
          expect(ENV[Match::Utils.environment_variable_name_certificate_name(app_identifier: "tools.fastlane.app",
                                                                             type: "appstore")]).to eql("fastlane certificate name")
        end

        it "fails because of an outdated certificate in readonly mode", requires_security: true do
          git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
          values = {
            app_identifier: "tools.fastlane.app",
            type: "appstore",
            git_url: git_url,
            username: "flapple@something.com",
            readonly: true
          }

          config = FastlaneCore::Configuration.create(Match::Options.available_options, values)
          repo_dir = "./match/spec/fixtures/existing"
          cert_path = "./match/spec/fixtures/existing/certs/distribution/E7P4EE896K.cer"
          key_path = "./match/spec/fixtures/existing/certs/distribution/E7P4EE896K.p12"

          create_fake_cache

          fake_storage = create_fake_storage(match_config: config, repo_dir: repo_dir)

          fake_encryption = "fake_encryption"
          expect(Match::Encryption::OpenSSL).to receive(:new).with(keychain_name: fake_storage.git_url, working_directory: fake_storage.working_directory, force_legacy_encryption: false).and_return(fake_encryption)
          expect(fake_encryption).to receive(:decrypt_files).and_return(nil)

          spaceship = "spaceship"
          allow(spaceship).to receive(:team_id).and_return("")
          expect(Match::SpaceshipEnsure).not_to receive(:new)

          expect(Match::Utils).to receive(:is_cert_valid?).and_return(false)

          expect do
            Match::Runner.new.run(config)
          end.to raise_error("Your certificate 'E7P4EE896K.cer' is not valid, please check end date and renew it if necessary")
        end

        it "installs profiles in read-only mode", requires_security: true do
          # GIVEN

          # Downloaded and decrypted storage location.
          repo_dir = "./match/spec/fixtures/existing"
          #   Valid cert and key
          stored_valid_cert_path = "#{repo_dir}/certs/distribution/E7P4EE896K.cer"
          stored_valid_profile_path = "#{repo_dir}/profiles/appstore/AppStore_tools.fastlane.app.mobileprovision"

          # match options
          match_test_options = {
            output_path: "tmp/match_certs", # to test the expectation that we do a file copy when this option is provided
            readonly: true # Current test suite.
          }
          match_config = create_match_config_with_git_storage(extra_values: match_test_options)

          # EXPECTATIONS

          # Ensure cache is not used.
          create_fake_cache(allow_usage: false)

          # Storage
          fake_storage = create_fake_storage(match_config: match_config, repo_dir: repo_dir)
          # Ensure no changes in storage are made.
          expect(fake_storage).not_to receive(:save_changes!)

          # Encryption
          fake_encryption = create_fake_encryption(storage: fake_storage)
          # Ensure there are no new files to encrypt.
          expect(fake_encryption).not_to receive(:encrypt_files)

          # Utils
          # Ensure match validates stored certificate.
          expect(Match::Utils).to receive(:is_cert_valid?).with(stored_valid_cert_path).and_return(true)

          # Certificates
          # Ensure a new certificate is not generated.
          expect(Match::Generator).not_to receive(:generate_certificate).with(match_config, :distribution, fake_storage.working_directory, specific_cert_type: nil)

          # Profiles
          begin # Ensure profiles are installed, but not validated.
            keychain_path = FastlaneCore::Helper.keychain_path("login.keychain")
            expect(FastlaneCore::ProvisioningProfile).to receive(:install).with(stored_valid_profile_path, keychain_path)
            expect(Match::Generator).not_to receive(:generate_provisioning_profile)
          end

          # output_path
          expect(FileUtils).to receive(:mkdir_p).with(match_test_options[:output_path])
          expect(FileUtils).to receive(:cp).with(stored_valid_cert_path, match_test_options[:output_path])
          expect(FileUtils).to receive(:cp).with("#{repo_dir}/certs/distribution/E7P4EE896K.p12", match_test_options[:output_path])
          expect(FileUtils).to receive(:cp).with(stored_valid_profile_path, match_test_options[:output_path])

          # WHEN
          Match::Runner.new.run(match_config)

          # THEN
          # Rely on expectations defined above.
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

          create_fake_cache

          fake_storage = "fake_storage"
          expect(Match::Storage::GitStorage).to receive(:configure).with({
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
            platform: config[:platform]
          }).and_return(fake_storage)

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
            ],
            files_to_delete: []
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

        it "fails because enterprise type requested without in_house credentials", requires_security: true do
          git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
          values = {
            app_identifier: "tools.fastlane.app",
            type: "enterprise",
            git_url: git_url,
            username: "flapple@something.com",
            readonly: false
          }

          config = FastlaneCore::Configuration.create(Match::Options.available_options, values)
          repo_dir = "./match/spec/fixtures/existing"
          cert_path = "./match/spec/fixtures/existing/certs/distribution/E7P4EE896K.cer"
          key_path = "./match/spec/fixtures/existing/certs/distribution/E7P4EE896K.p12"

          create_fake_cache

          fake_storage = create_fake_storage(match_config: config, repo_dir: repo_dir)

          fake_encryption = "fake_encryption"
          expect(Match::Encryption::OpenSSL).to receive(:new).with(keychain_name: fake_storage.git_url, working_directory: fake_storage.working_directory, force_legacy_encryption: false).and_return(fake_encryption)
          expect(fake_encryption).to receive(:decrypt_files).and_return(nil)

          client = "client"
          expect(Match::SpaceshipEnsure).to receive(:new)
          expect(Spaceship::ConnectAPI).to receive(:client).and_return(client)
          allow(client).to receive(:in_house?).and_return(false)

          expect do
            Match::Runner.new.run(config)
          end.to raise_error("You defined the profile type 'enterprise', but your Apple account doesn't support In-House profiles")
        end
      end
    end
  end
end
