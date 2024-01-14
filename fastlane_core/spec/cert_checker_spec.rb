describe FastlaneCore do
  describe FastlaneCore::CertChecker do
    let(:success_status) {
      class ProcessStatusMock
      end

      allow_any_instance_of(ProcessStatusMock).to receive(:success?).and_return(true)

      ProcessStatusMock.new
    }

    describe '#installed_identities' do
      it 'should print an error when no local code signing identities are found' do
        allow(FastlaneCore::CertChecker).to receive(:installed_wwdr_certificates).and_return(['G2', 'G3', 'G4', 'G5', 'G6'])
        allow(FastlaneCore::CertChecker).to receive(:list_available_identities).and_return("     0 valid identities found\n")
        expect(FastlaneCore::UI).to receive(:error).with(/There are no local code signing identities found/)

        FastlaneCore::CertChecker.installed_identities
      end

      it 'should not be fooled by 10 local code signing identities available' do
        allow(FastlaneCore::CertChecker).to receive(:installed_wwdr_certificates).and_return(['G2', 'G3', 'G4', 'G5', 'G6'])
        allow(FastlaneCore::CertChecker).to receive(:list_available_identities).and_return("     10 valid identities found\n")
        expect(FastlaneCore::UI).not_to(receive(:error))

        FastlaneCore::CertChecker.installed_identities
      end
    end

    describe '#installed_wwdr_certificates' do
      let(:cert) do
        cert = OpenSSL::X509::Certificate.new
        key = OpenSSL::PKey::RSA.new(2048)
        root_key = OpenSSL::PKey::RSA.new(2048)
        cert.public_key = key.public_key
        cert.sign(root_key, OpenSSL::Digest::SHA256.new)
        cert
      end

      it "should return installed certificate's alias" do
        expect(FastlaneCore::CertChecker).to receive(:wwdr_keychain).and_return('login.keychain')

        allow(FastlaneCore::Helper).to receive(:backticks).with(/security find-certificate/, { print: false }).and_return("-----BEGIN CERTIFICATE-----\nG6\n-----END CERTIFICATE-----\n")

        allow(Digest::SHA256).to receive(:hexdigest).with(cert.to_der).and_return('bdd4ed6e74691f0c2bfd01be0296197af1379e0418e2d300efa9c3bef642ca30')
        allow(OpenSSL::X509::Certificate).to receive(:new).and_return(cert)

        expect(FastlaneCore::CertChecker.installed_wwdr_certificates).to eq(['G6'])
      end

      it "should return an empty array if unknown WWDR certificates are found" do
        expect(FastlaneCore::CertChecker).to receive(:wwdr_keychain).and_return('login.keychain')

        allow(FastlaneCore::Helper).to receive(:backticks).with(/security find-certificate/, { print: false }).and_return("-----BEGIN CERTIFICATE-----\nG6\n-----END CERTIFICATE-----\n")

        allow(OpenSSL::X509::Certificate).to receive(:new).and_return(cert)

        expect(FastlaneCore::CertChecker.installed_wwdr_certificates).to eq([])
      end
    end

    describe '#install_missing_wwdr_certificates' do
      it 'should install all official WWDR certificates' do
        allow(FastlaneCore::CertChecker).to receive(:installed_wwdr_certificates).and_return([])
        expect(FastlaneCore::CertChecker).to receive(:install_wwdr_certificate).with('G2')
        expect(FastlaneCore::CertChecker).to receive(:install_wwdr_certificate).with('G3')
        expect(FastlaneCore::CertChecker).to receive(:install_wwdr_certificate).with('G4')
        expect(FastlaneCore::CertChecker).to receive(:install_wwdr_certificate).with('G5')
        expect(FastlaneCore::CertChecker).to receive(:install_wwdr_certificate).with('G6')
        expect(FastlaneCore::CertChecker).to receive(:install_wwdr_certificate).with('DEV-ID-G1')
        expect(FastlaneCore::CertChecker).to receive(:install_wwdr_certificate).with('DEV-ID-G2')
        FastlaneCore::CertChecker.install_missing_wwdr_certificates
      end

      it 'should install the missing official WWDR certificate' do
        allow(FastlaneCore::CertChecker).to receive(:installed_wwdr_certificates).and_return(['G2', 'G3', 'G4', 'G5', 'DEV-ID-G2'])
        expect(FastlaneCore::CertChecker).to receive(:install_wwdr_certificate).with('G6')
        expect(FastlaneCore::CertChecker).to receive(:install_wwdr_certificate).with('DEV-ID-G1')
        FastlaneCore::CertChecker.install_missing_wwdr_certificates
      end

      it 'should download the WWDR certificate from correct URL' do
        allow(FastlaneCore::CertChecker).to receive(:wwdr_keychain).and_return('login.keychain')

        expect(Open3).to receive(:capture3).with(include('https://www.apple.com/certificateauthority/AppleWWDRCAG2.cer')).and_return(["", "", success_status])
        FastlaneCore::CertChecker.install_wwdr_certificate('G2')

        expect(Open3).to receive(:capture3).with(include('https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer')).and_return(["", "", success_status])
        FastlaneCore::CertChecker.install_wwdr_certificate('G3')

        expect(Open3).to receive(:capture3).with(include('https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer')).and_return(["", "", success_status])
        FastlaneCore::CertChecker.install_wwdr_certificate('G4')

        expect(Open3).to receive(:capture3).with(include('https://www.apple.com/certificateauthority/AppleWWDRCAG5.cer')).and_return(["", "", success_status])
        FastlaneCore::CertChecker.install_wwdr_certificate('G5')

        expect(Open3).to receive(:capture3).with(include('https://www.apple.com/certificateauthority/AppleWWDRCAG6.cer')).and_return(["", "", success_status])
        FastlaneCore::CertChecker.install_wwdr_certificate('G6')

        expect(Open3).to receive(:capture3).with(include('https://www.apple.com/certificateauthority/DeveloperIDCA.cer')).and_return(["", "", success_status])
        FastlaneCore::CertChecker.install_wwdr_certificate('DEV-ID-G1')

        expect(Open3).to receive(:capture3).with(include('https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer')).and_return(["", "", success_status])
        FastlaneCore::CertChecker.install_wwdr_certificate('DEV-ID-G2')
      end
    end

    describe 'shell escaping' do
      let(:keychain_name) { "keychain with spaces.keychain" }
      let(:shell_escaped_name) { keychain_name.shellescape }
      let(:name_regex) { Regexp.new(Regexp.escape(shell_escaped_name)) }

      it 'should shell escape keychain names when checking for installation' do
        expect(FastlaneCore::CertChecker).to receive(:wwdr_keychain).and_return(keychain_name)
        expect(FastlaneCore::Helper).to receive(:backticks).with(name_regex, { print: false }).and_return("")

        FastlaneCore::CertChecker.installed_wwdr_certificates
      end

      describe 'uses the correct command to import it' do
        it 'with default' do
          # We have to execute *something* using ` since otherwise we set expectations to `nil`, which is not healthy
          `ls`

          keychain = "keychain with spaces.keychain"
          cmd = %r{curl -f -o (([A-Z]\:)?\/.+\.cer) https://www\.apple\.com/certificateauthority/AppleWWDRCAG6\.cer && security import \1 -k #{Regexp.escape(keychain.shellescape)}}
          require "open3"

          expect(Open3).to receive(:capture3).with(cmd).and_return(["", "", success_status])
          expect(FastlaneCore::CertChecker).to receive(:wwdr_keychain).and_return(keychain_name)

          allow(FastlaneCore::CertChecker).to receive(:installed_wwdr_certificates).and_return(['G2', 'G3', 'G4', 'G5', 'DEV-ID-G1', 'DEV-ID-G2'])
          expect(FastlaneCore::CertChecker.install_missing_wwdr_certificates).to be(1)
        end

        it 'with FASTLANE_WWDR_USE_HTTP1_AND_RETRIES feature' do
          # We have to execute *something* using ` since otherwise we set expectations to `nil`, which is not healthy
          `ls`

          stub_const('ENV', { "FASTLANE_WWDR_USE_HTTP1_AND_RETRIES" => "true" })

          keychain = "keychain with spaces.keychain"
          cmd = %r{curl --http1.1 --retry 3 --retry-all-errors -f -o (([A-Z]\:)?\/.+\.cer) https://www\.apple\.com/certificateauthority/AppleWWDRCAG6\.cer && security import \1 -k #{Regexp.escape(keychain.shellescape)}}
          require "open3"

          expect(Open3).to receive(:capture3).with(cmd).and_return(["", "", success_status])
          expect(FastlaneCore::CertChecker).to receive(:wwdr_keychain).and_return(keychain_name)

          allow(FastlaneCore::CertChecker).to receive(:installed_wwdr_certificates).and_return(['G2', 'G3', 'G4', 'G5', 'DEV-ID-G1', 'DEV-ID-G2'])
          expect(FastlaneCore::CertChecker.install_missing_wwdr_certificates).to be(1)
        end
      end
    end
  end
end
