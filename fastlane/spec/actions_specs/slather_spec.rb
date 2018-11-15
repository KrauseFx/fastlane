describe Fastlane do
  describe Fastlane::FastFile do
    describe "Slather Integration" do
      let(:action) { Fastlane::Actions::SlatherAction }
      it "works with all parameters" do
        allow(Fastlane::Actions::SlatherAction).to receive(:slather_version).and_return(Gem::Version.create('2.4.1'))
        source_files = "*.swift"
        result = Fastlane::FastFile.new.parse("lane :test do
          slather({
            use_bundle_exec: false,
            build_directory: 'foo',
            input_format: 'bah',
            scheme: 'Foo',
            configuration: 'Bar',
            buildkite: true,
            jenkins: true,
            travis: true,
            travis_pro: true,
            circleci: true,
            coveralls: true,
            teamcity: true,
            simple_output: true,
            gutter_json: true,
            cobertura_xml: true,
            llvm_cov: true,
            html: true,
            show: true,
            verbose: true,
            source_directory: 'baz',
            output_directory: '123',
            ignore: 'nothing',
            proj: 'foo.xcodeproj',
            binary_basename: ['YourApp', 'YourFramework'],
            binary_file: 'you',
            workspace: 'foo.xcworkspace',
            arch: 'arm64',
            source_files: '#{source_files}',
            decimals: '2'
          })
        end").runner.execute(:test)

        expected = "slather coverage
                    --travis
                    --travispro
                    --circleci
                    --jenkins
                    --buildkite
                    --teamcity
                    --coveralls
                    --simple-output
                    --gutter-json
                    --cobertura-xml
                    --llvm-cov
                    --html
                    --show
                    --build-directory foo
                    --source-directory baz
                    --output-directory 123
                    --ignore nothing
                    --verbose
                    --input-format bah
                    --scheme Foo
                    --configuration Bar
                    --workspace foo.xcworkspace
                    --binary-file you
                    --binary-basename YourApp
                    --binary-basename YourFramework
                    --arch arm64
                    --source-files #{source_files.shellescape}
                    --decimals 2 foo.xcodeproj".gsub(/\s+/, ' ')
        expect(result).to eq(expected)
      end

      it "works with bundle" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        allow(Fastlane::Actions::SlatherAction).to receive(:slather_version).and_return(Gem::Version.create('2.4.1'))
        result = Fastlane::FastFile.new.parse("lane :test do
          slather({
            use_bundle_exec: true,
            build_directory: 'foo',
            input_format: 'bah',
            scheme: 'Foo',
            configuration: 'Bar',
            buildkite: true,
            jenkins: true,
            travis: true,
            travis_pro: true,
            circleci: true,
            coveralls: true,
            simple_output: true,
            gutter_json: true,
            cobertura_xml: true,
            llvm_cov: true,
            html: true,
            show: true,
            source_directory: 'baz',
            output_directory: '123',
            ignore: 'nothing',
            proj: 'foo.xcodeproj',
            binary_basename: ['YourApp', 'YourFramework'],
            binary_file: 'you',
            workspace: 'foo.xcworkspace'
          })
        end").runner.execute(:test)

        expected = 'bundle exec slather coverage
                    --travis
                    --travispro
                    --circleci
                    --jenkins
                    --buildkite
                    --coveralls
                    --simple-output
                    --gutter-json
                    --cobertura-xml
                    --llvm-cov
                    --html
                    --show
                    --build-directory foo
                    --source-directory baz
                    --output-directory 123
                    --ignore nothing
                    --input-format bah
                    --scheme Foo
                    --configuration Bar
                    --workspace foo.xcworkspace
                    --binary-file you
                    --binary-basename YourApp
                    --binary-basename YourFramework foo.xcodeproj'.gsub(/\s+/, ' ')
        expect(result).to eq(expected)
      end

      it "requires project to be specified if .slather.yml is not found" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            slather
          end").runner.execute(:test)
        end.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it "does not require project if .slather.yml is found" do
        allow(FastlaneCore::FastlaneFolder).to receive(:path).and_return(nil)
        File.write('./.slather.yml', '')

        result = Fastlane::FastFile.new.parse("lane :test do
          slather
        end").runner.execute(:test)

        expect(result).to eq("slather coverage")
      end

      it "does not require any parameters other than project" do
        result = Fastlane::FastFile.new.parse("lane :test do
          slather({
            proj: 'foo.xcodeproj'
          })
        end").runner.execute(:test)

        expect(result).to eq("slather coverage foo.xcodeproj")
      end

      it "works with spaces in paths" do
        build_dir = "build dir"
        source_dir = "source dir"
        output_dir = "output dir"
        ignore = "nothing to ignore"
        scheme = "Foo App"
        proj = "foo bar.xcodeproj"
        result = Fastlane::FastFile.new.parse("lane :test do
          slather({
            build_directory: '#{build_dir}',
            input_format: 'bah',
            scheme: '#{scheme}',
            source_directory: '#{source_dir}',
            output_directory: '#{output_dir}',
            ignore: '#{ignore}',
            proj: '#{proj}'
          })
        end").runner.execute(:test)

        expected = "slather coverage
                    --build-directory #{build_dir.shellescape}
                    --source-directory #{source_dir.shellescape}
                    --output-directory #{output_dir.shellescape}
                    --ignore #{ignore.shellescape}
                    --input-format bah
                    --scheme #{scheme.shellescape}
                    #{proj.shellescape}".gsub(/\s+/, ' ')
        expect(result).to eq(expected)
      end

      it "works with multiple ignore patterns" do
        pattern1 = "Pods/*"
        pattern2 = "../**/*/Xcode*"
        result = Fastlane::FastFile.new.parse("lane :test do
          slather({
            ignore: ['#{pattern1}', '#{pattern2}'],
            proj: 'foo.xcodeproj'
          })
        end").runner.execute(:test)

        expect(result).to eq("slather coverage --ignore #{pattern1.shellescape} --ignore #{pattern2.shellescape} foo.xcodeproj")
      end

      describe "#configuration_available?" do
        let(:param) { { use_bundle_exec: false } }
        let(:version) { '' }
        before do
          allow(action).to receive(:slather_version).and_return(Gem::Version.create(version))
        end

        context "when slather version is 2.4.0" do
          let(:version) { '2.4.0' }
          it "configuration option is not available" do
            expect(action.configuration_available?).to be_falsey
          end
        end

        context "when slather version is 2.4.1" do
          let(:version) { '2.4.1' }
          it "configuration option is available" do
            expect(action.configuration_available?).to be_truthy
          end
        end

        context "when slather version is 2.4.2" do
          let(:version) { '2.4.2' }
          it "configuration option is available" do
            expect(action.configuration_available?).to be_truthy
          end
        end
      end

      describe "#validate_params!" do
        let(:param) { { configuration: 'Debug', proj: 'test.xcodeproj' } }
        let(:version) { '' }
        before do
          allow(action).to receive(:slather_version).and_return(Gem::Version.create(version))
        end

        context "when slather version is 2.4.0" do
          let(:version) { '2.4.0' }
          it "doesnot pass the validation" do
            expect do
              action.validate_params!(param)
            end.to raise_error(FastlaneCore::Interface::FastlaneError, 'configuration option is available since version 2.4.1')
          end
        end

        context "when slather version is 2.4.1" do
          let(:version) { '2.4.1' }
          it "pass the validation" do
            expect(action.validate_params!(param)).to be_truthy
          end
        end
      end

      after(:each) do
        File.delete('./.slather.yml') if File.exist?("./.slather.yml")
      end
    end
  end
end
