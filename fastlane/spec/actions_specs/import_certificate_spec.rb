describe Fastlane do
  describe Fastlane::FastFile do
    describe "Import certificate Integration" do
      before(:each) do
        allow(FastlaneCore::Helper).to receive(:backticks).with('security -h | grep set-key-partition-list', print: false).and_return('    set-key-partition-list               Set the partition list of a key.')
      end

      it "works with certificate and password" do
        cert_name = "test.cer"
        keychain = 'test.keychain'
        password = 'testpassword'

        keychain_path = File.expand_path(File.join('~', 'Library', 'Keychains', keychain))
        expected_command = "security import #{cert_name} -k '#{keychain_path}' -P #{password} -T /usr/bin/codesign -T /usr/bin/security &> /dev/null"

        # this command is also sent on macOS Sierra and we need to allow it or else the test will fail
        allowed_command = "security set-key-partition-list -S apple-tool:,apple: -k '' #{keychain_path.shellescape} &> /dev/null"

        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with(keychain_path).and_return(true)
        expect(File).to receive(:exist?).with(cert_name).and_return(true)
        allow(FastlaneCore::Helper).to receive(:backticks).with(allowed_command, print: false)
        expect(FastlaneCore::Helper).to receive(:backticks).with(expected_command, print: false)

        Fastlane::FastFile.new.parse("lane :test do
          import_certificate ({
            keychain_name: '#{keychain}',
            certificate_path: '#{cert_name}',
            certificate_password: '#{password}'
          })
        end").runner.execute(:test)
      end

      it "works with certificate and password that contain spaces, special chars, or '\'" do
        cert_name = '\" test \".cer'
        keychain = '\" test \".keychain'
        password = '\"test pa$$word\"'

        keychain_path = File.expand_path(File.join('~', 'Library', 'Keychains', keychain))
        expected_security_import_command = "security import #{cert_name.shellescape} -k '#{keychain_path.shellescape}' -P #{password.shellescape} -T /usr/bin/codesign -T /usr/bin/security &> /dev/null"

        # this command is also sent on macOS Sierra and we need to allow it or else the test will fail
        expected_set_key_partition_list_command = "security set-key-partition-list -S apple-tool:,apple: -k #{password.shellescape} #{keychain_path.shellescape} &> /dev/null"

        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with(keychain_path).and_return(true)
        expect(File).to receive(:exist?).with(cert_name).and_return(true)
        expect(FastlaneCore::Helper).to receive(:backticks).with(expected_set_key_partition_list_command, print: false)
        expect(FastlaneCore::Helper).to receive(:backticks).with(expected_security_import_command, print: false)

        Fastlane::FastFile.new.parse("lane :test do
          import_certificate ({
            keychain_name: '#{keychain}',
            keychain_password: '#{password}',
            certificate_path: '#{cert_name}',
            certificate_password: '#{password}'
          })
        end").runner.execute(:test)
      end

      it "works with a boolean for log_output" do
        cert_name = "test.cer"
        keychain = 'test.keychain'
        password = 'testpassword'

        keychain_path = File.expand_path(File.join('~', 'Library', 'Keychains', keychain))
        expected_command = "security import #{cert_name} -k '#{keychain_path}' -P #{password} -T /usr/bin/codesign -T /usr/bin/security"

        # this command is also sent on macOS Sierra and we need to allow it or else the test will fail
        allowed_command = "security set-key-partition-list -S apple-tool:,apple: -k '' #{keychain_path.shellescape}"

        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with(keychain_path).and_return(true)
        expect(File).to receive(:exist?).with(cert_name).and_return(true)
        allow(FastlaneCore::Helper).to receive(:backticks).with(allowed_command, print: true)
        expect(FastlaneCore::Helper).to receive(:backticks).with(expected_command, print: true)

        Fastlane::FastFile.new.parse("lane :test do
          import_certificate ({
            keychain_name: '#{keychain}',
            certificate_path: '#{cert_name}',
            certificate_password: '#{password}',
            log_output: true
          })
        end").runner.execute(:test)
      end
    end
  end
end
