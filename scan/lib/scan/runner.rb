require 'open3'
require 'fileutils'
require 'terminal-table'
require 'shellwords'

require 'fastlane_core/env'
require 'fastlane_core/device_manager'
require_relative 'module'
require_relative 'xcpretty_reporter_options_generator'
require_relative 'test_result_parser'
require_relative 'slack_poster'
require_relative 'test_command_generator'
require_relative 'error_handler'

module Scan
  class Runner
    def initialize
      @test_command_generator = TestCommandGenerator.new
      @device_boot_datetime = DateTime.now
    end

    def run
      @xcresults_before_run = find_xcresults_in_derived_data
      return handle_results(test_app)
    end

    def test_app
      force_quit_simulator_processes if Scan.config[:force_quit_simulator]

      if Scan.devices
        if Scan.config[:reset_simulator]
          Scan.devices.each do |device|
            if device.os_type == "iOS"
              FastlaneCore::Simulator.reset(udid: device.udid)
            elsif device.os_type == "visionOS"
              FastlaneCore::SimulatorVision.reset(udid: device.udid)
            end
          end
        end

        if Scan.config[:disable_slide_to_type]
          Scan.devices.each do |device|
            if device.os_type == "iOS"
              FastlaneCore::Simulator.disable_slide_to_type(udid: device.udid)
            end
          end
        end
      end

      prelaunch_simulators

      if Scan.config[:reinstall_app]
        app_identifier = Scan.config[:app_identifier]
        app_identifier ||= UI.input("App Identifier: ")

        Scan.devices.each do |device|
          if device.os_type == "iOS"
            FastlaneCore::Simulator.uninstall_app(app_identifier, device.name, device.udid)
          elsif device.os_type == "visionOS"
            FastlaneCore::SimulatorVision.uninstall_app(app_identifier, device.name, device.udid)
          end
        end
      end

      retries = Scan.config[:number_of_retries]
      execute(retries: retries)
    end

    def execute(retries: 0)
      # Set retries to 0 if Xcode 13 because TestCommandGenerator will set '-retry-tests-on-failure -test-iterations'
      if Helper.xcode_at_least?(13)
        retries = 0
        Scan.cache[:retry_attempt] = 0
      else
        Scan.cache[:retry_attempt] = Scan.config[:number_of_retries] - retries
      end

      command = @test_command_generator.generate

      prefix_hash = [
        {
          prefix: "Running Tests: ",
          block: proc do |value|
            value.include?("Touching")
          end
        }
      ]
      exit_status = 0

      FastlaneCore::CommandExecutor.execute(command: command, print_all: true, print_command: true,
                                             prefix: prefix_hash, loading: "Loading...",
                                    suppress_output: Scan.config[:suppress_xcode_output],
                                              error: proc do |error_output|
                                                begin
                                                  exit_status = $?.exitstatus
                                                  if retries > 0
                                                    # If there are retries remaining, run the tests again
                                                    return retry_execute(retries: retries, error_output: error_output)
                                                  else
                                                    ErrorHandler.handle_build_error(error_output, @test_command_generator.xcodebuild_log_path)
                                                  end
                                                rescue => ex
                                                  SlackPoster.new.run({
                                                    build_errors: 1
                                                  })
                                                  raise ex
                                                end
                                              end)

      exit_status
    end

    def retry_execute(retries:, error_output: "")
      tests = retryable_tests(error_output)

      if tests.empty?
        UI.build_failure!("Failed to find failed tests to retry (could not parse error output)")
      end

      Scan.config[:only_testing] = tests
      UI.important("Retrying tests: #{Scan.config[:only_testing].join(', ')}")

      retries -= 1
      UI.important("Number of retries remaining: #{retries}")

      return execute(retries: retries)
    end

    def retryable_tests(input)
      input = Helper.strip_ansi_colors(input)

      retryable_tests = []

      failing_tests = input.split("Failing tests:\n").fetch(1, []).split("\n\n").first

      suites = failing_tests.split(/(?=\n\s+[\w\s]+:\n)/)

      suites.each do |suite|
        suite_name = suite.match(/\s*([\w\s\S]+):/).captures.first

        test_cases = suite.split(":\n").fetch(1, []).split("\n").each
                          .select { |line| line.match?(/^\s+/) }
                          .map { |line| line.strip.gsub(/[\s\.]/, "/").gsub(/[\-\[\]\(\)]/, "") }
                          .map { |line| suite_name + "/" + line }

        retryable_tests += test_cases
      end

      return retryable_tests.uniq
    end

    def find_filename(type)
      index = Scan.config[:output_types].split(',').index(type)
      return nil if index.nil?
      return (Scan.config[:output_files] || "").split(',')[index]
    end

    def output_html?
      return Scan.config[:output_types].split(',').include?('html')
    end

    def output_junit?
      return Scan.config[:output_types].split(',').include?('junit')
    end

    def output_json_compilation_database?
      return Scan.config[:output_types].split(',').include?('json-compilation-database')
    end

    def output_html_filename
      return find_filename('html')
    end

    def output_junit_filename
      return find_filename('junit')
    end

    def output_json_compilation_database_filename
      return find_filename('json-compilation-database')
    end

    def find_xcresults_in_derived_data
      derived_data_path = Scan.config[:derived_data_path]
      return [] if derived_data_path.nil? # Swift packages might not have derived data

      xcresults_path = File.join(derived_data_path, "Logs", "Test", "*.xcresult")
      return Dir[xcresults_path]
    end

    def trainer_test_results
      require "trainer"

      results = {
        number_of_tests: 0,
        number_of_failures: 0,
        number_of_retries: 0,
        number_of_skipped: 0,
        number_of_tests_excluding_retries: 0,
        number_of_failures_excluding_retries: 0
      }

      result_bundle_path = Scan.cache[:result_bundle_path]

      # Looks for xcresult file in derived data if not specifically set
      if result_bundle_path.nil?
        xcresults = find_xcresults_in_derived_data
        new_xcresults = xcresults - @xcresults_before_run

        if new_xcresults.size != 1
          UI.build_failure!("Cannot find .xcresult in derived data which is needed to determine test results. This is an issue within scan. File an issue on GitHub or try setting option `result_bundle: true`")
        end

        result_bundle_path = new_xcresults.first
        Scan.cache[:result_bundle_path] = result_bundle_path
      end

      output_path = Scan.config[:output_directory] || Dir.mktmpdir
      output_path = File.absolute_path(output_path)

      UI.build_failure!("A -resultBundlePath is needed to parse the test results. This should not have happened. Please file an issue.") unless result_bundle_path

      params = {
        path: result_bundle_path,
        output_remove_retry_attempts: Scan.config[:output_remove_retry_attempts],
        silent: !FastlaneCore::Globals.verbose?
      }

      formatter = Scan.config[:xcodebuild_formatter].chomp
      show_output_types_tip = false
      if output_html? && formatter != 'xcpretty'
        UI.important("Skipping HTML... only available with `xcodebuild_formatter: 'xcpretty'` right now")
        show_output_types_tip = true
      end

      if output_json_compilation_database? && formatter != 'xcpretty'
        UI.important("Skipping JSON Compilation Database... only available with `xcodebuild_formatter: 'xcpretty'` right now")
        show_output_types_tip = true
      end

      if show_output_types_tip
        UI.important("Your 'xcodebuild_formatter' doesn't support these 'output_types'. Change your 'output_types' to prevent these warnings from showing...")
      end

      if output_junit?
        if formatter == 'xcpretty'
          UI.verbose("Generating junit report with xcpretty")
        else
          UI.verbose("Generating junit report with trainer")
          params[:output_filename] = output_junit_filename || "report.junit"
          params[:output_directory] = output_path
        end
      end

      resulting_paths = Trainer::TestParser.auto_convert(params)
      resulting_paths.each do |path, data|
        results[:number_of_tests] += data[:number_of_tests]
        results[:number_of_failures] += data[:number_of_failures]
        results[:number_of_tests_excluding_retries] += data[:number_of_tests_excluding_retries]
        results[:number_of_failures_excluding_retries] += data[:number_of_failures_excluding_retries]
        results[:number_of_skipped] += data[:number_of_skipped] || 0
        results[:number_of_retries] += data[:number_of_retries]
      end

      return results
    end

    def handle_results(tests_exit_status)
      copy_simulator_logs
      zip_build_products
      copy_xctestrun

      return nil if Scan.config[:build_for_testing]

      results = trainer_test_results

      number_of_retries = results[:number_of_retries]
      number_of_skipped = results[:number_of_skipped]
      number_of_tests = results[:number_of_tests_excluding_retries]
      number_of_failures = results[:number_of_failures_excluding_retries]

      SlackPoster.new.run({
        tests: number_of_tests,
        failures: number_of_failures
      })

      if number_of_failures > 0
        failures_str = number_of_failures.to_s.red
      else
        failures_str = number_of_failures.to_s.green
      end

      retries_str = case number_of_retries
                    when 0
                      ""
                    when 1
                      " (and 1 retry)"
                    else
                      " (and #{number_of_retries} retries)"
                    end

      puts(Terminal::Table.new({
        title: "Test Results",
        rows: [
          ["Number of tests", "#{number_of_tests}#{retries_str}"],
          number_of_skipped > 0 ? ["Number of tests skipped", number_of_skipped] : nil,
          ["Number of failures", failures_str]
        ].compact
      }))
      puts("")

      if number_of_failures > 0
        open_report

        if Scan.config[:fail_build]
          UI.test_failure!("Tests have failed")
        else
          UI.error("Tests have failed")
        end
      end

      unless tests_exit_status == 0
        if Scan.config[:fail_build]
          UI.test_failure!("Test execution failed. Exit status: #{tests_exit_status}")
        else
          UI.error("Test execution failed. Exit status: #{tests_exit_status}")
        end
      end

      open_report
      return results
    end

    def open_report
      if !Helper.ci? && Scan.cache[:open_html_report_path]
        `open --hide '#{Scan.cache[:open_html_report_path]}'`
      end
    end

    def zip_build_products
      return unless Scan.config[:should_zip_build_products]

      # Gets :derived_data_path/Build/Products directory for zipping zip
      derived_data_path = Scan.config[:derived_data_path]
      path = File.join(derived_data_path, "Build/Products")

      # Gets absolute path of output directory
      output_directory = File.absolute_path(Scan.config[:output_directory])
      output_path = File.join(output_directory, "build_products.zip")

      # Caching path for action to put into lane_context
      Scan.cache[:zip_build_products_path] = output_path

      # Zips build products and moves it to output directory
      UI.message("Zipping build products")
      FastlaneCore::Helper.zip_directory(path, output_path, contents_only: true, overwrite: true, print: false)
      UI.message("Successfully zipped build products: #{output_path}")
    end

    def copy_xctestrun
      return unless Scan.config[:output_xctestrun]

      # Gets :derived_data_path/Build/Products directory for coping .xctestrun file
      derived_data_path = Scan.config[:derived_data_path]
      path = File.join(derived_data_path, "Build", "Products")

      # Gets absolute path of output directory
      output_directory = File.absolute_path(Scan.config[:output_directory])
      output_path = File.join(output_directory, "settings.xctestrun")

      # Caching path for action to put into lane_context
      Scan.cache[:output_xctestrun] = output_path

      # Copy .xctestrun file and moves it to output directory
      UI.message("Copying .xctestrun file")
      xctestrun_file = Dir.glob("#{path}/*.xctestrun").first

      if xctestrun_file
        FileUtils.cp(xctestrun_file, output_path)
        UI.message("Successfully copied xctestrun file: #{output_path}")
      else
        UI.user_error!("Could not find .xctestrun file to copy")
      end
    end

    def test_results
      temp_junit_report = Scan.cache[:temp_junit_report]
      return File.read(temp_junit_report) if temp_junit_report && File.file?(temp_junit_report)

      # Something went wrong with the temp junit report for the test success/failures count.
      # We'll have to regenerate from the xcodebuild log, like we did before version 2.34.0.
      UI.message("Generating test results. This may take a while for large projects.")

      reporter_options_generator = XCPrettyReporterOptionsGenerator.new(false, [], [], "", false, nil)
      reporter_options = reporter_options_generator.generate_reporter_options
      xcpretty_args_options = reporter_options_generator.generate_xcpretty_args_options
      cmd = "cat #{@test_command_generator.xcodebuild_log_path.shellescape} | xcpretty #{reporter_options.join(' ')} #{xcpretty_args_options} &> /dev/null"
      system(cmd)
      File.read(Scan.cache[:temp_junit_report])
    end

    def prelaunch_simulators
      return unless Scan.devices.to_a.size > 0 # no devices selected, no sims to launch

      # Return early unless the user wants to prelaunch simulators. Or if the user wants simulator logs
      # then we must prelaunch simulators because Xcode's headless
      # mode launches and shuts down the simulators before we can collect the logs.
      return unless Scan.config[:prelaunch_simulator] || Scan.config[:include_simulator_logs]

      devices_to_shutdown = []
      Scan.devices.each do |device|
        devices_to_shutdown << device if device.state == "Shutdown"
        device.boot
      end
      at_exit do
        devices_to_shutdown.each(&:shutdown)
      end
    end

    def copy_simulator_logs
      return unless Scan.config[:include_simulator_logs]

      UI.header("Collecting system logs")
      Scan.devices.each do |device|
        log_identity = "#{device.name}_#{device.os_type}_#{device.os_version}"
        if device.os_type == "iOS"
          FastlaneCore::Simulator.copy_logs(device, log_identity, Scan.config[:output_directory], @device_boot_datetime)
        elsif device.os_type == "visionOS"
          FastlaneCore::SimulatorVision.copy_logs(device, log_identity, Scan.config[:output_directory], @device_boot_datetime)
        end
      end
    end

    def force_quit_simulator_processes
      # Silently execute and kill, verbose flags will show this command occurring
      Fastlane::Actions.sh("killall Simulator &> /dev/null || true", log: false)
    end
  end
end
