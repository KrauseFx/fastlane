describe CredentialsManager do
  describe CredentialsManager::AccountManager do
    let(:user) { "felix@krausefx.com" }
    let(:password) { "suchSecret" }

    it "allows passing user and password" do
      c = CredentialsManager::AccountManager.new(user: user, password: password)
      expect(c.user).to eq(user)
      expect(c.password).to eq(password)
    end

    it "loads the user from the new 'FASTLANE_USER' variable" do
      FastlaneSpec::Env.with_env_values(FASTLANE_USER: user) do
        c = CredentialsManager::AccountManager.new
        expect(c.user).to eq(user)
      end
    end

    it "loads the password from the new 'FASTLANE_PASSWORD' variable" do
      FastlaneSpec::Env.with_env_values(FASTLANE_PASSWORD: password) do
        c = CredentialsManager::AccountManager.new
        expect(c.password).to eq(password)
      end
    end

    it "still supports the legacy `DELIVER_USER` `DELIVER_PASSWORD` format" do
      FastlaneSpec::Env.with_env_values(DELIVER_USER: user, DELIVER_PASSWORD: password) do
        c = CredentialsManager::AccountManager.new
        expect(c.user).to eq(user)
        expect(c.password).to eq(password)
      end
    end

    it "fetches the Apple ID from the Appfile if available" do
      Dir.chdir("./credentials_manager/spec/fixtures/") do
        c = CredentialsManager::AccountManager.new
        expect(c.user).to eq("appfile@krausefx.com")
      end
    end

    it "automatically loads the password from the keychain" do
      FastlaneSpec::Env.with_env_values(FASTLANE_USER: user) do
        c = CredentialsManager::AccountManager.new

        dummy = Object.new
        expect(dummy).to receive(:password).and_return("Yeah! Pass!")

        expect(Security::InternetPassword).to receive(:find).with(server: "deliver.felix@krausefx.com").and_return(dummy)
        expect(c.password).to eq("Yeah! Pass!")
      end
    end

    it "loads the password from the keychain if empty password is stored by env" do
      FastlaneSpec::Env.with_env_values(FASTLANE_USER: user, FASTLANE_PASSWORD: '') do
        c = CredentialsManager::AccountManager.new

        dummy = Object.new
        expect(dummy).to receive(:password).and_return("Yeah! Pass!")

        expect(Security::InternetPassword).to receive(:find).with(server: "deliver.felix@krausefx.com").and_return(dummy)
        expect(c.password).to eq("Yeah! Pass!")
      end
    end

    it "removes the Keychain item if the user agrees when the credentials are invalid" do
      expect(Security::InternetPassword).to receive(:delete).with(server: "deliver.felix@krausefx.com").and_return(nil)

      c = CredentialsManager::AccountManager.new(user: "felix@krausefx.com")
      expect(c).to receive(:ask_for_login).and_return(nil)
      c.invalid_credentials(force: true)
    end

    it "defaults to 'deliver' as a prefix" do
      c = CredentialsManager::AccountManager.new(user: user)
      expect(c.server_name).to eq("deliver.#{user}")
    end

    it "supports custom prefixes" do
      prefix = "custom-prefix"
      c = CredentialsManager::AccountManager.new(user: user, prefix: prefix)
      expect(c.server_name).to eq("#{prefix}.#{user}")
    end
  end
end
