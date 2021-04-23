require 'scan'

describe Scan do
  describe Scan::Runner do
    describe "handle_results" do
      before(:each) do
        mock_slack_poster = Object.new
        allow(Scan::SlackPoster).to receive(:new).and_return(mock_slack_poster)
        allow(mock_slack_poster).to receive(:run)

        mock_test_command_generator = Object.new
        allow(Scan::TestCommandGenerator).to receive(:new).and_return(mock_test_command_generator)
        allow(mock_test_command_generator).to receive(:xcodebuild_log_path).and_return('./scan/spec/fixtures/boring.log')

        mock_test_result_parser = Object.new
        allow(Scan::TestResultParser).to receive(:new).and_return(mock_test_result_parser)
        allow(mock_test_result_parser).to receive(:parse_result).and_return({ tests: 100, failures: 0 })

        @scan = Scan::Runner.new
      end

      describe "with scan option :include_simulator_logs set to false" do
        it "does not copy any device logs to the output directory", requires_xcodebuild: true do
          # Circle CI is setting the SCAN_INCLUDE_SIMULATOR_LOGS env var, so just leaving
          # the include_simulator_logs option out does not let it default to false
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
            output_directory: '/tmp/scan_results',
            project: './scan/examples/standard/app.xcodeproj',
            include_simulator_logs: false
          })

          expect(FastlaneCore::Simulator).not_to(receive(:copy_logs))
          @scan.handle_results(0)
        end
      end

      describe "with scan option :include_simulator_logs set to true" do
        it "copies any device logs to the output directory", requires_xcodebuild: true do
          # Circle CI is setting the SCAN_INCLUDE_SIMULATOR_LOGS env var, so just leaving
          # the include_simulator_logs option out does not let it default to false
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
            output_directory: '/tmp/scan_results',
            project: './scan/examples/standard/app.xcodeproj',
            include_simulator_logs: true
          })

          expect(FastlaneCore::Simulator).to receive(:copy_logs)
          @scan.handle_results(0)
        end
      end

      describe "Test Failure" do
        it "raises a FastlaneTestFailure instead of a crash or UserError", requires_xcodebuild: true do
          expect do
            Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
              output_directory: '/tmp/scan_results',
              project: './scan/examples/standard/app.xcodeproj'
            })
            custom_parser = "custom_parser"
            expect(Scan::TestResultParser).to receive(:new).and_return(custom_parser)
            expect(custom_parser).to receive(:parse_result).and_return({ tests: 5, failures: 3 })

            @scan.handle_results(0)
          end.to raise_error(FastlaneCore::Interface::FastlaneTestFailure, "Tests have failed")
        end
      end

      describe "with scan option :disable_xcpretty set to true" do
        it "does not generate a temp junit report", requires_xcodebuild: true do
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
            output_directory: '/tmp/scan_results',
            project: './scan/examples/standard/app.xcodeproj',
            disable_xcpretty: true
          })

          Scan.cache[:temp_junit_report] = '/var/folders/non_existent_file.junit'
          @scan.handle_results(0)
          expect(Scan.cache[:temp_junit_report]).to(eq('/var/folders/non_existent_file.junit'))
        end

        it "fails if tests_exit_status is not 0", requires_xcodebuild: true do
          expect do
            Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
              output_directory: '/tmp/scan_results',
              project: './scan/examples/standard/app.xcodeproj',
              disable_xcpretty: true
            })

            @scan.handle_results(1)
          end.to raise_error(FastlaneCore::Interface::FastlaneTestFailure, "Test execution failed. Exit status: 1")
        end
      end
    end

    describe "retry_execute" do
      before(:each) do
        @scan = Scan::Runner.new
      end

      it "retry a failed test", requires_xcodebuild: true do
        error_output = <<-ERROR_OUTPUT
Failing tests:
  FastlaneAppTests:
          FastlaneAppTests.testCoinToss()
        ERROR_OUTPUT

        expect(Fastlane::UI).to receive(:important).with("Retrying tests: FastlaneAppTests/FastlaneAppTests/testCoinToss").once
        expect(Fastlane::UI).to receive(:important).with("Number of retries remaining: 4").once
        expect(@scan).to receive(:execute)

        @scan.retry_execute(retries: 5, error_output: error_output)
      end

      it "fail to parse error output", requires_xcodebuild: true do
        error_output = <<-ERROR_OUTPUT
Failing tests:
FastlaneAppTests:
FastlaneAppTests.testCoinToss()
        ERROR_OUTPUT

        expect do
          @scan.retry_execute(retries: 5, error_output: error_output)
        end.to raise_error(FastlaneCore::Interface::FastlaneCrash, "Failed to find failed tests to retry (could not parse error output)")
      end
    end

    describe "test_results" do
      before(:each) do
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
          output_directory: '/tmp/scan_results',
          project: './scan/examples/standard/app.xcodeproj',
          include_simulator_logs: false
        })

        mock_slack_poster = Object.new
        allow(Scan::SlackPoster).to receive(:new).and_return(mock_slack_poster)
        allow(mock_slack_poster).to receive(:run)

        mock_test_command_generator = Object.new
        allow(Scan::TestCommandGenerator).to receive(:new).and_return(mock_test_command_generator)
        allow(mock_test_command_generator).to receive(:xcodebuild_log_path).and_return('./scan/spec/fixtures/boring.log')

        @scan = Scan::Runner.new
      end

      it "still proceeds successfully if the temp junit report was deleted", requires_xcodebuild: true do
        Scan.cache[:temp_junit_report] = '/var/folders/non_existent_file.junit'
        expect(@scan.test_results).to_not(be_nil)
        expect(Scan.cache[:temp_junit_report]).to_not(eq('/var/folders/non_existent_file.junit'))
      end

      describe "when output_style is raw" do
        it "still proceeds successfully and generates a temp junit report", requires_xcodebuild: true do
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
            output_directory: '/tmp/scan_results',
            project: './scan/examples/standard/app.xcodeproj',
            include_simulator_logs: false,
            output_style: "raw"
          })

          Scan.cache[:temp_junit_report] = '/var/folders/non_existent_file.junit'
          expect(@scan.test_results).to_not(be_nil)
          expect(Scan.cache[:temp_junit_report]).to_not(eq('/var/folders/non_existent_file.junit'))
        end
      end
    end

    describe "#zip_build_products" do
      it "doesn't zip data when :should_zip_build_products is false", requires_xcodebuild: true do
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
          output_directory: '/tmp/scan_results',
          project: './scan/examples/standard/app.xcodeproj',
          should_zip_build_products: false
        })

        expect(FastlaneCore::Helper).to receive(:backticks).with(anything).exactly(0).times

        scan = Scan::Runner.new
        scan.zip_build_products
      end

      it "zips data when :should_zip_build_products is true", requires_xcodebuild: true do
        Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
          output_directory: '/tmp/scan_results',
          derived_data_path: '/tmp/derived_data/app',
          project: './scan/examples/standard/app.xcodeproj',
          should_zip_build_products: true
        })

        path = File.join(Scan.config[:derived_data_path], "Build/Products")
        path = File.absolute_path(path)

        output_path = File.absolute_path('/tmp/scan_results/build_products.zip')

        expect(FastlaneCore::Helper).to receive(:backticks)
          .with("cd '#{path}' && rm -f '#{output_path}' && zip -r '#{output_path}' *", { print: false })
          .exactly(1).times

        scan = Scan::Runner.new
        scan.zip_build_products
      end
    end

    describe "output_xctestrun" do
      it "copies .xctestrun file when :output_xctestrun is true", requires_xcodebuild: true do
        Dir.mktmpdir("scan_results") do |tmp_dir|
          # Configuration
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
            derived_data_path: File.join(tmp_dir, 'derived_data'),
            output_directory: File.join(tmp_dir, 'output'),
            project: './scan/examples/standard/app.xcodeproj',
            output_xctestrun: true
          })

          # Make output directory
          FileUtils.mkdir_p(Scan.config[:output_directory])

          # Make derived data directory
          path = File.join(Scan.config[:derived_data_path], "Build/Products")
          FileUtils.mkdir_p(path)

          # Create .xctestrun file that will be copied
          xctestrun_path = File.join(path, 'something-project-something.xctestrun')
          FileUtils.touch(xctestrun_path)

          scan = Scan::Runner.new
          scan.copy_xctestrun

          output_path = File.join(Scan.config[:output_directory], 'settings.xctestrun')
          expect(File.file?(output_path)).to eq(true)
        end
      end
    end
  end
end
