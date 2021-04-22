require 'shellwords'
require 'credentials_manager'

describe FastlaneCore do
  let(:password) { "!> p@$s_-+=w'o%rd\"&#*<" }
  let(:email) { 'fabric.devtools@gmail.com' }
  let(:jwt) { '409jjl43j90ghjqoineio49024' }

  describe FastlaneCore::ItunesTransporter do
    def shell_upload_command(provider_short_name: nil, transporter: nil, jwt: nil)
      escaped_password = password.shellescape
      unless FastlaneCore::Helper.windows?
        escaped_password = escaped_password.gsub("\\'") do
          "'\"\\'\"'"
        end
        escaped_password = "'" + escaped_password + "'"
      end
      [
        '"' + FastlaneCore::Helper.transporter_path + '"',
        "-m upload",
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p #{escaped_password}" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        "-f \"/tmp/my.app.id.itmsp\"",
        (transporter.to_s if transporter),
        "-k 100000",
        ("-WONoPause true" if FastlaneCore::Helper.windows?),
        ("-itc_provider #{provider_short_name}" if provider_short_name)
      ].compact.join(' ')
    end

    def shell_download_command(provider_short_name = nil, jwt: nil)
      escaped_password = password.shellescape
      unless FastlaneCore::Helper.windows?
        escaped_password = escaped_password.gsub("\\'") do
          "'\"\\'\"'"
        end
        escaped_password = "'" + escaped_password + "'"
      end
      [
        '"' + FastlaneCore::Helper.transporter_path + '"',
        '-m lookupMetadata',
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p #{escaped_password}" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        "-apple_id my.app.id",
        "-destination '/tmp'",
        ("-itc_provider #{provider_short_name}" if provider_short_name)
      ].compact.join(' ')
    end

    def shell_provider_id_command(jwt: nil)
      # Ruby doesn't escape "+" with Shellwords.escape from 2.7 https://bugs.ruby-lang.org/issues/14429
      escaped_password = if RUBY_VERSION >= "2.7.0"
                           "'\\!\\>\\ p@\\$s_-+\\=w'\"\\'\"'o\\%rd\\\"\\&\\#\\*\\<'"
                         else
                           "'\\!\\>\\ p@\\$s_-\\+\\=w'\"\\'\"'o\\%rd\\\"\\&\\#\\*\\<'"
                         end
      [
        '"' + FastlaneCore::Helper.transporter_path + '"',
        "-m provider",
        ('-u "fabric.devtools@gmail.com"' if jwt.nil?),
        ("-p #{escaped_password}" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?)
      ].compact.join(' ')
    end

    def java_upload_command(provider_short_name: nil, transporter: nil, jwt: nil, classpath: true)
      [
        FastlaneCore::Helper.transporter_java_executable_path.shellescape,
        "-Djava.ext.dirs=#{FastlaneCore::Helper.transporter_java_ext_dir.shellescape}",
        '-XX:NewSize=2m',
        '-Xms32m',
        '-Xmx1024m',
        '-Xms1024m',
        '-Djava.awt.headless=true',
        '-Dsun.net.http.retryPost=false',
        ("-classpath #{FastlaneCore::Helper.transporter_java_jar_path.shellescape}" if classpath),
        ('com.apple.transporter.Application' if classpath),
        ("-jar #{FastlaneCore::Helper.transporter_java_jar_path.shellescape}" unless classpath),
        "-m upload",
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p #{password.shellescape}" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        "-f /tmp/my.app.id.itmsp",
        (transporter.to_s if transporter),
        "-k 100000",
        ("-itc_provider #{provider_short_name}" if provider_short_name),
        '2>&1'
      ].compact.join(' ')
    end

    def java_download_command(provider_short_name = nil, jwt: nil, classpath: true)
      [
        FastlaneCore::Helper.transporter_java_executable_path.shellescape,
        "-Djava.ext.dirs=#{FastlaneCore::Helper.transporter_java_ext_dir.shellescape}",
        '-XX:NewSize=2m',
        '-Xms32m',
        '-Xmx1024m',
        '-Xms1024m',
        '-Djava.awt.headless=true',
        '-Dsun.net.http.retryPost=false',
        ("-classpath #{FastlaneCore::Helper.transporter_java_jar_path.shellescape}" if classpath),
        ('com.apple.transporter.Application' if classpath),
        ("-jar #{FastlaneCore::Helper.transporter_java_jar_path.shellescape}" unless classpath),
        '-m lookupMetadata',
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p #{password.shellescape}" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        '-apple_id my.app.id',
        '-destination /tmp',
        ("-itc_provider #{provider_short_name}" if provider_short_name),
        '2>&1'
      ].compact.join(' ')
    end

    def java_provider_id_command(jwt: nil)
      [
        FastlaneCore::Helper.transporter_java_executable_path.shellescape,
        "-Djava.ext.dirs=#{FastlaneCore::Helper.transporter_java_ext_dir.shellescape}",
        '-XX:NewSize=2m',
        '-Xms32m',
        '-Xmx1024m',
        '-Xms1024m',
        '-Djava.awt.headless=true',
        '-Dsun.net.http.retryPost=false',
        "-classpath #{FastlaneCore::Helper.transporter_java_jar_path.shellescape}",
        'com.apple.transporter.Application',
        '-m provider',
        ('-u fabric.devtools@gmail.com' if jwt.nil?),
        ("-p #{password.shellescape}" if jwt.nil?),
        ("-jwt #{jwt}" if jwt),
        '2>&1'
      ].compact.join(' ')
    end

    def java_upload_command_9(provider_short_name: nil, transporter: nil, jwt: nil)
      [
        FastlaneCore::Helper.transporter_java_executable_path.shellescape,
        "-Djava.ext.dirs=#{FastlaneCore::Helper.transporter_java_ext_dir.shellescape}",
        '-XX:NewSize=2m',
        '-Xms32m',
        '-Xmx1024m',
        '-Xms1024m',
        '-Djava.awt.headless=true',
        '-Dsun.net.http.retryPost=false',
        "-jar #{FastlaneCore::Helper.transporter_java_jar_path.shellescape}",
        "-m upload",
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p #{password.shellescape}" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        "-f /tmp/my.app.id.itmsp",
        (transporter.to_s if transporter),
        "-k 100000",
        ("-itc_provider #{provider_short_name}" if provider_short_name),
        '2>&1'
      ].compact.join(' ')
    end

    def java_download_command_9(provider_short_name = nil, jwt: nil)
      [
        FastlaneCore::Helper.transporter_java_executable_path.shellescape,
        "-Djava.ext.dirs=#{FastlaneCore::Helper.transporter_java_ext_dir.shellescape}",
        '-XX:NewSize=2m',
        '-Xms32m',
        '-Xmx1024m',
        '-Xms1024m',
        '-Djava.awt.headless=true',
        '-Dsun.net.http.retryPost=false',
        "-jar #{FastlaneCore::Helper.transporter_java_jar_path.shellescape}",
        '-m lookupMetadata',
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p #{password.shellescape}" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        '-apple_id my.app.id',
        '-destination /tmp',
        ("-itc_provider #{provider_short_name}" if provider_short_name),
        '2>&1'
      ].compact.join(' ')
    end

    def xcrun_upload_command(provider_short_name: nil, transporter: nil, jwt: nil)
      [
        ("ITMS_TRANSPORTER_PASSWORD=#{password.shellescape}" if jwt.nil?),
        "xcrun iTMSTransporter",
        "-m upload",
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p @env:ITMS_TRANSPORTER_PASSWORD" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        "-f /tmp/my.app.id.itmsp",
        (transporter.to_s if transporter),
        "-k 100000",
        ("-itc_provider #{provider_short_name}" if provider_short_name),
        '2>&1'
      ].compact.join(' ')
    end

    def xcrun_download_command(provider_short_name = nil, jwt: nil)
      [
        ("ITMS_TRANSPORTER_PASSWORD=#{password.shellescape}" if jwt.nil?),
        "xcrun iTMSTransporter",
        '-m lookupMetadata',
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p @env:ITMS_TRANSPORTER_PASSWORD" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        '-apple_id my.app.id',
        '-destination /tmp',
        ("-itc_provider #{provider_short_name}" if provider_short_name),
        '2>&1'
      ].compact.join(' ')
    end

    describe "with Xcode 7.x installed" do
      before(:each) do
        allow(FastlaneCore::Helper).to receive(:xcode_version).and_return('7.3')
        allow(FastlaneCore::Helper).to receive(:mac?).and_return(true)
        allow(FastlaneCore::Helper).to receive(:windows?).and_return(false)
        allow(FastlaneCore::Helper).to receive(:itms_path).and_return('/tmp')
      end

      describe "by default" do
        describe "with username and password" do
          describe "upload command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command)
            end
          end

          describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set" do
            it 'generates a call to java directly' do
              FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: '-t DAV,Signiant') do
                transporter = FastlaneCore::ItunesTransporter.new(email, password)
                expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command(transporter: "-t DAV,Signiant"))
              end
            end
          end

          describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set to empty string" do
            it 'generates a call to java directly' do
              FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: ' ') do
                transporter = FastlaneCore::ItunesTransporter.new(email, password)
                expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command)
              end
            end
          end

          describe "download command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.download('my.app.id', '/tmp')).to eq(java_download_command)
            end
          end

          describe "provider ID command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new('fabric.devtools@gmail.com', "!> p@$s_-+=w'o%rd\"&#*<")
              expect(transporter.provider_ids).to eq(java_provider_id_command)
            end
          end
        end

        describe "with JWt" do
          describe "upload command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command(jwt: jwt))
            end
          end

          describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set" do
            it 'generates a call to java directly' do
              FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: '-t DAV,Signiant') do
                transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
                expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command(transporter: "-t DAV,Signiant", jwt: jwt))
              end
            end
          end

          describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set to empty string" do
            it 'generates a call to java directly' do
              FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: ' ') do
                transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
                expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command(jwt: jwt))
              end
            end
          end

          describe "download command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.download('my.app.id', '/tmp')).to eq(java_download_command(jwt: jwt))
            end
          end

          describe "provider ID command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.provider_ids).to eq(java_provider_id_command(jwt: jwt))
            end
          end
        end
      end

      describe "use_shell_script is false with a itc_provider short name set" do
        describe "with username and password" do
          describe "upload command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false, 'abcd1234')
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command(provider_short_name: 'abcd1234'))
            end
          end

          describe "download command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false, 'abcd1234')
              expect(transporter.download('my.app.id', '/tmp')).to eq(java_download_command('abcd1234'))
            end
          end

          describe "provider ID command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new('fabric.devtools@gmail.com', "!> p@$s_-+=w'o%rd\"&#*<")
              expect(transporter.provider_ids).to eq(java_provider_id_command)
            end
          end
        end

        describe "with JWT (ignores provider id)" do
          describe "upload command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, 'abcd1234', jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command(jwt: jwt))
            end
          end

          describe "download command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, 'abcd1234', jwt)
              expect(transporter.download('my.app.id', '/tmp')).to eq(java_download_command(jwt: jwt))
            end
          end
        end
      end

      describe "use_shell_script is true with a itc_provider short name set" do
        describe "with username and password" do
          describe "upload command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, true, 'abcd1234')
              expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command(provider_short_name: 'abcd1234'))
            end
          end

          describe "download command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, true, 'abcd1234')
              expect(transporter.download('my.app.id', '/tmp')).to eq(shell_download_command('abcd1234'))
            end
          end

          describe "provider ID command generation" do
            it 'generates a call to the shell script' do
              transporter = FastlaneCore::ItunesTransporter.new('fabric.devtools@gmail.com', "!> p@$s_-+=w'o%rd\"&#*<", true, 'abcd1234')
              expect(transporter.provider_ids).to eq(shell_provider_id_command)
            end
          end
        end

        describe "with JWT (ignores provider id)" do
          describe "upload command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, true, 'abcd1234', jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command(jwt: jwt))
            end
          end

          describe "download command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, true, 'abcd1234', jwt)
              expect(transporter.download('my.app.id', '/tmp')).to eq(shell_download_command(jwt: jwt))
            end
          end
        end
      end

      describe "when use shell script ENV var is set" do
        describe "upload command generation" do
          it 'generates a call to the shell script' do
            FastlaneSpec::Env.with_env_values('FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT' => 'true') do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command)
            end
          end
        end

        describe "download command generation" do
          it 'generates a call to the shell script' do
            FastlaneSpec::Env.with_env_values('FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT' => 'true') do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.download('my.app.id', '/tmp')).to eq(shell_download_command)
            end
          end
        end

        describe "provider ID command generation" do
          it 'generates a call to the shell script' do
            FastlaneSpec::Env.with_env_values('FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT' => 'true') do
              transporter = FastlaneCore::ItunesTransporter.new('fabric.devtools@gmail.com', "!> p@$s_-+=w'o%rd\"&#*<")
              expect(transporter.provider_ids).to eq(shell_provider_id_command)
            end
          end
        end
      end

      describe "use_shell_script is true" do
        describe "upload command generation" do
          it 'generates a call to the shell script' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password, true)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command)
          end
        end

        describe "download command generation" do
          it 'generates a call to the shell script' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password, true)
            expect(transporter.download('my.app.id', '/tmp')).to eq(shell_download_command)
          end
        end

        describe "provider ID command generation" do
          it 'generates a call to the shell script' do
            transporter = FastlaneCore::ItunesTransporter.new('fabric.devtools@gmail.com', "!> p@$s_-+=w'o%rd\"&#*<", true)
            expect(transporter.provider_ids).to eq(shell_provider_id_command)
          end
        end
      end

      describe "use_shell_script is false" do
        describe "upload command generation" do
          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command)
          end
        end

        describe "download command generation" do
          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
            expect(transporter.download('my.app.id', '/tmp')).to eq(java_download_command)
          end
        end

        describe "provider ID command generation" do
          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new('fabric.devtools@gmail.com', "!> p@$s_-+=w'o%rd\"&#*<", false)
            expect(transporter.provider_ids).to eq(java_provider_id_command)
          end
        end
      end
    end

    describe "with Xcode 6.x installed" do
      before(:each) do
        allow(FastlaneCore::Helper).to receive(:xcode_version).and_return('6.4')
        allow(FastlaneCore::Helper).to receive(:mac?).and_return(true)
        allow(FastlaneCore::Helper).to receive(:windows?).and_return(false)
        allow(FastlaneCore::Helper).to receive(:itms_path).and_return('/tmp')
      end

      describe "with username and password" do
        describe "upload command generation" do
          it 'generates a call to the shell script' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command)
          end
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set" do
          it 'generates a call to java directly' do
            FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: '-t DAV,Signiant') do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command(transporter: "-t DAV,Signiant"))
            end
          end
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set to empty string" do
          it 'generates a call to java directly' do
            FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: ' ') do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command)
            end
          end
        end

        describe "download command generation" do
          it 'generates a call to the shell script' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
            expect(transporter.download('my.app.id', '/tmp')).to eq(shell_download_command)
          end
        end

        describe "provider ID command generation" do
          it 'generates a call to the shell script' do
            transporter = FastlaneCore::ItunesTransporter.new('fabric.devtools@gmail.com', "!> p@$s_-+=w'o%rd\"&#*<", false)
            expect(transporter.provider_ids).to eq(shell_provider_id_command)
          end
        end
      end

      describe "with JWT" do
        describe "upload command generation" do
          it 'generates a call to the shell script' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command(jwt: jwt))
          end
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set" do
          it 'generates a call to java directly' do
            FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: '-t DAV,Signiant') do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command(transporter: "-t DAV,Signiant", jwt: jwt))
            end
          end
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set to empty string" do
          it 'generates a call to java directly' do
            FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: ' ') do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command(jwt: jwt))
            end
          end
        end

        describe "download command generation" do
          it 'generates a call to the shell script' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.download('my.app.id', '/tmp')).to eq(shell_download_command(jwt: jwt))
          end
        end

        describe "provider ID command generation" do
          it 'generates a call to the shell script' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.provider_ids).to eq(shell_provider_id_command(jwt: jwt))
          end
        end
      end
    end

    describe "with Xcode 9.x installed" do
      before(:each) do
        allow(FastlaneCore::Helper).to receive(:xcode_version).and_return('9.1')
        allow(FastlaneCore::Helper).to receive(:mac?).and_return(true)
        allow(FastlaneCore::Helper).to receive(:windows?).and_return(false)
        allow(FastlaneCore::Helper).to receive(:itms_path).and_return('/tmp')
      end

      describe "with username and password" do
        describe "upload command generation" do
          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command_9)
          end
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set" do
          it 'generates a call to java directly' do
            FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: '-t DAV,Signiant') do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command_9(transporter: "-t DAV,Signiant"))
            end
          end
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set with empty string" do
          it 'generates a call to java directly' do
            FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: ' ') do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command_9)
            end
          end
        end

        describe "download command generation" do
          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
            expect(transporter.download('my.app.id', '/tmp')).to eq(java_download_command_9)
          end
        end
      end

      describe "with JWT" do
        describe "upload command generation" do
          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command_9(jwt: jwt))
          end
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set" do
          it 'generates a call to java directly' do
            FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: '-t DAV,Signiant') do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command_9(transporter: "-t DAV,Signiant", jwt: jwt))
            end
          end
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set with empty string" do
          it 'generates a call to java directly' do
            FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: ' ') do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command_9(jwt: jwt))
            end
          end
        end

        describe "download command generation" do
          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.download('my.app.id', '/tmp')).to eq(java_download_command_9(jwt: jwt))
          end
        end
      end
    end

    describe "with Xcode 11.x installed" do
      before(:each) do
        allow(FastlaneCore::Helper).to receive(:xcode_version).and_return('11.1')
        allow(FastlaneCore::Helper).to receive(:mac?).and_return(true)
        allow(FastlaneCore::Helper).to receive(:windows?).and_return(false)
      end

      describe "with username and password" do
        describe "with default itms_path" do
          before(:each) do
            allow(FastlaneCore::Helper).to receive(:itms_path).and_return('/tmp')
            stub_const('ENV', { 'FASTLANE_ITUNES_TRANSPORTER_PATH' => nil })
          end

          describe "upload command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(xcrun_upload_command)
            end
          end

          describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set" do
            it 'generates a call to java directly' do
              FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: '-t DAV,Signiant') do
                transporter = FastlaneCore::ItunesTransporter.new(email, password)
                expect(transporter.upload('my.app.id', '/tmp')).to eq(xcrun_upload_command(transporter: "-t DAV,Signiant"))
              end
            end
          end

          describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set with empty string" do
            it 'generates a call to java directly' do
              FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: ' ') do
                transporter = FastlaneCore::ItunesTransporter.new(email, password)
                expect(transporter.upload('my.app.id', '/tmp')).to eq(xcrun_upload_command)
              end
            end
          end

          describe "download command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
              expect(transporter.download('my.app.id', '/tmp')).to eq(xcrun_download_command)
            end
          end
        end

        describe "with user defined itms_path" do
          before(:each) do
            stub_const('ENV', { 'FASTLANE_ITUNES_TRANSPORTER_PATH' => '/tmp' })
          end

          describe "upload command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command(classpath: false))
            end
          end

          describe "download command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
              expect(transporter.download('my.app.id', '/tmp')).to eq(java_download_command(classpath: false))
            end
          end
        end
      end

      describe "with JWT" do
        before(:each) do
          allow(FastlaneCore::Helper).to receive(:itms_path).and_return('/tmp')
          stub_const('ENV', { 'FASTLANE_ITUNES_TRANSPORTER_PATH' => nil })
        end

        describe "upload command generation" do
          it 'generates a call to xcrun iTMSTransporter' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(xcrun_upload_command(jwt: jwt))
          end
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set" do
          it 'generates a call to java directly' do
            FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: '-t DAV,Signiant') do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(xcrun_upload_command(transporter: "-t DAV,Signiant", jwt: jwt))
            end
          end
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set with empty string" do
          it 'generates a call to java directly' do
            FastlaneSpec::Env.with_env_values(DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS: ' ') do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(xcrun_upload_command(jwt: jwt))
            end
          end
        end

        describe "download command generation" do
          it 'generates a call to xcrun iTMSTransporter' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.download('my.app.id', '/tmp')).to eq(xcrun_download_command(jwt: jwt))
          end
        end
      end
    end

    describe "with `FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT` set" do
      around do |example|
        FastlaneSpec::Env.with_env_values(FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT: '1') do
          allow(File).to receive(:exist?).with("C:/Program Files (x86)/itms").and_return(true) if FastlaneCore::Helper.windows?
          example.run
        end
      end

      describe "upload command generation" do
        it 'generates a call to the shell script' do
          transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
          expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command)
        end
      end

      describe "download command generation" do
        it 'generates a call to the shell script' do
          transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
          expect(transporter.download('my.app.id', '/tmp')).to eq(shell_download_command)
        end
      end
    end

    describe "with no special configuration" do
      before(:each) do
        allow(File).to receive(:exist?).and_return(true) unless FastlaneCore::Helper.mac?
      end

      describe "upload command generation" do
        it 'generates the correct command' do
          transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
          command = java_upload_command
          # If we are on Windows, switch to shell script command
          command = shell_upload_command if FastlaneCore::Helper.windows?
          # If we are on Mac with Xcode 6.x, switch to shell script command
          command = shell_upload_command if FastlaneCore::Helper.is_mac? && FastlaneCore::Helper.xcode_version.start_with?('6.')
          # If we are on Mac with Xcode >= 9, switch to newer java command
          command = java_upload_command_9 if FastlaneCore::Helper.is_mac? && FastlaneCore::Helper.xcode_at_least?(9)
          # If we are on Mac with Xcode >= 11, switch to xcrun command
          command = xcrun_upload_command if FastlaneCore::Helper.is_mac? && FastlaneCore::Helper.xcode_at_least?(11)
          expect(transporter.upload('my.app.id', '/tmp')).to eq(command)
        end
      end

      describe "download command generation" do
        it 'generates the correct command' do
          transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
          command = java_download_command
          # If we are on Windows, switch to shell script command
          command = shell_download_command if FastlaneCore::Helper.windows?
          # If we are on Mac with Xcode 6.x, switch to shell script command
          command = shell_download_command if FastlaneCore::Helper.is_mac? && FastlaneCore::Helper.xcode_version.start_with?('6.')
          # If we are on Mac with Xcode >= 9, switch to newer java command
          command = java_download_command_9 if FastlaneCore::Helper.is_mac? && FastlaneCore::Helper.xcode_at_least?(9)
          # If we are on Mac with Xcode >= 11, switch to newer xcrun command
          command = xcrun_download_command if FastlaneCore::Helper.is_mac? && FastlaneCore::Helper.xcode_at_least?(11)
          expect(transporter.download('my.app.id', '/tmp')).to eq(command)
        end
      end
    end

    describe "with upload error" do
      before(:each) do
        allow(FastlaneCore::Helper).to receive(:xcode_version).and_return('11.1')
        allow(FastlaneCore::Helper).to receive(:mac?).and_return(true)
        allow(FastlaneCore::Helper).to receive(:windows?).and_return(false)

        allow(FastlaneCore::Helper).to receive(:itms_path).and_return('/tmp')
        stub_const('ENV', { 'FASTLANE_ITUNES_TRANSPORTER_PATH' => nil })
      end

      describe "retries when TransporterRequiresApplicationSpecificPasswordError" do
        it "with app_id and dir" do
          transporter = FastlaneCore::ItunesTransporter.new(email, password, false)

          # Raise error once to test retry
          expect_any_instance_of(FastlaneCore::JavaTransporterExecutor).to receive(:execute).once.and_raise(FastlaneCore::TransporterRequiresApplicationSpecificPasswordError)
          expect(transporter).to receive(:handle_two_step_failure)

          # Call original implementation to undo above expect
          expect_any_instance_of(FastlaneCore::JavaTransporterExecutor).to receive(:execute).and_call_original

          expect(transporter.upload('my.app.id', '/tmp')).to eq(xcrun_upload_command)
        end

        it "with package_path" do
          transporter = FastlaneCore::ItunesTransporter.new(email, password, false)

          # Raise error once to test retry
          expect_any_instance_of(FastlaneCore::JavaTransporterExecutor).to receive(:execute).once.and_raise(FastlaneCore::TransporterRequiresApplicationSpecificPasswordError)
          expect(transporter).to receive(:handle_two_step_failure)

          # Call original implementation to undo above expect
          expect_any_instance_of(FastlaneCore::JavaTransporterExecutor).to receive(:execute).and_call_original

          expect(transporter.upload(package_path: '/tmp/my.app.id.itmsp')).to eq(xcrun_upload_command)
        end
      end
    end

    describe "with simulated no-test environment" do
      before(:each) do
        allow(FastlaneCore::Helper).to receive(:test?).and_return(false)
        @transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
      end

      describe "and faked command execution" do
        it 'handles successful execution with no errors' do
          expect(FastlaneCore::FastlanePty).to receive(:spawn).and_return(0)
          expect(@transporter.upload('my.app.id', '/tmp')).to eq(true)
        end

        it 'handles exceptions' do
          expect(FastlaneCore::FastlanePty).to receive(:spawn).and_raise(StandardError, "It's all broken now.")
          expect(@transporter.upload('my.app.id', '/tmp')).to eq(false)
        end
      end
    end
  end
end
