describe Sigh do
  describe Sigh::Manager do
    around do |example|
      FastlaneSpec::Env.with_env_values(
        DELIVER_USER: 'test@fastlane.tools',
        DELIVER_PASSWORD: '123'
      ) do
        example.run
      end
    end

    let(:mock_base_client) { "fake api base client" }

    before(:each) do
      allow(mock_base_client).to receive(:login)
      allow(mock_base_client).to receive(:team_id).and_return('')

      allow(Spaceship::ConnectAPI::Provisioning::Client).to receive(:instance).and_return(mock_base_client)
    end

    it "Successful run" do
      sigh_stub_spaceship_connect(inhouse: false, create_profile_app_identifier: "com.krausefx.app", all_app_identifiers: ["com.krausefx.app"])

      options = { app_identifier: "com.krausefx.app", skip_install: true, skip_certificate_verification: true }
      Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

      val = Sigh::Manager.start
      expect(val).to eq(File.expand_path("./AppStore_com.krausefx.app.mobileprovision"))
      File.delete(val)
    end

    it "Invalid profile not force run" do
      sigh_stub_spaceship_connect(inhouse: false, create_profile_app_identifier: "com.krausefx.app", all_app_identifiers: ["com.krausefx.app"], app_identifier_and_profile_names: { "com.krausefx.app" => ["No dupe here"] }, valid_profiles: false)

      options = { app_identifier: "com.krausefx.app", skip_install: true, skip_certificate_verification: true }
      Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

      val = Sigh::Manager.start
      expect(val).to eq(File.expand_path("./AppStore_com.krausefx.app.mobileprovision"))
      File.delete(val)
    end

    it "Invalid profile force run" do
      sigh_stub_spaceship_connect(inhouse: false, create_profile_app_identifier: "com.krausefx.app", all_app_identifiers: ["com.krausefx.app"], app_identifier_and_profile_names: { "com.krausefx.app" => ["No dupe here"] }, valid_profiles: false, expect_delete: true)

      options = { app_identifier: "com.krausefx.app", skip_install: true, skip_certificate_verification: true, force: true }
      Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

      val = Sigh::Manager.start
      expect(val).to eq(File.expand_path("./AppStore_com.krausefx.app.mobileprovision"))
      File.delete(val)
    end

    it "Existing profile fail on name taken" do
      sigh_stub_spaceship_connect(inhouse: false, create_profile_app_identifier: nil, all_app_identifiers: ["com.krausefx.app", "com.krausefx.app.other"], app_identifier_and_profile_names: { "com.krausefx.app.other" => ["com.krausefx.app AppStore"] })

      options = { app_identifier: "com.krausefx.app", skip_install: true, fail_on_name_taken: true, skip_certificate_verification: true, force: false }
      Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options)

      expect { Sigh::Manager.start }.to raise_error("The name 'com.krausefx.app AppStore' is already taken, and fail_on_name_taken is true")
    end
  end
end
