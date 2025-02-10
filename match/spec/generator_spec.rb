describe Match::Generator do
  describe 'calling through to other tools' do
    it 'configures cert correctly for nested execution in macOS' do
      require 'cert'

      allow(FastlaneCore::Helper).to receive(:mac?).and_return(true)
      allow(FastlaneCore::Helper).to receive(:xcode_at_least?).and_return(false)
      allow(File).to receive(:exist?).and_call_original
      expect(FastlaneCore::Helper).to receive(:keychain_path).with("login.keychain").exactly(2).times.and_return("fake_keychain_name")
      expect(File).to receive(:expand_path).with("fake_keychain_name").exactly(2).times.and_return("fake_keychain_path")
      expect(File).to receive(:exist?).with("fake_keychain_path").exactly(2).times.and_return(true)

      config = FastlaneCore::Configuration.create(Cert::Options.available_options, {
        development: true,
        output_path: 'workspace/certs/development',
        force: true,
        username: 'username',
        team_id: 'team_id',
        keychain_path: FastlaneCore::Helper.keychain_path("login.keychain"),
        keychain_password: 'password',
        platform: "ios",
        filename: nil,
        team_name: nil
      })

      # This is the important part. We need to see the right configuration come through
      # for cert
      expect(Cert).to receive(:config=).with(a_configuration_matching(config))

      # This just mocks out the usual behavior of running cert, since that's not what
      # we're testing
      fake_runner = "fake_runner"
      allow(Cert::Runner).to receive(:new).and_return(fake_runner)
      allow(fake_runner).to receive(:launch).and_return("fake_path")

      params = {
        type: 'development',
        workspace: 'workspace',
        username: 'username',
        team_id: 'team_id',
        keychain_name: 'login.keychain',
        keychain_password: 'password'
      }

      Match::Generator.generate_certificate(params, 'development', "workspace")
    end

    it 'configures cert correctly for nested execution in non-macOS' do
      require 'cert'

      fake_runner = "fake_runner"
      allow(Cert::Runner).to receive(:new).and_return(fake_runner)
      allow(fake_runner).to receive(:launch).and_return("fake_path")

      allow(FastlaneCore::Helper).to receive(:mac?).and_return(false)
      expect(FastlaneCore::Helper).not_to receive(:keychain_path)
      expect(File).not_to receive(:expand_path)

      config = FastlaneCore::Configuration.create(Cert::Options.available_options, {
        development: true,
        output_path: 'workspace/certs/development',
        force: true,
        username: 'username',
        team_id: 'team_id',
        keychain_path: nil,
        keychain_password: nil,
        platform: "ios",
        filename: nil,
        team_name: nil
      })
      expect(Cert).to receive(:config=).with(a_configuration_matching(config))

      params = {
        type: 'development',
        workspace: 'workspace',
        username: 'username',
        team_id: 'team_id',
        keychain_name: 'login.keychain',
        keychain_password: 'password'
      }

      Match::Generator.generate_certificate(params, 'development', "workspace")
    end

    it 'verifies keychain_path in macOS' do
      require 'cert'

      fake_runner = "fake_runner"
      allow(Cert::Runner).to receive(:new).and_return(fake_runner)
      allow(fake_runner).to receive(:launch).and_return("fake_path")

      allow(FastlaneCore::Helper).to receive(:mac?).and_return(true)
      allow(FastlaneCore::Helper).to receive(:xcode_at_least?).and_return(false)
      allow(File).to receive(:exist?).and_call_original
      expect(FastlaneCore::Helper).to receive(:keychain_path).with("login.keychain").and_return("fake_keychain_name")
      expect(File).to receive(:expand_path).with("fake_keychain_name").and_return("fake_keychain_path")
      expect(File).to receive(:exist?).with("fake_keychain_path").and_return(true)

      params = {
        type: 'development',
        workspace: 'workspace',
        username: 'username',
        team_id: 'team_id',
        keychain_name: 'login.keychain',
        keychain_password: 'password'
      }

      Match::Generator.generate_certificate(params, 'development', "workspace")
    end

    it 'configures sigh correctly for nested execution' do
      require 'sigh'

      config = FastlaneCore::Configuration.create(Sigh::Options.available_options, {
        app_identifier: 'app_identifier',
        development: true,
        output_path: 'workspace/profiles/development',
        username: 'username',
        force: false,
        cert_id: 'fake_cert_id',
        provisioning_name: 'match Development app_identifier',
        ignore_profiles_with_different_name: true,
        team_id: 'team_id',
        platform: :ios,
        template_name: 'template_name',
        fail_on_name_taken: false,
        include_all_certificates: true,
      })

      # This is the important part. We need to see the right configuration come through
      # for sigh
      expect(Sigh).to receive(:config=).with(a_configuration_matching(config))

      # This just mocks out the usual behavior of running sigh, since that's not what
      # we're testing
      allow(Sigh::Manager).to receive(:start).and_return("fake_path")

      params = {
        app_identifier: 'app_identifier',
        type: :development,
        workspace: 'workspace',
        username: 'username',
        team_id: 'team_id',
        platform: :ios,
        template_name: 'template_name',
        include_all_certificates: true,
      }
      Match::Generator.generate_provisioning_profile(params: params, prov_type: :development, certificate_id: 'fake_cert_id', app_identifier: params[:app_identifier], force: false, working_directory: "workspace")
    end
  end
end
