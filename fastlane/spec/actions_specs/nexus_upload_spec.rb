describe Fastlane do
  describe Fastlane::FastFile do
    describe "Nexus Upload integration" do
      it "sets verbosity correctly" do
        expect(Fastlane::Actions::NexusUploadAction.verbose(verbose: true)).to eq("--verbose")
        expect(Fastlane::Actions::NexusUploadAction.verbose(verbose: false)).to eq("--silent")
      end

      it "sets upload url correctly for Nexus 2" do
        expect(Fastlane::Actions::NexusUploadAction.upload_url(endpoint: "http://localhost:8081",
          mount_path: "/nexus", nexus_version: 2)).to eq("http://localhost:8081/nexus/service/local/artifact/maven/content")
        expect(Fastlane::Actions::NexusUploadAction.upload_url(endpoint: "http://localhost:8081",
          mount_path: "/custom-nexus", nexus_version: 2)).to eq("http://localhost:8081/custom-nexus/service/local/artifact/maven/content")
        expect(Fastlane::Actions::NexusUploadAction.upload_url(endpoint: "http://localhost:8081",
          mount_path: "", nexus_version: 2)).to eq("http://localhost:8081/service/local/artifact/maven/content")
      end

      it "sets upload url correctly for Nexus 3 with all required parameters" do
        tmp_path = Dir.mktmpdir
        file_path = "#{tmp_path}/file.ipa"
        FileUtils.touch(file_path)

        expect(Fastlane::Actions::NexusUploadAction.upload_url(
                 endpoint: 'http://localhost:8081',
                   mount_path: '/nexus',
                   nexus_version: 3,
                 repo_id: 'artefacts',
                 repo_group_id: 'com.fastlane',
                 repo_project_name: 'myproject',
                 repo_project_version: '1.12',
                   file: file_path.to_s
               )).to eq("http://localhost:8081/nexus/repository/artefacts/com/fastlane/myproject/1.12/myproject-1.12.ipa")
      end

      it "sets upload url correctly for Nexus 3 with repo classifier" do
        tmp_path = Dir.mktmpdir
        file_path = "#{tmp_path}/file.ipa"
        FileUtils.touch(file_path)

        expect(Fastlane::Actions::NexusUploadAction.upload_url(
                 endpoint: 'http://localhost:8081',
                   mount_path: '/nexus',
                   nexus_version: 3,
                 repo_id: 'artefacts',
                 repo_group_id: 'com.fastlane',
                 repo_project_name: 'myproject',
                 repo_project_version: '1.12',
                   file: file_path.to_s,
                   repo_classifier: 'ipa'
               )).to eq("http://localhost:8081/nexus/repository/artefacts/com/fastlane/myproject/1.12/myproject-1.12-ipa.ipa")
      end

      it "sets upload options correctly for Nexus 2 with all required parameters" do
        tmp_path = Dir.mktmpdir
        file_path = "#{tmp_path}/file.ipa"
        FileUtils.touch(file_path)

        result = Fastlane::Actions::NexusUploadAction.upload_options(
          nexus_version: 2,
        repo_id: 'artefacts',
        repo_group_id: 'com.fastlane',
        repo_project_name: 'myproject',
        repo_project_version: '1.12',
          file: file_path.to_s,
                        username: 'admin',
                        password: 'admin123'
        )

        expect(result).to include('-F p=zip')
        expect(result).to include('-F hasPom=false')
        expect(result).to include('-F r=artefacts')
        expect(result).to include('-F g=com.fastlane')
        expect(result).to include('-F a=myproject')
        expect(result).to include('-F v=1.12')
        expect(result).to include('-F e=ipa')
        expect(result).to include("-F file=@#{file_path}")
        expect(result).to include('-u admin:admin123')
      end

      it "sets upload options correctly for Nexus 2 with repo classifier" do
        tmp_path = Dir.mktmpdir
        file_path = "#{tmp_path}/file.ipa"
        FileUtils.touch(file_path)

        result = Fastlane::Actions::NexusUploadAction.upload_options(
          nexus_version: 2,
        repo_id: 'artefacts',
        repo_group_id: 'com.fastlane',
        repo_project_name: 'myproject',
        repo_project_version: '1.12',
          file: file_path.to_s,
                        username: 'admin',
                        password: 'admin123',
                        repo_classifier: 'dSYM'
        )

        expect(result).to include('-F p=zip')
        expect(result).to include('-F hasPom=false')
        expect(result).to include('-F r=artefacts')
        expect(result).to include('-F g=com.fastlane')
        expect(result).to include('-F a=myproject')
        expect(result).to include('-F v=1.12')
        expect(result).to include('-F c=dSYM')
        expect(result).to include('-F e=ipa')
        expect(result).to include("-F file=@#{file_path}")
        expect(result).to include('-u admin:admin123')
      end

      it "sets upload options correctly for Nexus 3 with all required parameters" do
        tmp_path = Dir.mktmpdir
        file_path = "#{tmp_path}/file.ipa"
        FileUtils.touch(file_path)

        result = Fastlane::Actions::NexusUploadAction.upload_options(
          nexus_version: 3,
          file: file_path.to_s,
                        username: 'admin',
                        password: 'admin123'
        )

        expect(result).to include("--upload-file #{file_path}")
        expect(result).to include('-u admin:admin123')
      end

      it "sets ssl option correctly" do
        expect(Fastlane::Actions::NexusUploadAction.ssl_options(ssl_verify: false)).to eq(["--insecure"])
        expect(Fastlane::Actions::NexusUploadAction.ssl_options(ssl_verify: true)).to eq([])
      end

      it "sets proxy options correctly" do
        expect(Fastlane::Actions::NexusUploadAction.proxy_options(proxy_address: "",
          proxy_port: nil, proxy_username: nil, proxy_password: nil)).to eq([])
        expect(Fastlane::Actions::NexusUploadAction.proxy_options(proxy_address: nil,
          proxy_port: "", proxy_username: nil, proxy_password: nil)).to eq([])
        expect(Fastlane::Actions::NexusUploadAction.proxy_options(proxy_address: nil,
          proxy_port: nil, proxy_username: "", proxy_password: "")).to eq([])
        expect(Fastlane::Actions::NexusUploadAction.proxy_options(proxy_address: "http://1",
          proxy_port: "2", proxy_username: "3", proxy_password: "4")).to eq(["-x http://1:2", "--proxy-user 3:4"])
      end

      it "raises an error if file does not exist" do
        file_path = File.expand_path('/tmp/xfile.ipa')

        expect do
          result = Fastlane::FastFile.new.parse("lane :test do
            nexus_upload(file: '/tmp/xfile.ipa',
                        repo_id: 'artefacts',
                        repo_group_id: 'com.fastlane',
                        repo_project_name: 'myproject',
                        repo_project_version: '1.12',
                        endpoint: 'http://localhost:8081',
                        username: 'admin',
                        password: 'admin123',
                        verbose: true,
                        ssl_verify: false,
                        proxy_address: 'http://server',
                        proxy_port: '30',
                        proxy_username: 'admin',
                        proxy_password: 'admin')
          end").runner.execute(:test)
        end.to raise_exception("Couldn't find file at path '#{file_path}'")
      end

      it "uses mandatory options correctly" do
        tmp_path = Dir.mktmpdir
        file_path = "#{tmp_path}/file.ipa"
        FileUtils.touch(file_path)
        result = Fastlane::FastFile.new.parse("lane :test do
          nexus_upload(file: '#{file_path}',
                      repo_id: 'artefacts',
                      repo_group_id: 'com.fastlane',
                      repo_project_name: 'myproject',
                      repo_project_version: '1.12',
                      endpoint: 'http://localhost:8081',
                      username: 'admin',
                      password: 'admin123',
                      verbose: true,
                      ssl_verify: false,
                      proxy_address: 'http://server',
                      proxy_port: '30',
                      proxy_username: 'admin',
                      proxy_password: 'admin')
        end").runner.execute(:test)

        expect(result).to include('-F p=zip')
        expect(result).to include('-F hasPom=false')
        expect(result).to include('-F r=artefacts')
        expect(result).to include('-F g=com.fastlane')
        expect(result).to include('-F a=myproject')
        expect(result).to include('-F v=1.12')
        expect(result).to include('-F e=ipa')
        expect(result).to include("-F file=@#{tmp_path}")
        expect(result).to include('-u admin:admin123')
        expect(result).to include('--verbose')
        expect(result).to include('http://localhost:8081/nexus/service/local/artifact/maven/content')
        expect(result).to include('-x http://server:30')
        expect(result).to include('--proxy-user admin:admin')
        expect(result).to include('--insecure')
      end

      it "uses optional options correctly" do
        tmp_path = Dir.mktmpdir
        file_path = "#{tmp_path}/file.ipa"
        FileUtils.touch(file_path)
        result = Fastlane::FastFile.new.parse("lane :test do
          nexus_upload(file: '#{file_path}',
                      repo_id: 'artefacts',
                      repo_group_id: 'com.fastlane',
                      repo_project_name: 'myproject',
                      repo_project_version: '1.12',
                      repo_classifier: 'dSYM',
                      endpoint: 'http://localhost:8081',
                      mount_path: '/my-nexus',
                      username: 'admin',
                      password: 'admin123',
                      verbose: true)
        end").runner.execute(:test)

        expect(result).to include('-F p=zip')
        expect(result).to include('-F hasPom=false')
        expect(result).to include('-F r=artefacts')
        expect(result).to include('-F g=com.fastlane')
        expect(result).to include('-F a=myproject')
        expect(result).to include('-F v=1.12')
        expect(result).to include('-F c=dSYM')
        expect(result).to include('-F e=ipa')
        expect(result).to include("-F file=@#{file_path}")
        expect(result).to include('-u admin:admin123')
        expect(result).to include('--verbose')
        expect(result).to include('http://localhost:8081/my-nexus/service/local/artifact/maven/content')
        expect(result).not_to(include('-x '))
        expect(result).not_to(include('--proxy-user'))
      end

      it "runs the correct command for Nexus 3" do
        tmp_path = Dir.mktmpdir
        file_path = "#{tmp_path}/file.ipa"
        FileUtils.touch(file_path)
        result = Fastlane::FastFile.new.parse("lane :test do
          nexus_upload(file: '#{file_path}',
          nexus_version: 3,
                      repo_id: 'artefacts',
                      repo_group_id: 'com.fastlane',
                      repo_project_name: 'myproject',
                      repo_project_version: '1.12',
                      endpoint: 'http://localhost:8081',
                      username: 'admin',
                      password: 'admin123',
                      verbose: true,
                      ssl_verify: false,
                      proxy_address: 'http://server',
                      proxy_port: '30',
                      proxy_username: 'admin',
                      proxy_password: 'admin')
        end").runner.execute(:test)

        expect(result).to include("--upload-file #{tmp_path}")
        expect(result).to include('-u admin:admin123')
        expect(result).to include('--verbose')
        expect(result).to include('http://localhost:8081/nexus/repository/artefacts/com/fastlane/myproject/1.12/myproject-1.12.ipa')
        expect(result).to include('-x http://server:30')
        expect(result).to include('--proxy-user admin:admin')
        expect(result).to include('--insecure')
      end
    end
  end
end
