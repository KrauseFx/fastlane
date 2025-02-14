require 'shellwords'
require 'credentials_manager'

describe FastlaneCore do
  let(:password) { "!> p@$s_-+=w'o%rd\"&#*<" }
  let(:email) { 'fabric.devtools@gmail.com' }
  let(:jwt) { '409jjl43j90ghjqoineio49024' }
  let(:api_key) { { key_id: "TESTAPIK2HW", issuer_id: "11223344-1122-aabb-aabb-uuvvwwxxyyzz" } }

  describe FastlaneCore::ItunesTransporter do
    let(:random_uuid) { '2a912f38-5dbc-4fc3-a5b3-1bf184b2b021' }
    before(:each) do
      allow(SecureRandom).to receive(:uuid).and_return(random_uuid)
    end

    def shell_upload_command(provider_short_name: nil, transporter: nil, jwt: nil, use_asset_path: false, username: email, input_pass: password, api_key: nil)
      upload_part = use_asset_path ? "-assetFile /tmp/#{random_uuid}.ipa" : "-f /tmp/my.app.id.itmsp"

      username = username if username != email
      escaped_password = input_pass != password ? input_pass : password
      unless escaped_password.nil?
        escaped_password = escaped_password.shellescape
        unless FastlaneCore::Helper.windows?
          escaped_password = escaped_password.gsub("\\'") do
            "'\"\\'\"'"
          end
          escaped_password = "'" + escaped_password + "'"
        end
      end
      [
        '"' + FastlaneCore::Helper.transporter_path + '"',
        "-m upload",
        (if jwt.nil?
           if api_key.nil?
             if username.nil? || escaped_password.nil?
               nil
             else
               "-u #{username.shellescape} -p #{escaped_password}"
             end
           else
             "-apiIssuer #{api_key[:issuer_id]} -apiKey #{api_key[:key_id]}"
           end
         else
           "-jwt #{jwt}"
         end),
        upload_part,
        (transporter.to_s if transporter),
        "-k 100000",
        ("-WONoPause true" if FastlaneCore::Helper.windows?),
        ("-itc_provider #{provider_short_name}" if provider_short_name)
      ].compact.join(' ')
    end

    def shell_verify_command(provider_short_name: nil, transporter: nil, jwt: nil)
      escaped_password = password.shellescape
      unless FastlaneCore::Helper.windows?
        escaped_password = escaped_password.gsub("\\'") do
          "'\"\\'\"'"
        end
        escaped_password = "'" + escaped_password + "'"
      end
      [
        '"' + FastlaneCore::Helper.transporter_path + '"',
        "-m verify",
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p #{escaped_password}" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        "-f /tmp/my.app.id.itmsp",
        (transporter.to_s if transporter),
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

    def altool_upload_command(api_key: nil, platform: "macos", provider_short_name: "")
      use_api_key = !api_key.nil?
      upload_part = "-f /tmp/my.app.id.itmsp"
      escaped_password = password.shellescape

      [
        "xcrun altool",
        "--upload-app",
        ("-u #{email.shellescape}" unless use_api_key),
        ("-p #{escaped_password}" unless use_api_key),
        ("--apiKey #{api_key[:key_id]}" if use_api_key),
        ("--apiIssuer #{api_key[:issuer_id]}" if use_api_key),
        ("--asc-provider #{provider_short_name}" unless use_api_key || provider_short_name.to_s.empty?),
        ("-t #{platform}"),
        upload_part,
        "-k 100000"
      ].compact.join(' ')
    end

    def altool_provider_id_command(api_key: nil)
      use_api_key = !api_key.nil?
      escaped_password = password.shellescape

      [
        "xcrun altool",
        "--list-providers",
        ("-u #{email.shellescape}" unless use_api_key),
        ("-p #{escaped_password}" unless use_api_key),
        ("--apiKey #{api_key[:key_id]}" if use_api_key),
        ("--apiIssuer #{api_key[:issuer_id]}" if use_api_key),
        "--output-format json"
      ].compact.join(' ')
    end

    def java_upload_command(provider_short_name: nil, transporter: nil, jwt: nil, classpath: true, use_asset_path: false)
      upload_part = use_asset_path ? "-assetFile /tmp/#{random_uuid}.ipa" : "-f /tmp/my.app.id.itmsp"

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
        upload_part,
        (transporter.to_s if transporter),
        "-k 100000",
        ("-itc_provider #{provider_short_name}" if provider_short_name),
        '2>&1'
      ].compact.join(' ')
    end

    def java_verify_command(provider_short_name: nil, transporter: nil, jwt: nil, classpath: true)
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
        "-m verify",
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p #{password.shellescape}" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        "-f /tmp/my.app.id.itmsp",
        (transporter.to_s if transporter),
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

    def java_upload_command_9(provider_short_name: nil, transporter: nil, jwt: nil, use_asset_path: false)
      upload_part = use_asset_path ? "-assetFile /tmp/#{random_uuid}.ipa" : "-f /tmp/my.app.id.itmsp"

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
        upload_part,
        (transporter.to_s if transporter),
        "-k 100000",
        ("-itc_provider #{provider_short_name}" if provider_short_name),
        '2>&1'
      ].compact.join(' ')
    end

    def java_verify_command_9(provider_short_name: nil, transporter: nil, jwt: nil)
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
        "-m verify",
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p #{password.shellescape}" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        "-f /tmp/my.app.id.itmsp",
        (transporter.to_s if transporter),
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

    def xcrun_upload_command(provider_short_name: nil, transporter: nil, jwt: nil, use_asset_path: false)
      upload_part = use_asset_path ? "-assetFile /tmp/#{random_uuid}.ipa" : "-f /tmp/my.app.id.itmsp"

      [
        ("ITMS_TRANSPORTER_PASSWORD=#{password.shellescape}" if jwt.nil?),
        "xcrun iTMSTransporter",
        "-m upload",
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p @env:ITMS_TRANSPORTER_PASSWORD" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        upload_part,
        (transporter.to_s if transporter),
        "-k 100000",
        ("-itc_provider #{provider_short_name}" if provider_short_name),
        '2>&1'
      ].compact.join(' ')
    end

    def xcrun_verify_command(transporter: nil, jwt: nil)
      [
        ("ITMS_TRANSPORTER_PASSWORD=#{password.shellescape}" if jwt.nil?),
        "xcrun iTMSTransporter",
        "-m verify",
        ("-u #{email.shellescape}" if jwt.nil?),
        ("-p @env:ITMS_TRANSPORTER_PASSWORD" if jwt.nil?),
        ("-jwt #{jwt}" unless jwt.nil?),
        "-f /tmp/my.app.id.itmsp",
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
            before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = "-t DAV,Signiant" }

            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command(transporter: "-t DAV,Signiant"))
            end

            after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
          end

          describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set to empty string" do
            before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = " " }

            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command)
            end

            after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
          end

          describe "verify command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.verify('my.app.id', '/tmp')).to eq(java_verify_command)
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
            before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = "-t DAV,Signiant" }

            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command(transporter: "-t DAV,Signiant", jwt: jwt))
            end

            after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
          end

          describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set to empty string" do
            before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = " " }

            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command(jwt: jwt))
            end

            after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
          end

          describe "verify command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.verify('my.app.id', '/tmp')).to eq(java_verify_command(jwt: jwt))
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

          describe "with package_path" do
            describe "upload command generation" do
              it 'generates a call to xcrun iTMSTransporter' do
                transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
                expect(transporter.upload(package_path: '/tmp/my.app.id.itmsp')).to eq(java_upload_command(jwt: jwt))
              end
            end

            describe "verify command generation" do
              it 'generates a call to xcrun iTMSTransporter' do
                transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
                expect(transporter.verify(package_path: '/tmp/my.app.id.itmsp')).to eq(java_verify_command(jwt: jwt))
              end
            end
          end

          describe "with asset_path" do
            describe "upload command generation" do
              it 'generates a call to xcrun iTMSTransporter' do
                expect(Dir).to receive(:tmpdir).and_return("/tmp")
                expect(FileUtils).to receive(:cp)

                transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
                expect(transporter.upload(asset_path: '/tmp/my_app.ipa')).to eq(java_upload_command(jwt: jwt, use_asset_path: true))
              end
            end
          end

          describe "with package_path and asset_path" do
            describe "upload command generation" do
              it 'generates a call to xcrun iTMSTransporter with -assetFile' do
                expect(Dir).to receive(:tmpdir).and_return("/tmp")
                expect(FileUtils).to receive(:cp)

                transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
                expect(transporter.upload(package_path: '/tmp/my.app.id.itmsp', asset_path: '/tmp/my_app.ipa')).to eq(java_upload_command(jwt: jwt, use_asset_path: true))
              end
            end

            describe "upload command generation with ITMSTRANSPORTER_FORCE_ITMS_PACKAGE_UPLOAD=true" do
              it 'generates a call to xcrun iTMSTransporter with -assetFile' do
                stub_const('ENV', { 'ITMSTRANSPORTER_FORCE_ITMS_PACKAGE_UPLOAD' => 'true' })

                transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
                expect(transporter.upload(package_path: '/tmp/my.app.id.itmsp', asset_path: '/tmp/my_app.ipa')).to eq(java_upload_command(jwt: jwt, use_asset_path: false))
              end
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

          describe "verify command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false, 'abcd1234')
              expect(transporter.verify('my.app.id', '/tmp')).to eq(java_verify_command(provider_short_name: 'abcd1234'))
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

          describe "verify command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, 'abcd1234', jwt)
              expect(transporter.verify('my.app.id', '/tmp')).to eq(java_verify_command(jwt: jwt))
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

          describe "verify command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, true, 'abcd1234')
              expect(transporter.verify('my.app.id', '/tmp')).to eq(shell_verify_command(provider_short_name: 'abcd1234'))
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

          describe "verify command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, true, 'abcd1234', jwt)
              expect(transporter.verify('my.app.id', '/tmp')).to eq(shell_verify_command(jwt: jwt))
            end
          end

          describe "download command generation" do
            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, true, 'abcd1234', jwt)
              expect(transporter.download('my.app.id', '/tmp')).to eq(shell_download_command(jwt: jwt))
            end
          end

          describe "with package_path" do
            describe "upload command generation" do
              it 'generates a call to xcrun iTMSTransporter' do
                transporter = FastlaneCore::ItunesTransporter.new(nil, nil, true, 'abcd1234', jwt)
                expect(transporter.upload(package_path: '/tmp/my.app.id.itmsp')).to eq(shell_upload_command(jwt: jwt))
              end
            end

            describe "verify command generation" do
              it 'generates a call to xcrun iTMSTransporter' do
                transporter = FastlaneCore::ItunesTransporter.new(nil, nil, true, 'abcd1234', jwt)
                expect(transporter.verify(package_path: '/tmp/my.app.id.itmsp')).to eq(shell_verify_command(jwt: jwt))
              end
            end
          end

          describe "with asset_path" do
            describe "upload command generation" do
              it 'generates a call to xcrun iTMSTransporter' do
                expect(Dir).to receive(:tmpdir).and_return("/tmp")
                expect(FileUtils).to receive(:cp)

                transporter = FastlaneCore::ItunesTransporter.new(nil, nil, true, 'abcd1234', jwt)
                expect(transporter.upload(asset_path: '/tmp/my_app.ipa')).to eq(shell_upload_command(jwt: jwt, use_asset_path: true))
              end
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

        describe "verify command generation" do
          it 'generates a call to the shell script' do
            FastlaneSpec::Env.with_env_values('FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT' => 'true') do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.verify('my.app.id', '/tmp')).to eq(shell_verify_command)
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

        describe "verify command generation" do
          it 'generates a call to the shell script' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password, true)
            expect(transporter.verify('my.app.id', '/tmp')).to eq(shell_verify_command)
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

        describe "verify command generation" do
          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
            expect(transporter.verify('my.app.id', '/tmp')).to eq(java_verify_command)
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
          before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = "-t DAV,Signiant" }

          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command(transporter: "-t DAV,Signiant"))
          end

          after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set to empty string" do
          before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = " " }

          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command)
          end

          after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
        end

        describe "verify command generation" do
          it 'generates a call to the shell script' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
            expect(transporter.verify('my.app.id', '/tmp')).to eq(shell_verify_command)
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
          before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = "-t DAV,Signiant" }

          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command(transporter: "-t DAV,Signiant", jwt: jwt))
          end

          after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set to empty string" do
          before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = " " }

          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command(jwt: jwt))
          end

          after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
        end

        describe "verify command generation" do
          it 'generates a call to the shell script' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.verify('my.app.id', '/tmp')).to eq(shell_verify_command(jwt: jwt))
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
          before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = "-t DAV,Signiant" }

          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command_9(transporter: "-t DAV,Signiant"))
          end

          after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set with empty string" do
          before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = " " }

          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command_9)
          end

          after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
        end

        describe "verify command generation" do
          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
            expect(transporter.verify('my.app.id', '/tmp')).to eq(java_verify_command_9)
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
          before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = "-t DAV,Signiant" }

          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command_9(transporter: "-t DAV,Signiant", jwt: jwt))
          end

          after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
        end

        describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set with empty string" do
          before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = " " }

          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.upload('my.app.id', '/tmp')).to eq(java_upload_command_9(jwt: jwt))
          end

          after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
        end

        describe "verify command generation" do
          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.verify('my.app.id', '/tmp')).to eq(java_verify_command_9(jwt: jwt))
          end
        end

        describe "download command generation" do
          it 'generates a call to java directly' do
            transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
            expect(transporter.download('my.app.id', '/tmp')).to eq(java_download_command_9(jwt: jwt))
          end
        end

        describe "with package_path" do
          before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = " " }

          describe "upload command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload(package_path: '/tmp/my.app.id.itmsp')).to eq(java_upload_command_9(jwt: jwt))
            end
          end
        end

        describe "with asset_path" do
          before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = " " }

          describe "upload command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              expect(Dir).to receive(:tmpdir).and_return("/tmp")
              expect(FileUtils).to receive(:cp)

              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload(asset_path: '/tmp/my_app.ipa')).to eq(java_upload_command_9(jwt: jwt, use_asset_path: true))
            end
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
            before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = "-t DAV,Signiant" }

            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(xcrun_upload_command(transporter: "-t DAV,Signiant"))
            end

            after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
          end

          describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set with empty string" do
            before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = " " }

            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(xcrun_upload_command)
            end

            after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
          end

          describe "verify command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
              expect(transporter.verify('my.app.id', '/tmp')).to eq(xcrun_verify_command)
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

          describe "verify command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
              expect(transporter.verify('my.app.id', '/tmp')).to eq(java_verify_command(classpath: false))
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

        describe "with app_id and dir" do
          describe "upload command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(xcrun_upload_command(jwt: jwt))
            end
          end

          describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set" do
            before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = "-t DAV,Signiant" }

            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(xcrun_upload_command(transporter: "-t DAV,Signiant", jwt: jwt))
            end

            after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
          end

          describe "upload command generation with DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS set with empty string" do
            before(:each) { ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"] = " " }

            it 'generates a call to java directly' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload('my.app.id', '/tmp')).to eq(xcrun_upload_command(jwt: jwt))
            end

            after(:each) { ENV.delete("DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS") }
          end

          describe "verify command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.verify('my.app.id', '/tmp')).to eq(xcrun_verify_command(jwt: jwt))
            end
          end

          describe "download command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.download('my.app.id', '/tmp')).to eq(xcrun_download_command(jwt: jwt))
            end
          end
        end

        describe "with package_path" do
          describe "upload command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload(package_path: '/tmp/my.app.id.itmsp')).to eq(xcrun_upload_command(jwt: jwt))
            end
          end

          describe "verify command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.verify(package_path: '/tmp/my.app.id.itmsp')).to eq(xcrun_verify_command(jwt: jwt))
            end
          end
        end

        describe "with asset_path" do
          describe "upload command generation" do
            it 'generates a call to xcrun iTMSTransporter' do
              expect(Dir).to receive(:tmpdir).and_return("/tmp")
              expect(FileUtils).to receive(:cp)

              transporter = FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, jwt)
              expect(transporter.upload(asset_path: '/tmp/my_app.ipa')).to eq(xcrun_upload_command(jwt: jwt, use_asset_path: true))
            end
          end
        end
      end
    end

    context "with Xcode 14.x installed" do
      before(:each) do
        allow(FastlaneCore::Helper).to receive(:xcode_version).and_return('14.0')
        allow(FastlaneCore::Helper).to receive(:mac?).and_return(true)
        allow(FastlaneCore::Helper).to receive(:windows?).and_return(false)
      end

      context "with username and password" do
        context "with default itms_path" do
          before(:each) do
            allow(FastlaneCore::Helper).to receive(:itms_path).and_return(nil)
            stub_const('ENV', { 'FASTLANE_ITUNES_TRANSPORTER_PATH' => nil })
          end
          context "upload command generation" do
            it 'generates a call to altool' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false, 'abcd123', altool_compatible_command: true)
              expect(transporter.upload('my.app.id', '/tmp', package_path: '/tmp/my.app.id.itmsp', platform: "osx")).to eq(altool_upload_command(provider_short_name: 'abcd123'))
            end
          end

          context "provider IDs command generation" do
            it 'generates a call to altool' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false, 'abcd123', altool_compatible_command: true)
              expect(transporter.provider_ids).to eq(altool_provider_id_command)
            end
          end
        end

        context "with user defined itms_path" do
          before(:each) do
            allow(FastlaneCore::Helper).to receive(:itms_path).and_return('/tmp')
            stub_const('ENV', { 'FASTLANE_ITUNES_TRANSPORTER_PATH' => '/tmp' })
          end
          context "upload command generation" do
            it 'generates a call to xcrun iTMSTransporter instead altool' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false, 'abcd123', altool_compatible_command: true)
              expect(transporter.upload('my.app.id', '/tmp', platform: "osx")).to eq(java_upload_command(provider_short_name: 'abcd123', classpath: false))
            end
          end
        end

        after(:each) { ENV.delete("FASTLANE_ITUNES_TRANSPORTER_PATH") }
      end

      context "with api_key" do
        context "with default itms_path" do
          before(:each) do
            allow(FastlaneCore::Helper).to receive(:itms_path).and_return(nil)
            stub_const('ENV', { 'FASTLANE_ITUNES_TRANSPORTER_PATH' => nil })
          end
          context "upload command generation" do
            it 'generates a call to altool' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false, 'abcd123', altool_compatible_command: true, api_key: api_key)
              expected = Regexp.new("API_PRIVATE_KEYS_DIR=#{Regexp.escape(Dir.tmpdir)}.*\s#{Regexp.escape(altool_upload_command(api_key: api_key, provider_short_name: 'abcd123'))}")
              expect(transporter.upload('my.app.id', '/tmp', platform: "osx")).to match(expected)
            end
          end

          context "provider IDs command generation" do
            it 'generates a call to altool' do
              transporter = FastlaneCore::ItunesTransporter.new(email, password, false, 'abcd123', altool_compatible_command: true, api_key: api_key)
              expected = Regexp.new("API_PRIVATE_KEYS_DIR=#{Regexp.escape(Dir.tmpdir)}.*\s#{Regexp.escape(altool_provider_id_command(api_key: api_key))}")
              expect(transporter.provider_ids).to match(expected)
            end
          end
        end
      end
    end

    describe "with `FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT` set" do
      before(:each) do
        ENV["FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT"] = "1"
        allow(FastlaneCore::Helper).to receive(:itms_path).and_return('/tmp')
        allow(File).to receive(:exist?).with("C:/Program Files (x86)/itms").and_return(true) if FastlaneCore::Helper.windows?
      end

      describe "upload command generation" do
        let(:keys_parent_dir) { File.join(Dir.home, ".appstoreconnect") }

        it 'generates a call to the shell script with user and password' do
          transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
          expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command)
        end

        it 'generates a call to the shell script with api key' do
          transporter = FastlaneCore::ItunesTransporter.new(api_key: api_key)
          expect(transporter.upload('my.app.id', '/tmp')).to eq(shell_upload_command(username: nil, input_pass: nil, api_key: api_key))
          expect(Dir.empty?(keys_parent_dir)).to be_truthy if Dir.exist?(keys_parent_dir)
        end
      end

      describe "verify command generation" do
        it 'generates a call to the shell script' do
          transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
          expect(transporter.verify('my.app.id', '/tmp')).to eq(shell_verify_command)
        end
      end

      describe "download command generation" do
        it 'generates a call to the shell script' do
          transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
          expect(transporter.download('my.app.id', '/tmp')).to eq(shell_download_command)
        end
      end

      after(:each) { ENV.delete("FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT") }
    end

    describe "with no special configuration" do
      before(:each) do
        allow(FastlaneCore::Helper).to receive(:itms_path).and_return('/tmp')
        allow(File).to receive(:exist?).and_return(true) unless FastlaneCore::Helper.mac?
        ENV.delete("FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT")
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

      describe "verify command generation" do
        it 'generates the correct command' do
          transporter = FastlaneCore::ItunesTransporter.new(email, password, false)
          command = java_verify_command
          # If we are on Windows, switch to shell script command
          command = shell_verify_command if FastlaneCore::Helper.windows?
          # If we are on Mac with Xcode 6.x, switch to shell script command
          command = shell_verify_command if FastlaneCore::Helper.is_mac? && FastlaneCore::Helper.xcode_version.start_with?('6.')
          # If we are on Mac with Xcode >= 9, switch to newer java command
          command = java_verify_command_9 if FastlaneCore::Helper.is_mac? && FastlaneCore::Helper.xcode_at_least?(9)
          # If we are on Mac with Xcode >= 11, switch to xcrun command
          command = xcrun_verify_command if FastlaneCore::Helper.is_mac? && FastlaneCore::Helper.xcode_at_least?(11)
          expect(transporter.verify('my.app.id', '/tmp')).to eq(command)
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

    describe "with verify error" do
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

          expect(transporter.verify('my.app.id', '/tmp')).to eq(xcrun_verify_command)
        end

        it "with package_path" do
          transporter = FastlaneCore::ItunesTransporter.new(email, password, false)

          # Raise error once to test retry
          expect_any_instance_of(FastlaneCore::JavaTransporterExecutor).to receive(:execute).once.and_raise(FastlaneCore::TransporterRequiresApplicationSpecificPasswordError)
          expect(transporter).to receive(:handle_two_step_failure)

          # Call original implementation to undo above expect
          expect_any_instance_of(FastlaneCore::JavaTransporterExecutor).to receive(:execute).and_call_original

          expect(transporter.verify(package_path: '/tmp/my.app.id.itmsp')).to eq(xcrun_verify_command)
        end
      end
    end

    describe "with simulated no-test environment" do
      before(:each) do
        allow(FastlaneCore::Helper).to receive(:test?).and_return(false)
        allow(FastlaneCore::Helper).to receive(:itms_path).and_return('/tmp')
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

  describe FastlaneCore::AltoolTransporterExecutor do
    let(:upload_cmd) { "xcrun altool --upload-app --apiKey #{api_key[:key_id]} --apiIssuer #{api_key[:issuer_id]} -t macos -f /tmp/my.app.id.itmsp -k 100000" }
    let(:instance) { described_class.new }
    describe "#execute" do
      it "logs specific info about altool crash if exit code is -1" do
        # remove test behavior, we actually want FastlanePty.spawn to be called here
        allow(FastlaneCore::Helper).to receive(:test?).and_return(false)
        # force the nil return of FastlanePty.spawn
        allow(FastlaneCore::FastlanePty).to receive(:spawn).and_return(-1)
        expect(instance.execute(upload_cmd, false)).to eq(false)
        expect(instance.errors).to include(
          "-1 indicates altool exited abnormally; try retrying (see https://github.com/fastlane/fastlane/issues/21535)"
        )
      end
    end
  end
end
