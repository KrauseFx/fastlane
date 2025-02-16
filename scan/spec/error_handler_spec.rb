require 'scan'

describe Scan do
  describe Scan::ErrorHandler do
    let(:log_path) { '~/scan.log' }

    describe "handle_build_error" do
      describe "when parsing parallel test failure output" do
        it "does not report a build failure" do
          expect(Scan).to receive(:config).and_return({})
          output = File.open('./scan/spec/fixtures/parallel_testing_failure.log', &:read)
          expect do
            Scan::ErrorHandler.handle_build_error(output, log_path)
          end.not_to raise_error
        end
      end

      describe "when parsing non-parallel test failure output" do
        it "does not report a build failure" do
          expect(Scan).to receive(:config).and_return({})
          output = File.open('./scan/spec/fixtures/non_parallel_testing_failure.log', &:read)
          expect do
            Scan::ErrorHandler.handle_build_error(output, log_path)
          end.to_not(raise_error)
        end
      end

      describe "when parsing build failure output", requires_xcode: true do
        before(:each) do
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
            project: './scan/examples/standard/app.xcodeproj'
          })
        end

        it "reports a build failure" do
          expect(FastlaneCore::UI).to receive(:build_failure!).with("Error building the application. See the log above.")

          output = File.open('./scan/spec/fixtures/build_failure.log', &:read)
          expect do
            Scan::ErrorHandler.handle_build_error(output, log_path)
          end.to(raise_error)
        end
      end

      describe "when parsing early failure output" do
        let(:output_path) { './scan/spec/fixtures/early_testing_failure.log' }

        before(:each) do
          Scan.config = FastlaneCore::Configuration.create(Scan::Options.available_options, {
            project: './scan/examples/standard/app.xcodeproj'
          })
        end

        it "reports a build failure", requires_xcodebuild: true do
          output = File.open(output_path, &:read)
          expect do
            Scan::ErrorHandler.handle_build_error(output, log_path)
          end.to(raise_error(FastlaneCore::Interface::FastlaneBuildFailure))
        end

        it "mentions log above when not suppressing output", requires_xcodebuild: true do
          output = File.open(output_path, &:read)
          expect do
            Scan::ErrorHandler.handle_build_error(output, log_path)
          end.to(raise_error(FastlaneCore::Interface::FastlaneBuildFailure, "Error building the application. See the log above."))
        end

        it "mentions log file when suppressing output", requires_xcodebuild: true do
          Scan.config[:suppress_xcode_output] = true

          output = File.open(output_path, &:read)
          expect do
            Scan::ErrorHandler.handle_build_error(output, log_path)
          end.to(raise_error(FastlaneCore::Interface::FastlaneBuildFailure, "Error building the application. See the log here: '#{log_path}'."))
        end
      end
    end
  end
end
