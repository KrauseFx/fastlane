describe Fastlane do
  describe Fastlane::FastFile do
    describe "import_from_git" do
      it "raises an exception when no path is given" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            import_from_git
          end").runner.execute(:test)
        end.to raise_error("Please pass a path to the `import_from_git` action")
      end

      # (2.32.0)
      # (2.32.0).win.1
      # (3)
      def git_version
        output = `git --version`
        m = output.match(/(?<version>\d+(?:\.\d+)*)/)
        raise "Couldn't parse git version in '#{output}'" unless m
        m['version']
      end

      original_source_directory_path = nil
      source_directory_path = nil

      original_cache_directory_path = nil
      cache_directory_path = nil
      missing_cache_directory_path = nil

      before :all do
        # This is needed for tag searching that `import_from_git` needs.
        ENV["FORCE_SH_DURING_TESTS"] = "1"

        original_source_directory_path = Dir.mktmpdir("fl_spec_import_from_git_source")

        Dir.chdir(original_source_directory_path) do
          if Gem::Version.new(git_version) >= Gem::Version.new("2.28.0")
            `git init -b master`
          else
            `git init`
          end
          `git config user.email "you@example.com"`
          `git config user.name "Your Name"`

          `mkdir fastlane`
          File.write('fastlane/Fastfile', <<-FASTFILE)
            lane :works do
              UI.important('Works since v1')
            end
          FASTFILE
          `git add .`
          `git commit --message "Version 1"`
          `git tag "1" --message "Version 1"`

          File.write('fastlane/FastfileExtra', <<-FASTFILE)
            lane :works_extra do
              UI.important('Works from extra since v2')
            end
          FASTFILE
          `git add .`
          `git commit --message "Version 2"`
          `git tag "2" --message "Version 2"`

          File.write('FastfileRoot', <<-FASTFILE)
            lane :works_root do
              UI.important('Works from root since v3')
            end
          FASTFILE
          `git add .`
          `git commit --message "Version 3"`
          `git tag "3" --message "Version 3"`

          `mkdir fastlane/actions`
          FileUtils.mkdir_p('fastlane/actions')
          File.write('fastlane/actions/work_action.rb', <<-FASTFILE)
            module Fastlane
              module Actions
                class WorkActionAction < Action
                  def self.run(params)
                    UI.important('Works from action since v4')
                  end

                  def self.is_supported?(platform)
                    true
                  end
                end
              end
            end
          FASTFILE
          `git add .`
          `git commit --message "Version 4"`
          `git tag "4" --message "Version 4"`

          `git checkout tags/2 -b version-2.1 2>&1`
          File.write('fastlane/Fastfile', <<-FASTFILE)
            lane :works do
              UI.important('Works since v2.1')
            end
          FASTFILE
          `git add .`
          `git commit --message "Version 2.1"`
          `git tag "2.1" --message "Version 2.1"`
        end

        original_cache_directory_path = Dir.mktmpdir("fl_spec_import_from_git_cache")

        missing_cache_directory_path = Dir.mktmpdir("fl_spec_import_from_git_missing_cache")
        FileUtils.remove_dir(missing_cache_directory_path)
      end

      before :each do
        source_directory_path = "#{original_source_directory_path}-#{Time.now.to_i}"
        FileUtils.copy_entry(original_source_directory_path, source_directory_path)

        cache_directory_path = "#{original_cache_directory_path}-#{Time.now.to_i}"
        FileUtils.copy_entry(original_cache_directory_path, cache_directory_path)
      end

      let(:caching_message) { "Eligible for caching" }

      describe "with caching" do
        it "works with version" do
          allow(UI).to receive(:message)
          expect(UI).to receive(:message).with(caching_message)
          expect(UI).to receive(:important).with('Works since v1')

          Fastlane::FastFile.new.parse("lane :test do
            import_from_git(url: '#{source_directory_path}', version: '1', cache_path: '#{cache_directory_path}')

            works
          end").runner.execute(:test)
        end

        it "works with dependencies and version" do
          allow(UI).to receive(:message)
          expect(UI).to receive(:message).with(caching_message)
          expect(UI).to receive(:important).with('Works from extra since v2')

          Fastlane::FastFile.new.parse("lane :test do
            import_from_git(url: '#{source_directory_path}', dependencies: ['fastlane/FastfileExtra'], version: '2', cache_path: '#{cache_directory_path}')

            works_extra
          end").runner.execute(:test)
        end

        it "works with path and version" do
          allow(UI).to receive(:message)
          expect(UI).to receive(:message).with(caching_message)
          expect(UI).to receive(:important).with('Works from root since v3')

          Fastlane::FastFile.new.parse("lane :test do
            import_from_git(url: '#{source_directory_path}', path: 'FastfileRoot', version: '3', cache_path: '#{cache_directory_path}')

            works_root
          end").runner.execute(:test)
        end

        it "works with actions" do
          allow(UI).to receive(:message)
          expect(UI).to receive(:message).with(caching_message)
          expect(UI).to receive(:important).with('Works from action since v4')

          Fastlane::FastFile.new.parse("lane :test do
            import_from_git(url: '#{source_directory_path}', version: '4', cache_path: '#{cache_directory_path}')

            work_action
          end").runner.execute(:test)
        end

        # This is based on the fact that rspec runs the tests in the order
        # they're defined in this file, so it tests the fact that importing
        # works with an older version after a newer one was previously checked
        # out.
        it "works with older version" do
          allow(UI).to receive(:message)
          expect(UI).to receive(:message).with(caching_message)
          expect(UI).to receive(:important).with('Works since v1')

          Fastlane::FastFile.new.parse("lane :test do
            import_from_git(url: '#{source_directory_path}', version: '1', cache_path: '#{cache_directory_path}')

            works
          end").runner.execute(:test)
        end

        # Meaning, a `git pull` is performed when the specified tag is not found
        # in the local clone.
        it "works with new tags" do
          # Simulating a previous `import_from_git` execution
          Fastlane::Actions.sh("git clone #{source_directory_path.shellescape} #{File.join(cache_directory_path, source_directory_path.split('/').last).shellescape}")

          Dir.chdir(source_directory_path) do
            `git checkout "master" 2>&1`
            File.write('fastlane/Fastfile', <<-FASTFILE)
              lane :works do
                UI.important('Works until v5')
              end
            FASTFILE
            `git add .`
            `git commit --message "Version 5"`
            `git tag "5" --message "Version 5"`
          end

          allow(UI).to receive(:message)
          expect(UI).to receive(:message).with(caching_message)
          expect(UI).to receive(:important).with('Works until v5')

          Fastlane::FastFile.new.parse("lane :test do
            import_from_git(url: '#{source_directory_path}', branch: 'master', version: '5', cache_path: '#{cache_directory_path}')

            works
          end").runner.execute(:test)
        end

        # Actually, `git checkout` makes sure of this, but I think it's ok to
        # keep this test, in case we change the implementation.
        it "works with nonexistent paths" do
          expect(UI).to receive(:important).with('Works since v1')

          expect do
            Fastlane::FastFile.new.parse("lane :test do
              import_from_git(url: '#{source_directory_path}', version: '3', cache_path: '#{missing_cache_directory_path}')

              works
            end").runner.execute(:test)
          end.not_to raise_error

          FileUtils.remove_dir(missing_cache_directory_path)
        end

        it "works with branch" do
          allow(UI).to receive(:message)
          expect(UI).to receive(:message).with(caching_message)
          expect(UI).to receive(:important).with('Works since v2.1')

          Fastlane::FastFile.new.parse("lane :test do
            import_from_git(url: '#{source_directory_path}', branch: 'version-2.1', cache_path: '#{cache_directory_path}')

            works
          end").runner.execute(:test)
        end

        it "works with initial checkout where the requested version is the last commit" do
          allow(UI).to receive(:message)
          expect(UI).to receive(:message).with(caching_message)
          expect(UI).to receive(:important).with('Works since v2.1')

          Fastlane::FastFile.new.parse("lane :test_wtf do
            import_from_git(url: '#{source_directory_path}', version: '2.1', cache_path: '#{cache_directory_path}')

            works
          end").runner.execute(:test_wtf)
        end

        # Meaning, `git fetch` and `git rebase` are performed when caching is eligible
        # and the version isn't specified.
        it "works with updated branch" do
          Dir.chdir(source_directory_path) do
            `git checkout "version-2.1" 2>&1`
            File.write('fastlane/Fastfile', <<-FASTFILE)
              lane :works do
                UI.important('Works until v5')
              end
            FASTFILE
            `git add .`
            `git commit --message "Version 5"`
          end

          allow(UI).to receive(:message)
          expect(UI).to receive(:message).with(caching_message)
          expect(UI).to receive(:important).with('Works until v5')

          Fastlane::FastFile.new.parse("lane :test do
            import_from_git(url: '#{source_directory_path}', branch: 'version-2.1', cache_path: '#{cache_directory_path}')

            works
          end").runner.execute(:test)
        end

        # Respects the specified version even if the branch is specified.
        it "works with new tags and branch" do
          Dir.chdir(source_directory_path) do
            `git checkout "master" 2>&1`
            File.write('fastlane/Fastfile', <<-FASTFILE)
              lane :works do
                UI.important('Works until v6')
              end
            FASTFILE
            `git add .`
            `git commit --message "Version 6"`
            `git tag "6" --message "Version 6"`
          end

          allow(UI).to receive(:message)
          expect(UI).to receive(:message).with(caching_message)
          expect(UI).to receive(:important).with('Works until v6')

          Fastlane::FastFile.new.parse("lane :test do
            import_from_git(url: '#{source_directory_path}', branch: 'version-2.1', version: '6', cache_path: '#{cache_directory_path}')

            works
          end").runner.execute(:test)
        end

        it "doesn't superfluously execute checkout" do
          # Simulating a previous `import_from_git` execution
          Fastlane::Actions.sh("git clone #{source_directory_path.shellescape} #{File.join(cache_directory_path, source_directory_path.split('/').last).shellescape}")

          allow(UI).to receive(:message)
          expect(UI).to receive(:message).with(caching_message)
          expect(UI).to receive(:important).with('Works since v2.1')
          allow(Fastlane::Actions).to receive(:sh).and_call_original

          Fastlane::FastFile.new.parse("lane :test do
            import_from_git(url: '#{source_directory_path}', version: '2.1', cache_path: '#{cache_directory_path}')

            works
          end").runner.execute(:test)

          expect(Fastlane::Actions).not_to have_received(:sh).with(/git checkout/)
        end

      end

      describe "without caching" do
        it "works when no cache is provided" do
          allow(UI).to receive(:message)
          expect(UI).not_to receive(:message).with(caching_message)
          expect(UI).to receive(:important).with('Works since v2.1')
          allow(Fastlane::Actions).to receive(:sh).and_call_original

          Fastlane::FastFile.new.parse("lane :test do
            import_from_git(url: '#{source_directory_path}', cache_path: nil)

            works
          end").runner.execute(:test)
        end
      end

      it "works with one HTTP header" do
        header = 'Authorization: Basic my_base_64_key'

        allow(Fastlane::Actions).to receive(:sh).and_call_original
        expect(Fastlane::Actions).to receive(:sh).with(any_args, '--config', "http.extraHeader=#{header}")

        Fastlane::FastFile.new.parse("lane :test do
          import_from_git(url: '#{source_directory_path}', git_extra_headers: ['#{header}'])
        end").runner.execute(:test)
      end

      it "works with two HTTP headers" do
        first_header = 'Authorization: Basic my_base_64_key'
        second_header = 'Cache-Control: no-cache'

        allow(Fastlane::Actions).to receive(:sh).and_call_original
        expect(Fastlane::Actions).to receive(:sh).with(any_args, '--config', "http.extraHeader=#{first_header}", '--config', "http.extraHeader=#{second_header}")

        Fastlane::FastFile.new.parse("lane :test do
          import_from_git(url: '#{source_directory_path}', git_extra_headers: ['#{first_header}', '#{second_header}'])
        end").runner.execute(:test)
      end

      after :each do
        FileUtils.remove_dir(source_directory_path)
        FileUtils.remove_dir(cache_directory_path)
      end

      after :all do
        ENV.delete("FORCE_SH_DURING_TESTS")

        FileUtils.remove_dir(original_source_directory_path)
        FileUtils.remove_dir(original_cache_directory_path)
      end
    end
  end
end
