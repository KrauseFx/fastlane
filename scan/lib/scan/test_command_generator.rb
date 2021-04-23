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
      ["set -o pipefail &&"]
    end

    # Path to the project or workspace as parameter
    # This will also include the scheme (if given)
    # @return [Array] The array with all the components to join
    def project_path_array
      proj = Scan.project.xcodebuild_parameters
      return proj if proj.count > 0
      UI.user_error!("No project/workspace found")
    end

    def options # rubocop:disable Metrics/PerceivedComplexity
      config = Scan.config

      options = []
      options += project_path_array unless config[:xctestrun]
      options << "-sdk '#{config[:sdk]}'" if config[:sdk]
      options << destination # generated in `detect_values`
      options << "-toolchain '#{config[:toolchain]}'" if config[:toolchain]
      if config[:derived_data_path] && !options.include?("-derivedDataPath #{config[:derived_data_path].shellescape}")
        options << "-derivedDataPath #{config[:derived_data_path].shellescape}"
      end
      if config[:use_system_scm] && !options.include?("-scmProvider system")
        options << "-scmProvider system"
      end
      options << "-resultBundlePath '#{result_bundle_path}'" if config[:result_bundle]
      if FastlaneCore::Helper.xcode_at_least?(10)
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
      []
    end

    def pipe
      pipe = ["| tee '#{xcodebuild_log_path}'"]

      if Scan.config[:disable_xcpretty] || Scan.config[:output_style] == 'raw'
        return pipe
      end

      formatter = []
      if (custom_formatter = Scan.config[:formatter])
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
      return pipe << "| xcpretty #{formatter.join(' ')} #{reporter_options.join(' ')} #{reporter_xcpretty_args}"
    end

    # Store the raw file
    def xcodebuild_log_path
      file_name = "#{Scan.config[:app_name] || Scan.project.app_name}-#{Scan.config[:scheme]}.log"
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
    def result_bundle_path
      retry_count = Scan.cache[:retry_attempt] || 0
      attempt = retry_count > 0 ? "-#{retry_count}" : ""
      ext = FastlaneCore::Helper.xcode_version.to_i >= 11 ? '.xcresult' : '.test_result'
      path = File.join(Scan.config[:output_directory], Scan.config[:scheme]) + attempt + ext
      if File.directory?(path)
        FileUtils.remove_dir(path)
      end
      Scan.cache[:result_bundle_path] = path

      return path
    end
  end
end
