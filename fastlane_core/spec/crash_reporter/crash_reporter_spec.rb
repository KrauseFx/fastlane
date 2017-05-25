describe FastlaneCore::CrashReporter do
  context 'crash reporting' do
    before do
      ENV['FASTLANE_OPT_OUT_CRASH_REPORTING'] = nil
      FastlaneCore::CrashReporter.reset_crash_reporter_for_testing
      FastlaneCore::CrashReporter.enable_for_testing
    end

    after do
      ENV['FASTLANE_OPT_OUT_CRASH_REPORTING'] = '1'
      FastlaneCore::CrashReporter.disable_for_testing
    end

    let(:exception) { double('Exception', backtrace: []) }

    let(:stub_body) do
      {
        'key' => 'value'
      }
    end

    context 'post reports to Stackdriver' do
      before do
        silence_ui_output
        supress_crash_report_file_writing
        supress_opt_out_crash_reporting_file_writing
      end

      it 'only posts one report' do
        stub_stackdriver_request
        setup_crash_report_generator_expectation(exception: exception)
        FastlaneCore::CrashReporter.report_crash(exception: exception)

        # The expectation we set up above is only for one invocation of the
        # report generator, so if this calls it again, it will fail
        FastlaneCore::CrashReporter.report_crash(exception: exception)
      end
    end

    context 'plugin crashes' do
      let(:plugin_exception) { double('Plugin_Exception', backtrace: ['[gem_home]/gems/fastlane-plugin-appicon-0.6.0/lib/fastlane/plugin/appicon/actions/android_appicon_action.rb:23:in `run']) }

      it 'does not post crash report if the crash came from a plugin' do
        expect(FastlaneCore::CrashReportGenerator).to_not receive(:generate)
        expect(FastlaneCore::CrashReporter.crash_came_from_plugin?(exception: plugin_exception)).to eq(true)
        FastlaneCore::CrashReporter.report_crash(exception: plugin_exception)
      end
    end

    context 'opted out of crash reporting' do
      before do
        silence_ui_output
        supress_opt_out_crash_reporting_file_writing
        supress_crash_report_file_writing
      end

      it 'does not post a report to Stackdriver if opted out' do
        ENV['FASTLANE_OPT_OUT_CRASH_REPORTING'] = '1'
        assert_not_requested(stub_stackdriver_request)
      end
    end

    context 'write report to file' do
      before do
        silence_ui_output
        supress_stackdriver_reporting
        setup_crash_report_generator_expectation(exception: exception)
        supress_opt_out_crash_reporting_file_writing
      end

      it 'writes a file with the json payload' do
        expect(File).to receive(:write).with(FastlaneCore::CrashReporter.crash_report_path, stub_body.to_json)

        FastlaneCore::CrashReporter.report_crash(exception: exception)
      end
    end
  end
end

def silence_ui_output
  allow(UI).to receive(:message)
end

def supress_opt_out_crash_reporting_file_writing
  allow(File).to receive(:write)
end

def supress_crash_report_file_writing
  allow(File).to receive(:write).with(FastlaneCore::CrashReporter.crash_report_path, stub_body.to_json)
end

def supress_stackdriver_reporting
  stub_stackdriver_request
end

def setup_crash_report_generator_expectation(action: nil, exception: nil)
  expect(FastlaneCore::CrashReportGenerator).to receive(:generate).with(
    exception: exception,
    action: action
  ).and_return(stub_body.to_json)
end

def stub_stackdriver_request
  stub_request(:post, %r{https:\/\/clouderrorreporting.googleapis.com\/v1beta1\/projects\/fastlane-166414\/events:report\?key=.*}).with do |request|
    request.body == stub_body.to_json
  end
end
