describe Match do
  describe Match::Storage::GitStorage do
    describe "#generate_commit_message" do
      [["tools.fastlane.com"], ["tools.fastlane.com", "tools.fastlane.com.extension"]].each do |identifiers|
        context "With identifiers #{identifiers}" do
          it "works" do
            storage = Match::Storage::GitStorage.new(
              type: "appstore",
              platform: "ios",
              identifiers: identifiers
            )
            result = storage.generate_commit_message
            expect(result).to eq("[fastlane] Updated appstore and platform ios for identifier(s) #{identifiers.join(', ')}")
          end
        end
      end
    end

    describe "#download" do
      it "clones the repo" do
        path = Dir.mktmpdir # to have access to the actual path
        expect(Dir).to receive(:mktmpdir).and_return(path)
        git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
        git_branch = "master"
        shallow_clone = true

        expected_commands = [
          "git clone #{git_url.shellescape} #{path.shellescape} --depth 1 --no-single-branch",
          "git --no-pager branch --list origin/#{git_branch} --no-color -r",
          "git checkout --orphan #{git_branch}",
          "git reset --hard"
        ]
        expected_commands.each do |command|
          expect(FastlaneCore::CommandExecutor).to receive(:execute).once.with({
            command: command,
            print_all: nil,
            print_command: nil
          }).and_return("")
        end

        storage = Match::Storage::GitStorage.new(
          git_url: git_url,
          shallow_clone: shallow_clone
        )
        storage.download

        expect(File.directory?(storage.working_directory)).to eq(true)
        expect(File.exist?(File.join(storage.working_directory, 'README.md'))).to eq(false) # because the README is being added when committing the changes
      end

      it "clones the repo (not shallow)" do
        path = Dir.mktmpdir # to have access to the actual path
        expect(Dir).to receive(:mktmpdir).and_return(path)
        git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
        git_branch = "master"
        shallow_clone = false

        expected_commands = [
          "git clone #{git_url.shellescape} #{path.shellescape}",
          "git --no-pager branch --list origin/#{git_branch} --no-color -r",
          "git checkout --orphan #{git_branch}",
          "git reset --hard"
        ]
        expected_commands.each do |command|
          expect(FastlaneCore::CommandExecutor).to receive(:execute).once.with({
            command: command,
            print_all: nil,
            print_command: nil
          }).and_return("")
        end

        storage = Match::Storage::GitStorage.new(
          git_url: git_url,
          shallow_clone: shallow_clone
        )
        storage.download

        expect(File.directory?(storage.working_directory)).to eq(true)
        expect(File.exist?(File.join(storage.working_directory, 'README.md'))).to eq(false) # because the README is being added when committing the changes
      end

      it "checks out a branch" do
        path = Dir.mktmpdir # to have access to the actual path
        expect(Dir).to receive(:mktmpdir).and_return(path)
        git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
        git_branch = "test"
        shallow_clone = false

        expected_commands = [
          "git clone #{git_url.shellescape} #{path.shellescape}",
          "git --no-pager branch --list origin/#{git_branch} --no-color -r",
          "git checkout --orphan #{git_branch}",
          "git reset --hard"
        ]
        expected_commands.each do |command|
          expect(FastlaneCore::CommandExecutor).to receive(:execute).once.with({
            command: command,
            print_all: nil,
            print_command: nil
          }).and_return("")
        end

        storage = Match::Storage::GitStorage.new(
          git_url: git_url,
          shallow_clone: shallow_clone,
          branch: git_branch
        )
        storage.download

        expect(File.directory?(storage.working_directory)).to eq(true)
        expect(File.exist?(File.join(storage.working_directory, 'README.md'))).to eq(false) # because the README is being added when committing the changes
      end
    end

    describe "#save_changes" do
      it "skips README file generation if so requested" do
        path = Dir.mktmpdir # to have access to the actual path
        expect(Dir).to receive(:mktmpdir).and_return(path)
        git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
        git_branch = "master"
        random_file = "random_file"

        storage = Match::Storage::GitStorage.new(
          type: "appstore",
          platform: "ios",
          git_url: git_url,
          shallow_clone: false,
          skip_docs: true,
          identifiers: ["tools.fastlane.com"]
        )

        expected_commands = [
          "git clone #{git_url.shellescape} #{path.shellescape}",
          "git --no-pager branch --list origin/#{git_branch} --no-color -r",
          "git checkout --orphan #{git_branch}",
          "git reset --hard",
          "git add #{random_file}",
          "git add match_version.txt",
          "git commit -m " + '[fastlane] Updated appstore and platform ios for identifier(s) tools.fastlane.com'.shellescape,
          "git push origin #{git_branch}"
        ]

        expected_commands.each do |command|
          expect(FastlaneCore::CommandExecutor).to receive(:execute).once.with({
            command: command,
            print_all: nil,
            print_command: nil
          }).and_return("")
        end

        expect(storage).to receive(:clear_changes).and_return(nil) # so we can inspect the folder

        storage.download
        storage.save_changes!(files_to_commit: [random_file])

        expect(File.directory?(storage.working_directory)).to eq(true)
        expect(File.exist?(File.join(storage.working_directory, 'README.md'))).to eq(false)
        expect(File.read(File.join(storage.working_directory, 'match_version.txt'))).to eq(Fastlane::VERSION)
      end
    end

    describe "authentication" do
      it "wraps the git command in ssh-agent shell when using a private key file" do
        path = Dir.mktmpdir # to have access to the actual path
        expect(Dir).to receive(:mktmpdir).and_return(path)
        expect(File).to receive(:file?).and_return(true)
        git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
        shallow_clone = false
        private_key = "#{path}/fastlane.match.id_dsa"
        clone_command = "ssh-agent bash -c 'ssh-add #{private_key.shellescape}; git clone #{git_url.shellescape} #{path.shellescape}'"

        git_branch = "master"

        expected_commands = [
          clone_command,
          "git --no-pager branch --list origin/#{git_branch} --no-color -r",
          "git checkout --orphan #{git_branch}",
          "git reset --hard"
        ]

        expected_commands.each do |command|
          expect(FastlaneCore::CommandExecutor).to receive(:execute).once.with({
            command: command,
            print_all: nil,
            print_command: nil
          }).and_return("")
        end

        storage = Match::Storage::GitStorage.new(
          git_url: git_url,
          shallow_clone: shallow_clone,
          git_private_key: private_key
        )
        storage.download

        expect(File.directory?(storage.working_directory)).to eq(true)
        expect(File.exist?(File.join(storage.working_directory, 'README.md'))).to eq(false) # because the README is being added when committing the changes
      end

      it "wraps the git command in ssh-agent shell when using a raw private key" do
        path = Dir.mktmpdir # to have access to the actual path
        expect(Dir).to receive(:mktmpdir).and_return(path)
        expect(File).to receive(:file?).and_return(false)
        git_url = "https://github.com/fastlane/fastlane/tree/master/certificates"
        shallow_clone = false
        private_key = "-----BEGIN PRIVATE KEY-----\n-----END PRIVATE KEY-----\n"
        clone_command = "ssh-agent bash -c 'ssh-add - <<< \"#{private_key}\"; git clone #{git_url.shellescape} #{path.shellescape}'"

        git_branch = "master"

        expected_commands = [
          clone_command,
          "git --no-pager branch --list origin/#{git_branch} --no-color -r",
          "git checkout --orphan #{git_branch}",
          "git reset --hard"
        ]

        expected_commands.each do |command|
          expect(FastlaneCore::CommandExecutor).to receive(:execute).once.with({
            command: command,
            print_all: nil,
            print_command: nil
          }).and_return("")
        end

        storage = Match::Storage::GitStorage.new(
          git_url: git_url,
          shallow_clone: shallow_clone,
          git_private_key: private_key
        )
        storage.download

        expect(File.directory?(storage.working_directory)).to eq(true)
        expect(File.exist?(File.join(storage.working_directory, 'README.md'))).to eq(false) # because the README is being added when committing the changes
      end
    end

    describe "ssh-agent utilities" do
      it "wraps any given command in ssh-agent shell when using a raw private key" do
        given_command = "any random command"
        private_key = "-----BEGIN PRIVATE KEY-----\n-----END PRIVATE KEY-----\n"

        storage = Match::Storage::GitStorage.new(
          git_private_key: private_key
        )

        expected_command = "ssh-agent bash -c 'ssh-add - <<< \"#{private_key}\"; #{given_command}'"
        expect(storage.command_from_private_key(given_command)).to eq(expected_command)
      end

      it "wraps any given command in ssh-agent shell when using a private key file" do
        given_command = "any random command"
        private_key = "#{Dir.mktmpdir}/fastlane.match.id_dsa"

        storage = Match::Storage::GitStorage.new(
          git_private_key: private_key
        )

        expected_command = "ssh-agent bash -c 'ssh-add - <<< \"#{File.expand_path(private_key).shellescape}\"; #{given_command}'"
        expect(storage.command_from_private_key(given_command)).to eq(expected_command)
      end
    end
  end
end
