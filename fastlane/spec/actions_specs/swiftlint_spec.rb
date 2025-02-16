describe Fastlane do
  describe Fastlane::FastFile do
    describe "SwiftLint" do
      let(:swiftlint_gem_version) { Gem::Version.new('0.11.0') }
      let(:output_file) { "swiftlint.result.json" }
      let(:config_file) { ".swiftlint-ci.yml" }

      before :each do
        allow(Fastlane::Actions::SwiftlintAction).to receive(:swiftlint_version).and_return(swiftlint_gem_version)
      end

      context "default use case" do
        it "default use case" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint")
        end
      end

      context "when specify strict option" do
        it "adds strict option" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              strict: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint --strict")
        end

        it "omits strict option if swiftlint does not support it" do
          allow(Fastlane::Actions::SwiftlintAction).to receive(:swiftlint_version).and_return(Gem::Version.new('0.9.1'))

          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              strict: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint")
        end

        it "adds strict option for custom executable" do
          CUSTOM_EXECUTABLE_NAME = "custom_executable"

          # Override the already overridden swiftlint_version method to check
          # that the correct executable is being passed in as a parameter.
          allow(Fastlane::Actions::SwiftlintAction).to receive(:swiftlint_version) { |params|
            expect(params[:executable]).to eq(CUSTOM_EXECUTABLE_NAME)
            swiftlint_gem_version
          }

          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              strict: true,
              executable: '#{CUSTOM_EXECUTABLE_NAME}'
            )
          end").runner.execute(:test)

          expect(result).to eq("#{CUSTOM_EXECUTABLE_NAME} lint --strict")
        end
      end

      context "when specify false for strict option" do
        it "doesn't add strict option" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              strict: false
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint")
        end
      end

      context "when specify output_file options" do
        it "adds redirect file to command" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              output_file: '#{output_file}'
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint > #{output_file}")
        end
      end

      context "when specify config_file options" do
        it "adds config option" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              config_file: '#{config_file}'
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint --config #{config_file}")
        end
      end

      context "when specify output_file, config_file and strict options" do
        it "adds config option, strict option and redirect file" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              strict: true,
              output_file: '#{output_file}',
              config_file: '#{config_file}'
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint --strict --config #{config_file} > #{output_file}")
        end
      end

      context "when specify path options" do
        it "adds path option" do
          path = "./spec/fixtures"
          result = Fastlane::FastFile.new.parse("
            lane :test do
              swiftlint(
                path: '#{path}'
              )
            end").runner.execute(:test)

          expect(result).to eq("swiftlint lint --path #{path}")
        end

        it "adds invalid path option" do
          path = "./non/existent/path"
          expect do
            Fastlane::FastFile.new.parse("lane :test do
              swiftlint(
                path: '#{path}'
              )
            end").runner.execute(:test)
          end.to raise_error(/Couldn't find path '.*#{path}'/)
        end
      end

      context "the `ignore_exit_status` option" do
        context "by default" do
          it 'should raise if swiftlint completes with a non-zero exit status' do
            allow(FastlaneCore::UI).to receive(:important)
            expect(FastlaneCore::UI).to receive(:important).with(/If you want fastlane to continue anyway/)
            # This is simulating the exception raised if the return code is non-zero
            expect(Fastlane::Actions).to receive(:sh).and_raise("fake error")
            expect(FastlaneCore::UI).to receive(:user_error!).with(/SwiftLint finished with errors/).and_call_original

            expect do
              Fastlane::FastFile.new.parse("lane :test do
                swiftlint
              end").runner.execute(:test)
            end.to raise_error(/SwiftLint finished with errors/)
          end
        end

        context "when enabled" do
          it 'should not raise if swiftlint completes with a non-zero exit status' do
            allow(FastlaneCore::UI).to receive(:important)
            expect(FastlaneCore::UI).to receive(:important).with(/fastlane will continue/)
            # This is simulating the exception raised if the return code is non-zero
            expect(Fastlane::Actions).to receive(:sh).and_raise("fake error")
            expect(FastlaneCore::UI).to_not(receive(:user_error!))

            result = Fastlane::FastFile.new.parse("lane :test do
              swiftlint(ignore_exit_status: true)
            end").runner.execute(:test)
          end
        end

        context "when disabled" do
          it 'should raise if swiftlint completes with a non-zero exit status' do
            allow(FastlaneCore::UI).to receive(:important)
            expect(FastlaneCore::UI).to receive(:important).with(/If you want fastlane to continue anyway/)
            # This is simulating the exception raised if the return code is non-zero
            expect(Fastlane::Actions).to receive(:sh).and_raise("fake error")
            expect(FastlaneCore::UI).to receive(:user_error!).with(/SwiftLint finished with errors/).and_call_original

            expect do
              Fastlane::FastFile.new.parse("lane :test do
                swiftlint(ignore_exit_status: false)
              end").runner.execute(:test)
            end.to raise_error(/SwiftLint finished with errors/)
          end
        end
      end

      context "when specify mode explicitly" do
        it "uses lint mode as default" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint")
        end

        it "supports lint mode option" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :lint
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint")
        end

        it "supports fix mode option" do
          allow(Fastlane::Actions::SwiftlintAction).to receive(:swiftlint_version).and_return(Gem::Version.new('0.43.0'))
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :fix
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint --fix")
        end

        it "supports autocorrect mode option" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :autocorrect
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint autocorrect")
        end

        it "switches autocorrect mode to fix mode option if swiftlint does not support it" do
          allow(Fastlane::Actions::SwiftlintAction).to receive(:swiftlint_version).and_return(Gem::Version.new('0.43.0'))
          expect(FastlaneCore::UI).to receive(:deprecated).with("Your version of swiftlint (0.43.0) has deprecated autocorrect mode, please start using fix mode in input param")
          expect(FastlaneCore::UI).to receive(:important).with("For now, switching swiftlint mode `from :autocorrect to :fix` for you 😇")

          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :autocorrect
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint --fix")
        end

        it "switches fix mode to autocorrect mode option if swiftlint does not support it" do
          allow(Fastlane::Actions::SwiftlintAction).to receive(:swiftlint_version).and_return(Gem::Version.new('0.42.0'))
          expect(FastlaneCore::UI).to receive(:important).with("Your version of swiftlint (0.42.0) does not support fix mode.\nUpdate swiftlint using `brew update && brew upgrade swiftlint`")
          expect(FastlaneCore::UI).to receive(:important).with("For now, switching swiftlint mode `from :fix to :autocorrect` for you 😇")

          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :fix
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint autocorrect")
        end
      end

      context "when specify list of files to process" do
        it "adds use script input files option and environment variables" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              files: ['AppDelegate.swift', 'path/to/project/src/Model.swift', 'path/to/project/test/Test.swift']
            )
          end").runner.execute(:test)

          expect(result).to eq("SCRIPT_INPUT_FILE_COUNT=3 SCRIPT_INPUT_FILE_0=AppDelegate.swift SCRIPT_INPUT_FILE_1=path/to/project/src/Model.swift SCRIPT_INPUT_FILE_2=path/to/project/test/Test.swift swiftlint lint --use-script-input-files")
        end
      end

      context "when file paths contain spaces" do
        it "escapes spaces in output and config file paths" do
          output_file = "output path with spaces.txt"
          config_file = ".config file with spaces.yml"
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              output_file: '#{output_file}',
              config_file: '#{config_file}'
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint --config #{config_file.shellescape} > #{output_file.shellescape}")
        end

        it "escapes spaces in list of files to process" do
          file = "path/to/my project/source code/AppDelegate.swift"
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
                files: ['#{file}']
            )
          end").runner.execute(:test)

          expect(result).to eq("SCRIPT_INPUT_FILE_COUNT=1 SCRIPT_INPUT_FILE_0=#{file.shellescape} swiftlint lint --use-script-input-files")
        end
      end

      context "when specify reporter" do
        it "adds reporter option" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              reporter: 'json'
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint --reporter json")
        end
      end

      context "when specify quiet option" do
        it "adds quiet option" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              quiet: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint --quiet")
        end

        it "omits quiet option if swiftlint does not support it" do
          allow(Fastlane::Actions::SwiftlintAction).to receive(:swiftlint_version).and_return(Gem::Version.new('0.8.0'))

          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              quiet: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint")
        end
      end

      context "when specify false for quiet option" do
        it "doesn't add quiet option" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              quiet: false
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint")
        end
      end

      context "when specify format option" do
        it "adds format option" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :autocorrect,
              format: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint autocorrect --format")
        end

        it "omits format option if mode is :lint" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :lint,
              format: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint")
        end

        it "omits format option if swiftlint does not support it" do
          allow(Fastlane::Actions::SwiftlintAction).to receive(:swiftlint_version).and_return(Gem::Version.new('0.10.0'))
          expect(FastlaneCore::UI).to receive(:important).with(/Your version of swiftlint \(0.10.0\) does not support/)

          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :autocorrect,
              format: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint autocorrect")
        end
      end

      context "when specify false for format option" do
        it "doesn't add format option" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :autocorrect,
              format: false
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint autocorrect")
        end
      end

      context "when specify no-cache option" do
        it "adds no-cache option if mode is :autocorrect" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :autocorrect,
              no_cache: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint autocorrect --no-cache")
        end

        it "adds no-cache option if mode is :lint" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :lint,
              no_cache: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint --no-cache")
        end

        it "adds no-cache option if mode is :fix" do
          allow(Fastlane::Actions::SwiftlintAction).to receive(:swiftlint_version).and_return(Gem::Version.new('0.43.0'))

          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :fix,
              no_cache: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint --fix --no-cache")
        end

        it "omits format option if mode is :analyze" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :analyze,
              no_cache: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint analyze")
        end
      end

      context "when specify false for no-cache option" do
        it "doesn't add no-cache option if mode is :autocorrect" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :autocorrect,
              no_cache: false
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint autocorrect")
        end

        it "doesn't add no-cache option if mode is :lint" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :lint,
              no_cache: false
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint")
        end

        it "doesn't add no-cache option if mode is :fix" do
          allow(Fastlane::Actions::SwiftlintAction).to receive(:swiftlint_version).and_return(Gem::Version.new('0.43.0'))

          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              mode: :fix,
              no_cache: false
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint --fix")
        end
      end

      context "when using analyzer mode" do
        it "adds compiler-log-path option" do
          path = "./spec/fixtures"
          result = Fastlane::FastFile.new.parse("
            lane :test do
              swiftlint(
                compiler_log_path: '#{path}',
                mode: :analyze
              )
            end").runner.execute(:test)

          expect(result).to eq("swiftlint analyze --compiler-log-path #{path}")
        end

        it "adds invalid path option" do
          path = "./non/existent/path"
          expect do
            Fastlane::FastFile.new.parse("lane :test do
              swiftlint(
                compiler_log_path: '#{path}',
                mode: :analyze
              )
            end").runner.execute(:test)
          end.to raise_error(/Couldn't find compiler_log_path '.*#{path}'/)
        end
      end

      context "when specifying progress option" do
        it "adds progress option" do
          allow(Fastlane::Actions::SwiftlintAction).to receive(:swiftlint_version).and_return(Gem::Version.new('0.49.1'))

          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              progress: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint --progress")
        end

        it "omits progress option if swiftlint does not support it" do
          allow(Fastlane::Actions::SwiftlintAction).to receive(:swiftlint_version).and_return(Gem::Version.new('0.49.0'))
          expect(FastlaneCore::UI).to receive(:important).with(/Your version of swiftlint \(0.49.0\) does not support/)

          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              progress: true
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint")
        end
      end

      context "when specify false for progress option" do
        it "doesn't add progress option" do
          result = Fastlane::FastFile.new.parse("lane :test do
            swiftlint(
              progress: false
            )
          end").runner.execute(:test)

          expect(result).to eq("swiftlint lint")
        end
      end
    end
  end
end
