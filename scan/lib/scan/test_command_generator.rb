require_relative 'xcpretty_reporter_options_generator'

module Scan
  # Responsible for building the fully working xcodebuild command
  class TestCommandGenerator
    def generate
      parts = prefix
      parts << Scan.config[:xcodebuild_command]
      parts += options
      parts += actions
      parts += suffix
      parts += pipe

      parts
    end

    def prefix
      prefixes = ["set -o pipefail &&"]

      package_path = Scan.config[:package_path]
      prefixes << "cd #{package_path} &&" if package_path.to_s != ""

      prefixes
    end

    # Path to the project or workspace as parameter
    # This will also include the scheme (if given)
    # @return [Array] The array with all the components to join
    def project_path_array
      unless Scan.config[:package_path].nil?
        params = []
        params << "-scheme #{Scan.config[:scheme].shellescape}" if Scan.config[:scheme]
        params << "-workspace #{Scan.config[:workspace].shellescape}" if Scan.config[:workspace]
        return params
      end

      proj = Scan.project.xcodebuild_parameters
      return proj if proj.count > 0
      UI.user_error!("No project/workspace found")
    end

    def options # rubocop:disable Metrics/PerceivedComplexity
      config = Scan.config

      options = []
      options += project_path_array unless config[:xctestrun]
      options << "-sdk '#{config[:sdk]}'" if config[:sdk]
      options << destination if destination # generated in `detect_values`
      options << "-toolchain '#{config[:toolchain]}'" if config[:toolchain]
      if config[:derived_data_path] && !options.include?("-derivedDataPath #{config[:derived_data_path].shellescape}")
        options << "-derivedDataPath #{config[:derived_data_path].shellescape}"
      end
      if config[:use_system_scm] && !options.include?("-scmProvider system")
        options << "-scmProvider system"
      end
      if config[:result_bundle_path]
        options << "-resultBundlePath '#{config[:result_bundle_path].shellescape}'"
        Scan.cache[:result_bundle_path] = config[:result_bundle_path]
      elsif config[:result_bundle]
        options << "-resultBundlePath '#{result_bundle_path(true)}'"
      end
      if FastlaneCore::Helper.xcode_at_least?(10)
        options << "-parallel-testing-enabled #{config[:parallel_testing] ? 'YES' : 'NO'}" unless config[:parallel_testing].nil?
        options << "-parallel-testing-worker-count #{config[:concurrent_workers]}" if config[:concurrent_workers]
        options << "-maximum-concurrent-test-simulator-destinations #{config[:max_concurrent_simulators]}" if config[:max_concurrent_simulators]
        options << "-disable-concurrent-testing" if config[:disable_concurrent_testing]
      end
      options << "-enableCodeCoverage #{config[:code_coverage] ? 'YES' : 'NO'}" unless config[:code_coverage].nil?
      options << "-enableAddressSanitizer #{config[:address_sanitizer] ? 'YES' : 'NO'}" unless config[:address_sanitizer].nil?
      options << "-enableThreadSanitizer #{config[:thread_sanitizer] ? 'YES' : 'NO'}" unless config[:thread_sanitizer].nil?
      if FastlaneCore::Helper.xcode_at_least?(11)
        options << "-testPlan '#{config[:testplan]}'" if config[:testplan]

        # detect_values will ensure that these values are present as Arrays if
        # they are present at all
        options += config[:only_test_configurations].map { |name| "-only-test-configuration '#{name}'" } if config[:only_test_configurations]
        options += config[:skip_test_configurations].map { |name| "-skip-test-configuration '#{name}'" } if config[:skip_test_configurations]
      end
      options << "-xctestrun '#{config[:xctestrun]}'" if config[:xctestrun]
      options << config[:xcargs] if config[:xcargs]

      # Number of retries does not equal xcodebuild's -test-iterations number
      # It needs include 1 iteration by default
      number_of_retries = config[:number_of_retries] + 1
      if number_of_retries > 1 && FastlaneCore::Helper.xcode_at_least?(13)
        options << "-retry-tests-on-failure"
        options << "-test-iterations #{number_of_retries}"
      end

      # detect_values will ensure that these values are present as Arrays if
      # they are present at all
      options += config[:only_testing].map { |test_id| "-only-testing:#{test_id.shellescape}" } if config[:only_testing]
      options += config[:skip_testing].map { |test_id| "-skip-testing:#{test_id.shellescape}" } if config[:skip_testing]

      options
    end

    def actions
      config = Scan.config

      actions = []
      actions << :clean if config[:clean]

      if config[:build_for_testing]
        actions << "build-for-testing"
      elsif config[:test_without_building] || config[:xctestrun]
        actions << "test-without-building"
      else
        actions << :build unless config[:skip_build]
        actions << :test
      end

      actions
    end

    def suffix
      suffix = []
      suffix
    end

    def pipe
      pipe = ["| tee '#{xcodebuild_log_path}'"]

      # disable_xcpretty is now deprecated and directs to use output_style of raw
      if Scan.config[:disable_xcpretty] || Scan.config[:output_style] == 'raw'
        return pipe
      end

      formatter = Scan.config[:xcodebuild_formatter].chomp
      options = legacy_xcpretty_options

      if formatter == ''
        UI.verbose("Not using an xcodebuild formatter")
      elsif !options.empty?
        UI.important("Detected legacy xcpretty being used, so formatting with xcpretty")
        UI.important("Option(s) used: #{options.join(', ')}")
        pipe << pipe_xcpretty
      elsif formatter == 'xcpretty'
        pipe << pipe_xcpretty
      elsif formatter == 'xcbeautify'
        pipe << pipe_xcbeautify
      else
        pipe << "| #{formatter}"
      end

      return pipe
    end

    def pipe_xcbeautify
      formatter = ['| xcbeautify']

      if FastlaneCore::Helper.colors_disabled?
        formatter << '--disable-colored-output'
      end

      return formatter.join(' ')
    end

    def legacy_xcpretty_options
      options = []

      options << "formatter" if Scan.config[:formatter]
      options << "xcpretty_formatter" if Scan.config[:xcpretty_formatter]
      options << "output_style" if Scan.config[:output_style]
      options << "output_types" if (Scan.config[:output_types] || "").include?("json-compilation-database")
      options << "custom_report_file_name" if Scan.config[:custom_report_file_name]

      return options
    end

    def pipe_xcpretty
      formatter = []
      if (custom_formatter = Scan.config[:xcpretty_formatter] || Scan.config[:formatter])
        if custom_formatter.end_with?(".rb")
          formatter << "-f '#{custom_formatter}'"
        else
          formatter << "-f `#{custom_formatter}`"
        end
      elsif FastlaneCore::Env.truthy?("TRAVIS")
        formatter << "-f `xcpretty-travis-formatter`"
        UI.success("Automatically switched to Travis formatter")
      end

      if Helper.colors_disabled?
        formatter << "--no-color"
      end

      if Scan.config[:output_style] == 'basic'
        formatter << "--no-utf"
      end

      if Scan.config[:output_style] == 'rspec'
        formatter << "--test"
      end

      @reporter_options_generator = XCPrettyReporterOptionsGenerator.new(Scan.config[:open_report],
                                                                         Scan.config[:output_types],
                                                                         Scan.config[:output_files] || Scan.config[:custom_report_file_name],
                                                                         Scan.config[:output_directory],
                                                                         Scan.config[:use_clang_report_name],
                                                                         Scan.config[:xcpretty_args])
      reporter_options = @reporter_options_generator.generate_reporter_options
      reporter_xcpretty_args = @reporter_options_generator.generate_xcpretty_args_options
      return "| xcpretty #{formatter.join(' ')} #{reporter_options.join(' ')} #{reporter_xcpretty_args}"
    end

    # Store the raw file
    def xcodebuild_log_path
      parts = []
      if Scan.config[:app_name]
        parts << Scan.config[:app_name]
      elsif Scan.project
        parts << Scan.project.app_name
      end
      parts << Scan.config[:scheme] if Scan.config[:scheme]

      file_name = "#{parts.join('-')}.log"
      containing = File.expand_path(Scan.config[:buildlog_path])
      FileUtils.mkdir_p(containing)

      return File.join(containing, file_name)
    end

    # Generate destination parameters
    def destination
      unless Scan.cache[:destination]
        Scan.cache[:destination] = [*Scan.config[:destination]].map { |dst| "-destination '#{dst}'" }.join(' ')
      end
      Scan.cache[:destination]
    end

    # The path to set the Derived Data to
    def build_path
      unless Scan.cache[:build_path]
        day = Time.now.strftime("%F") # e.g. 2015-08-07

        Scan.cache[:build_path] = File.expand_path("~/Library/Developer/Xcode/Archives/#{day}/")
        FileUtils.mkdir_p(Scan.cache[:build_path])
      end
      Scan.cache[:build_path]
    end

    # The path to the result bundle
    def result_bundle_path(use_output_directory)
      root_dir = use_output_directory ? File.join(Dir.pwd, Scan.config[:output_directory]) : Dir.mktmpdir

      retry_count = Scan.cache[:retry_attempt] || 0
      attempt = retry_count > 0 ? "-#{retry_count}" : ""
      ext = FastlaneCore::Helper.xcode_version.to_i >= 11 ? '.xcresult' : '.test_result'
      path = File.join([root_dir, Scan.config[:scheme]].compact) + attempt + ext

      Scan.cache[:result_bundle_path] = path

      delete_path = path
      FileUtils.remove_dir(delete_path) if File.directory?(delete_path)

      # The result bundle path will be in the package path directory if specified
      delete_path = File.join(Scan.config[:package_path], path) if Scan.config[:package_path].to_s != ""
      FileUtils.remove_dir(delete_path) if File.directory?(delete_path)

      return path
    end
  end
end
