require 'plist'

require 'fastlane_core/print_table'

require_relative 'junit_generator'
require_relative 'xcresult'
require_relative 'module'

module Trainer
  class TestParser
    attr_accessor :data

    attr_accessor :file_content

    attr_accessor :raw_json

    attr_accessor :number_of_tests
    attr_accessor :number_of_failures
    attr_accessor :number_of_tests_excluding_retries
    attr_accessor :number_of_failures_excluding_retries
    attr_accessor :number_of_retries
    attr_accessor :number_of_skipped

    # Returns a hash with the path being the key, and the value
    # defining if the tests were successful
    def self.auto_convert(config)
      unless config[:silent]
        FastlaneCore::PrintTable.print_values(config: config,
                                               title: "Summary for trainer #{Fastlane::VERSION}")
      end

      containing_dir = config[:path]
      # Xcode < 10
      files = Dir["#{containing_dir}/**/Logs/Test/*TestSummaries.plist"]
      files += Dir["#{containing_dir}/Test/*TestSummaries.plist"]
      files += Dir["#{containing_dir}/*TestSummaries.plist"]
      # Xcode 10
      files += Dir["#{containing_dir}/**/Logs/Test/*.xcresult/TestSummaries.plist"]
      files += Dir["#{containing_dir}/Test/*.xcresult/TestSummaries.plist"]
      files += Dir["#{containing_dir}/*.xcresult/TestSummaries.plist"]
      files += Dir[containing_dir] if containing_dir.end_with?(".plist") # if it's the exact path to a plist file
      # Xcode 11
      files += Dir["#{containing_dir}/**/Logs/Test/*.xcresult"]
      files += Dir["#{containing_dir}/Test/*.xcresult"]
      files += Dir["#{containing_dir}/*.xcresult"]
      files << containing_dir if File.extname(containing_dir) == ".xcresult"

      if files.empty?
        UI.user_error!("No test result files found in directory '#{containing_dir}', make sure the file name ends with 'TestSummaries.plist' or '.xcresult'")
      end

      return_hash = {}
      files.each do |path|
        extension = config[:extension]
        output_filename = config[:output_filename]

        should_write_file = !extension.nil? || !output_filename.nil?

        if should_write_file
          if config[:output_directory]
            FileUtils.mkdir_p(config[:output_directory])
            # Remove .xcresult or .plist extension
            # Use custom file name ONLY if one file otherwise issues
            if files.size == 1 && output_filename
              filename = output_filename
            elsif path.end_with?(".xcresult")
              filename ||= File.basename(path).gsub(".xcresult", extension)
            else
              filename ||= File.basename(path).gsub(".plist", extension)
            end
            to_path = File.join(config[:output_directory], filename)
          else
            # Remove .xcresult or .plist extension
            if path.end_with?(".xcresult")
              to_path = path.gsub(".xcresult", extension)
            else
              to_path = path.gsub(".plist", extension)
            end
          end
        end

        tp = Trainer::TestParser.new(path, config)
        File.write(to_path, tp.to_junit) if should_write_file
        UI.success("Successfully generated '#{to_path}'") if should_write_file && !config[:silent]

        return_hash[path] = {
          to_path: to_path,
          successful: tp.tests_successful?,
          number_of_tests: tp.number_of_tests,
          number_of_failures: tp.number_of_failures,
          number_of_tests_excluding_retries: tp.number_of_tests_excluding_retries,
          number_of_failures_excluding_retries: tp.number_of_failures_excluding_retries,
          number_of_retries: tp.number_of_retries,
          number_of_skipped: tp.number_of_skipped
        }
      end
      return_hash
    end

    def initialize(path, config = {})
      path = File.expand_path(path)
      UI.user_error!("File not found at path '#{path}'") unless File.exist?(path)

      if File.directory?(path) && path.end_with?(".xcresult")
        parse_xcresult(path, output_remove_retry_attempts: config[:output_remove_retry_attempts])
      else
        self.file_content = File.read(path)
        self.raw_json = Plist.parse_xml(self.file_content)

        return if self.raw_json["FormatVersion"].to_s.length.zero? # maybe that's a useless plist file

        ensure_file_valid!
        parse_content(config[:xcpretty_naming])
      end

      self.number_of_tests = 0
      self.number_of_failures = 0
      self.number_of_tests_excluding_retries = 0
      self.number_of_failures_excluding_retries = 0
      self.number_of_retries = 0
      self.number_of_skipped = 0
      self.data.each do |thing|
        self.number_of_tests += thing[:number_of_tests].to_i
        self.number_of_failures += thing[:number_of_failures].to_i
        self.number_of_tests_excluding_retries += thing[:number_of_tests_excluding_retries].to_i
        self.number_of_failures_excluding_retries += thing[:number_of_failures_excluding_retries].to_i
        self.number_of_retries += thing[:number_of_retries].to_i
        self.number_of_skipped += thing[:number_of_skipped].to_i
      end
    end

    # Returns the JUnit report as String
    def to_junit
      JunitGenerator.new(self.data).generate
    end

    # @return [Bool] were all tests successful? Is false if at least one test failed
    def tests_successful?
      self.data.collect { |a| a[:number_of_failures_excluding_retries] }.all?(&:zero?)
    end

    private

    def ensure_file_valid!
      format_version = self.raw_json["FormatVersion"]
      supported_versions = ["1.1", "1.2"]
      UI.user_error!("Format version '#{format_version}' is not supported, must be #{supported_versions.join(', ')}") unless supported_versions.include?(format_version)
    end

    # Converts the raw plist test structure into something that's easier to enumerate
    def unfold_tests(data)
      # `data` looks like this
      # => [{"Subtests"=>
      #  [{"Subtests"=>
      #     [{"Subtests"=>
      #        [{"Duration"=>0.4,
      #          "TestIdentifier"=>"Unit/testExample()",
      #          "TestName"=>"testExample()",
      #          "TestObjectClass"=>"IDESchemeActionTestSummary",
      #          "TestStatus"=>"Success",
      #          "TestSummaryGUID"=>"4A24BFED-03E6-4FBE-BC5E-2D80023C06B4"},
      #         {"FailureSummaries"=>
      #           [{"FileName"=>"/Users/krausefx/Developer/themoji/Unit/Unit.swift",
      #             "LineNumber"=>34,
      #             "Message"=>"XCTAssertTrue failed - ",
      #             "PerformanceFailure"=>false}],
      #          "TestIdentifier"=>"Unit/testExample2()",

      tests = []
      data.each do |current_hash|
        if current_hash["Subtests"]
          tests += unfold_tests(current_hash["Subtests"])
        end
        if current_hash["TestStatus"]
          tests << current_hash
        end
      end
      return tests
    end

    # Returns the test group and test name from the passed summary and test
    # Pass xcpretty_naming = true to get the test naming aligned with xcpretty
    def test_group_and_name(testable_summary, test, xcpretty_naming)
      if xcpretty_naming
        group = testable_summary["TargetName"] + "." + test["TestIdentifier"].split("/")[0..-2].join(".")
        name = test["TestName"][0..-3]
      else
        group = test["TestIdentifier"].split("/")[0..-2].join(".")
        name = test["TestName"]
      end
      return group, name
    end

    def execute_cmd(cmd)
      output = `#{cmd}`
      raise "Failed to execute - #{cmd}" unless $?.success?
      return output
    end

    # Hotfix: From Xcode 16 beta 3 'xcresulttool get --format json' has been deprecated;
    #         '--legacy' flag required to keep on using the command
    def generate_cmd_parse_xcresult(path)
      xcresulttool_cmd = %W(
        xcrun
        xcresulttool
        get
        --format
        json
        --path
        #{path}
      )

      # e.g. DEVELOPER_DIR=/Applications/Xcode_16_beta_3.app
      # xcresulttool version 23021, format version 3.53 (current)
      match = `xcrun xcresulttool version`.match(/xcresulttool version (?<version>[\d.]+)/)
      version = match[:version]
      xcresulttool_cmd << '--legacy' if Gem::Version.new(version) >= Gem::Version.new(23_021)

      xcresulttool_cmd.join(' ')
    end

    def parse_xcresult(path, output_remove_retry_attempts: false)
      require 'shellwords'
      path = Shellwords.escape(path)

      # Executes xcresulttool to get JSON format of the result bundle object
      # Hotfix: From Xcode 16 beta 3 'xcresulttool get --format json' has been deprecated; '--legacy' flag required to keep on using the command
      xcresulttool_cmd = generate_cmd_parse_xcresult(path)

      result_bundle_object_raw = execute_cmd(xcresulttool_cmd)
      result_bundle_object = JSON.parse(result_bundle_object_raw)

      # Parses JSON into ActionsInvocationRecord to find a list of all ids for ActionTestPlanRunSummaries
      actions_invocation_record = Trainer::XCResult::ActionsInvocationRecord.new(result_bundle_object)
      test_refs = actions_invocation_record.actions.map do |action|
        action.action_result.tests_ref
      end.compact
      ids = test_refs.map(&:id)

      # Maps ids into ActionTestPlanRunSummaries by executing xcresulttool to get JSON
      # containing specific information for each test summary,
      summaries = ids.map do |id|
        raw = execute_cmd("#{xcresulttool_cmd} --id #{id}")
        json = JSON.parse(raw)
        Trainer::XCResult::ActionTestPlanRunSummaries.new(json)
      end

      # Converts the ActionTestPlanRunSummaries to data for junit generator
      failures = actions_invocation_record.issues.test_failure_summaries || []
      summaries_to_data(summaries, failures, output_remove_retry_attempts: output_remove_retry_attempts)
    end

    def summaries_to_data(summaries, failures, output_remove_retry_attempts: false)
      # Gets flat list of all ActionTestableSummary
      all_summaries = summaries.map(&:summaries).flatten
      testable_summaries = all_summaries.map(&:testable_summaries).flatten

      summaries_to_names = test_summaries_to_configuration_names(all_summaries)

      # Maps ActionTestableSummary to rows for junit generator
      rows = testable_summaries.map do |testable_summary|
        all_tests = testable_summary.all_tests.flatten

        # Used by store number of passes and failures by identifier
        # This is used when Xcode 13 (and up) retries tests
        # The identifier is duplicated until test succeeds or max count is reached
        tests_by_identifier = {}

        test_rows = all_tests.map do |test|
          identifier = "#{test.parent.name}.#{test.name}"
          test_row = {
            identifier: identifier,
            name: test.name,
            duration: test.duration,
            status: test.test_status,
            test_group: test.parent.name,

            # These don't map to anything but keeping empty strings
            guid: ""
          }

          info = tests_by_identifier[identifier] || {}
          info[:failure_count] ||= 0
          info[:skip_count] ||= 0
          info[:success_count] ||= 0

          retry_count = info[:retry_count]
          if retry_count.nil?
            retry_count = 0
          else
            retry_count += 1
          end
          info[:retry_count] = retry_count

          case test.test_status
          when "Failure"
            test_row[:failures] = [{
              file_name: "",
              line_number: 0,
              message: "",
              performance_failure: {},
              failure_message: test.failure_message(failures)
            }]
            info[:failure_count] += 1
          when "Skipped"
            test_row[:skipped] = true
            info[:skip_count] += 1
          else
            info[:success_count] = 1
          end

          tests_by_identifier[identifier] = info

          test_row
        end

        # Remove retry attempts from the count and test rows
        if output_remove_retry_attempts
          test_rows = test_rows.reject do |test_row|
            remove = false

            identifier = test_row[:identifier]
            info = tests_by_identifier[identifier]

            # Remove if this row is a retry and is a failure
            if info[:retry_count] > 0
              remove = !(test_row[:failures] || []).empty?
            end

            # Remove all failure and retry count if test did eventually pass
            if remove
              info[:failure_count] -= 1
              info[:retry_count] -= 1
              tests_by_identifier[identifier] = info
            end

            remove
          end
        end

        row = {
          project_path: testable_summary.project_relative_path,
          target_name: testable_summary.target_name,
          test_name: testable_summary.name,
          configuration_name: summaries_to_names[testable_summary],
          duration: all_tests.map(&:duration).inject(:+),
          tests: test_rows
        }

        row[:number_of_tests] = row[:tests].count
        row[:number_of_failures] = row[:tests].find_all { |a| (a[:failures] || []).count > 0 }.count

        # Used for seeing if any tests continued to fail after all of the Xcode 13 (and up) retries have finished
        unique_tests = tests_by_identifier.values || []
        row[:number_of_tests_excluding_retries] = unique_tests.count
        row[:number_of_skipped] = unique_tests.map { |a| a[:skip_count] }.inject(:+)
        row[:number_of_failures_excluding_retries] = unique_tests.find_all { |a| (a[:success_count] + a[:skip_count]) == 0 }.count
        row[:number_of_retries] = unique_tests.map { |a| a[:retry_count] }.inject(:+)

        row
      end

      self.data = rows
    end

    def test_summaries_to_configuration_names(test_summaries)
      summary_to_name = {}
      test_summaries.each do |summary|
        summary.testable_summaries.each do |testable_summary|
          summary_to_name[testable_summary] = summary.name
        end
      end
      summary_to_name
    end

    # Convert the Hashes and Arrays in something more useful
    def parse_content(xcpretty_naming)
      self.data = self.raw_json["TestableSummaries"].collect do |testable_summary|
        summary_row = {
          project_path: testable_summary["ProjectPath"],
          target_name: testable_summary["TargetName"],
          test_name: testable_summary["TestName"],
          duration: testable_summary["Tests"].map { |current_test| current_test["Duration"] }.inject(:+),
          tests: unfold_tests(testable_summary["Tests"]).collect do |current_test|
            test_group, test_name = test_group_and_name(testable_summary, current_test, xcpretty_naming)
            current_row = {
              identifier: current_test["TestIdentifier"],
                 test_group: test_group,
                 name: test_name,
              object_class: current_test["TestObjectClass"],
              status: current_test["TestStatus"],
              guid: current_test["TestSummaryGUID"],
              duration: current_test["Duration"]
            }
            if current_test["FailureSummaries"]
              current_row[:failures] = current_test["FailureSummaries"].collect do |current_failure|
                {
                  file_name: current_failure['FileName'],
                  line_number: current_failure['LineNumber'],
                  message: current_failure['Message'],
                  performance_failure: current_failure['PerformanceFailure'],
                  failure_message: "#{current_failure['Message']} (#{current_failure['FileName']}:#{current_failure['LineNumber']})"
                }
              end
            end
            current_row
          end
        }
        summary_row[:number_of_tests] = summary_row[:tests].count
        summary_row[:number_of_failures] = summary_row[:tests].find_all { |a| (a[:failures] || []).count > 0 }.count

        # Makes sure that plist support matches data output of xcresult
        summary_row[:number_of_tests_excluding_retries] = summary_row[:number_of_tests]
        summary_row[:number_of_failures_excluding_retries] = summary_row[:number_of_failures]
        summary_row[:number_of_retries] = 0

        summary_row
      end
    end
  end
end
