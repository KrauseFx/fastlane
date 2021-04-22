describe Sigh do
  describe Sigh::Runner do
    around do |example|
      FastlaneSpec::Env.with_env_values(
        DELIVER_USER: 'test@fastlane.tools',
        DELIVER_PASSWORD: '123'
      ) do
        example.run
      end
    end

    let(:fake_runner) { Sigh::Runner.new }
    let(:mock_base_client) { "fake api base client" }

    before(:each) do
      allow(mock_base_client).to receive(:login)
      allow(mock_base_client).to receive(:team_id).and_return('')

      allow(Spaceship::ConnectAPI::Provisioning::Client).to receive(:instance).and_return(mock_base_client)
    end

    describe "#run" do
    end

    describe "#profile_type" do
      profile_types = {
        "ios" => {
          Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_STORE => { in_house: false, options: { platform: "ios" } },
          Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_INHOUSE => { in_house: true, options: { platform: "ios" } },
          Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_ADHOC => { in_house: false, options: { platform: "ios", adhoc: true } },
          Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_DEVELOPMENT => { in_house: false, options: { platform: "ios", development: true } }
        },
        "tvos" => {
          Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_STORE => { in_house: false, options: { platform: "tvos" } },
          Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_INHOUSE => { in_house: true, options: { platform: "tvos" } },
          Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_ADHOC => { in_house: false, options: { platform: "tvos", adhoc: true } },
          Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_DEVELOPMENT => { in_house: false, options: { platform: "tvos", development: true } }
        },
        "macos" => {
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_STORE => { in_house: false, options: { platform: "macos" } },
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_DEVELOPMENT => { in_house: false, options: { platform: "macos", development: true } },
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_DIRECT => { in_house: false, options: { platform: "macos", developer_id: true } }
        },
        "catalyst" => {
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_STORE => { in_house: false, options: { platform: "catalyst" } },
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_DEVELOPMENT => { in_house: false, options: { platform: "catalyst", development: true } },
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_DIRECT => { in_house: false, options: { platform: "catalyst", developer_id: true } }
        }
      }

      # Iterates over platforms
      profile_types.each do |platform, test|
        context platform do
          # Creates test for each profile type in platform
          test.each do |type, test_options|
            it type do
              sigh_stub_spaceship_connect(inhouse: test_options[:in_house])

              Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, test_options[:options])
              expect(fake_runner.profile_type).to eq(type)
            end
          end
        end
      end
    end

    describe "#fetch_profiles" do
      context "successfully" do
        it "with skip verification" do
          sigh_stub_spaceship_connect(inhouse: false, all_app_identifiers: ["com.krausefx.app"], app_identifier_and_profile_names: { "com.krausefx.app" => ["No dupe here"] })

          options = { app_identifier: "com.krausefx.app", skip_certificate_verification: true }
          Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

          profiles = fake_runner.fetch_profiles
          expect(profiles.size).to eq(1)
        end

        it "without skip verification" do
          sigh_stub_spaceship_connect(inhouse: false, all_app_identifiers: ["com.krausefx.app"], app_identifier_and_profile_names: { "com.krausefx.app" => ["No dupe here"] })

          options = { app_identifier: "com.krausefx.app", skip_certificate_verification: false }
          Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

          expect(FastlaneCore::CertChecker).to receive(:installed?).with(anything).and_return(true)

          profiles = fake_runner.fetch_profiles
          expect(profiles.size).to eq(1)
        end
      end

      context "unsuccessfully" do
        it "without skip verification" do
          sigh_stub_spaceship_connect(inhouse: false, all_app_identifiers: ["com.krausefx.app"], app_identifier_and_profile_names: { "com.krausefx.app" => ["No dupe here"] })

          options = { app_identifier: "com.krausefx.app", skip_certificate_verification: false }
          Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

          expect(FastlaneCore::CertChecker).to receive(:installed?).with(anything).and_return(false)

          profiles = fake_runner.fetch_profiles
          expect(profiles.size).to eq(0)
        end
      end
    end

    describe "#devices_to_use" do
      it "no devices for app store" do
        options = {}
        Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

        expect(Spaceship::ConnectAPI::Device).not_to(receive(:all))

        devices = fake_runner.devices_to_use
        expect(devices.size).to eq(0)
      end

      it "no devices for developer id" do
        options = { developer_id: true }
        Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

        expect(Spaceship::ConnectAPI::Device).not_to(receive(:all))

        devices = fake_runner.devices_to_use
        expect(devices.size).to eq(0)
      end

      it "devices for development" do
        options = { development: true }
        Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

        expect(Spaceship::ConnectAPI::Device).to receive(:all).and_return(["device"])

        devices = fake_runner.devices_to_use
        expect(devices.size).to eq(1)
      end

      it "devices for adhoc" do
        options = { adhoc: true }
        Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

        expect(Spaceship::ConnectAPI::Device).to receive(:all).and_return(["device"])

        devices = fake_runner.devices_to_use
        expect(devices.size).to eq(1)
      end
    end

    describe "#certificates_to_use" do
      it "list certificates found when there're multiple certificates and not in development" do
        options = { skip_certificate_verification: true }
        Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)
        sigh_stub_spaceship_connect

        certificates_to_use = fake_runner.certificates_to_use
        expect(certificates_to_use.size).to eq(1)
      end
    end

    describe "#profile_type_pretty_type" do
      profile_types = {
        Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_STORE => "AppStore",
        Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_INHOUSE => "InHouse",
        Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_ADHOC => "AdHoc",
        Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_DEVELOPMENT => "Development",
        Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_STORE => "AppStore",
        Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_INHOUSE => "InHouse",
        Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_ADHOC => "AdHoc",
        Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_DEVELOPMENT => "Development",
        Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_STORE => "AppStore",
        Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_DEVELOPMENT => "Development",
        Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_DIRECT => "Direct",
        Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_STORE => "AppStore",
        Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_DEVELOPMENT => "Development",
        Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_DIRECT => "Direct"
      }

      # Creates test for each profile type
      profile_types.each do |type, pretty_type|
        it "#{type} - #{pretty_type}" do
          allow(fake_runner).to receive(:profile_type).and_return(type)
          expect(fake_runner.profile_type_pretty_type).to eq(pretty_type)
        end
      end
    end

    describe "#create_profile!" do
      context "successfully creates profile" do
        it "skips fetching of profiles" do
          sigh_stub_spaceship_connect(inhouse: false, create_profile_app_identifier: "com.krausefx.app", all_app_identifiers: ["com.krausefx.app"])

          options = { app_identifier: "com.krausefx.app", skip_install: true, skip_certificate_verification: true, skip_fetch_profiles: true }
          Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

          profile = fake_runner.create_profile!

          expect(profile.name).to eq("com.krausefx.app AppStore")
          expect(profile.bundle_id.identifier).to eq("com.krausefx.app")
        end

        it "skips fetches profiles with no duplicate name" do
          sigh_stub_spaceship_connect(inhouse: false, create_profile_app_identifier: "com.krausefx.app", all_app_identifiers: ["com.krausefx.app"], app_identifier_and_profile_names: { "com.krausefx.app" => ["No dupe here"] })

          options = { app_identifier: "com.krausefx.app", skip_install: true, skip_certificate_verification: true, skip_fetch_profiles: true }
          Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

          profile = fake_runner.create_profile!

          expect(profile.name).to eq("com.krausefx.app AppStore")
          expect(profile.bundle_id.identifier).to eq("com.krausefx.app")
        end

        it "fetches profiles with duplicate name and appends timestamp" do
          sigh_stub_spaceship_connect(inhouse: false, create_profile_app_identifier: "com.krausefx.app", all_app_identifiers: ["com.krausefx.app"], app_identifier_and_profile_names: { "com.krausefx.app" => ["com.krausefx.app AppStore"] })

          allow(Time).to receive(:now).and_return(Time.at(1_608_653_743))

          options = { app_identifier: "com.krausefx.app", skip_install: true, skip_certificate_verification: true, skip_fetch_profiles: false }
          Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

          profile = fake_runner.create_profile!

          expect(profile.name).to eq("com.krausefx.app AppStore 1608653743")
          expect(profile.bundle_id.identifier).to eq("com.krausefx.app")
        end
      end

      context "raises error" do
        it "when cannot find bundle id" do
          sigh_stub_spaceship_connect(inhouse: false, all_app_identifiers: [])

          options = { app_identifier: "com.krausefx.app", skip_install: true, skip_certificate_verification: true, skip_fetch_profiles: true }
          Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

          expect do
            fake_runner.create_profile!
          end.to raise_error("Could not find App with App Identifier 'com.krausefx.app'")
        end

        it "when name already taken" do
          sigh_stub_spaceship_connect(inhouse: false, all_app_identifiers: ["com.krausefx.app"], app_identifier_and_profile_names: { "com.krausefx.app" => ["com.krausefx.app AppStore"] })

          options = { app_identifier: "com.krausefx.app", skip_install: true, skip_certificate_verification: true, skip_fetch_profiles: false, fail_on_name_taken: true }
          Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

          expect do
            fake_runner.create_profile!
          end.to raise_error("The name 'com.krausefx.app AppStore' is already taken, and fail_on_name_taken is true")
        end
      end
    end

    describe "#download_profile" do
      it "ios" do
        sigh_stub_spaceship_connect(inhouse: false, all_app_identifiers: [])

        options = { platform: "ios", app_identifier: "com.krausefx.app", skip_install: true, skip_certificate_verification: true, skip_fetch_profiles: true }
        Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

        profile = Spaceship::ConnectAPI::Profile.new("123", {
          profileContent: Base64.encode64("12345")
        })

        path = fake_runner.download_profile(profile)
        expect(path).to end_with("AppStore_com.krausefx.app.mobileprovision")
        expect(File.binread(path)).to eq("12345")
      end

      it "tvos" do
        sigh_stub_spaceship_connect(inhouse: false, all_app_identifiers: [])

        options = { platform: "tvos", app_identifier: "com.krausefx.app", skip_install: true, skip_certificate_verification: true, skip_fetch_profiles: true }
        Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

        profile = Spaceship::ConnectAPI::Profile.new("123", {
          profileContent: Base64.encode64("12345")
        })

        path = fake_runner.download_profile(profile)
        expect(path).to end_with("AppStore_com.krausefx.app_tvos.mobileprovision")
        expect(File.binread(path)).to eq("12345")
      end

      it "macos" do
        sigh_stub_spaceship_connect(inhouse: false, all_app_identifiers: [])

        options = { platform: "macos", app_identifier: "com.krausefx.app", skip_install: true, skip_certificate_verification: true, skip_fetch_profiles: true }
        Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

        profile = Spaceship::ConnectAPI::Profile.new("123", {
          profileContent: Base64.encode64("12345")
        })

        path = fake_runner.download_profile(profile)
        expect(path).to end_with("AppStore_com.krausefx.app.provisionprofile")
        expect(File.binread(path)).to eq("12345")
      end

      it "catalyst" do
        sigh_stub_spaceship_connect(inhouse: false, all_app_identifiers: [])

        options = { platform: "catalyst", app_identifier: "com.krausefx.app", skip_install: true, skip_certificate_verification: true, skip_fetch_profiles: true }
        Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

        profile = Spaceship::ConnectAPI::Profile.new("123", {
          profileContent: Base64.encode64("12345")
        })

        path = fake_runner.download_profile(profile)
        expect(path).to end_with("AppStore_com.krausefx.app_catalyst.provisionprofile")
        expect(File.binread(path)).to eq("12345")
      end
    end
  end
end
