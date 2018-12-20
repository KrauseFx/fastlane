require 'fastlane_core/configuration/config_item'
require 'credentials_manager/appfile_config'
require_relative 'module'

module Scan
  # rubocop:disable Metrics/ClassLength
  class Options
    def self.verify_type(item_name, acceptable_types, value)
      type_ok = [Array, String].any? { |type| value.kind_of?(type) }
      UI.user_error!("'#{item_name}' should be of type #{acceptable_types.join(' or ')} but found: #{value.class.name}") unless type_ok
    end

    def self.available_options
      containing = FastlaneCore::Helper.fastlane_enabled_folder_path

      [
        # app to test
        FastlaneCore::ConfigItem.new(key: :workspace,
                                     short_option: "-w",
                                     env_name: "SCAN_WORKSPACE",
                                     optional: true,
                                     description: "Path to the workspace file",
                                     verify_block: proc do |value|
                                       v = File.expand_path(value.to_s)
                                       UI.user_error!("Workspace file not found at path '#{v}'") unless File.exist?(v)
                                       UI.user_error!("Workspace file invalid") unless File.directory?(v)
                                       UI.user_error!("Workspace file is not a workspace, must end with .xcworkspace") unless v.include?(".xcworkspace")
                                     end),
        FastlaneCore::ConfigItem.new(key: :project,
                                     short_option: "-p",
                                     optional: true,
                                     env_name: "SCAN_PROJECT",
                                     description: "Path to the project file",
                                     verify_block: proc do |value|
                                       v = File.expand_path(value.to_s)
                                       UI.user_error!("Project file not found at path '#{v}'") unless File.exist?(v)
                                       UI.user_error!("Project file invalid") unless File.directory?(v)
                                       UI.user_error!("Project file is not a project file, must end with .xcodeproj") unless v.include?(".xcodeproj")
                                     end),
        FastlaneCore::ConfigItem.new(key: :scheme,
                                     short_option: "-s",
                                     optional: true,
                                     env_name: "SCAN_SCHEME",
                                     description: "The project's scheme. Make sure it's marked as `Shared`"),

        # device (simulator) to use for testing
        FastlaneCore::ConfigItem.new(key: :device,
                                     short_option: "-a",
                                     optional: true,
                                     is_string: true,
                                     env_name: "SCAN_DEVICE",
                                     description: "The name of the simulator type you want to run tests on (e.g. 'iPhone 6')",
                                     conflicting_options: [:devices],
                                     conflict_block: proc do |value|
                                       UI.user_error!("You can't use 'device' and 'devices' options in one run")
                                     end),
        FastlaneCore::ConfigItem.new(key: :devices,
                                     optional: true,
                                     is_string: false,
                                     env_name: "SCAN_DEVICES",
                                     type: Array,
                                     description: "Array of devices to run the tests on (e.g. ['iPhone 6', 'iPad Air'])",
                                     conflicting_options: [:device],
                                     conflict_block: proc do |value|
                                       UI.user_error!("You can't use 'device' and 'devices' options in one run")
                                     end),
        FastlaneCore::ConfigItem.new(key: :skip_detect_devices,
                                     description: "Should skip auto detecting of devices if none were specified",
                                     default_value: false,
                                     type: Boolean,
                                     optional: true),

        # reinstall app
        FastlaneCore::ConfigItem.new(key: :reinstall_app,
                                     env_name: 'SCAN_REINSTALL_APP',
                                     description: "Enabling this option will automatically uninstall the application before running it",
                                     default_value: false,
                                     is_string: false),
        FastlaneCore::ConfigItem.new(key: :app_identifier,
                                     env_name: 'SCAN_APP_IDENTIFIER',
                                     optional: true,
                                     description: "The bundle identifier of the app to uninstall (only needed when enabling reinstall_app)",
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier),
                                     default_value_dynamic: true),

        # tests to run
        FastlaneCore::ConfigItem.new(key: :only_testing,
                                     env_name: "SCAN_ONLY_TESTING",
                                     description: "Array of strings matching Test Bundle/Test Suite/Test Cases to run",
                                     optional: true,
                                     is_string: false,
                                     verify_block: proc do |value|
                                       verify_type('only_testing', [Array, String], value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :skip_testing,
                                     env_name: "SCAN_SKIP_TESTING",
                                     description: "Array of strings matching Test Bundle/Test Suite/Test Cases to skip",
                                     optional: true,
                                     is_string: false,
                                     verify_block: proc do |value|
                                       verify_type('skip_testing', [Array, String], value)
                                     end),

        # other test options
        FastlaneCore::ConfigItem.new(key: :xctestrun,
                                     short_option: "-X",
                                     env_name: "SCAN_XCTESTRUN",
                                     description: "Run tests using the provided `.xctestrun` file",
                                     conflicting_options: [:build_for_testing],
                                     is_string: true,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :toolchain,
                                     env_name: "SCAN_TOOLCHAIN",
                                     conflicting_options: [:xctestrun],
                                     description: "The toolchain that should be used for building the application (e.g. `com.apple.dt.toolchain.Swift_2_3, org.swift.30p620160816a`)",
                                     optional: true,
                                     is_string: false),
        FastlaneCore::ConfigItem.new(key: :clean,
                                     short_option: "-c",
                                     env_name: "SCAN_CLEAN",
                                     description: "Should the project be cleaned before building it?",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :code_coverage,
                                     description: "Should code coverage be generated? (Xcode 7 and up)",
                                     is_string: false,
                                     type: Boolean,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :address_sanitizer,
                                     description: "Should the address sanitizer be turned on?",
                                     is_string: false,
                                     type: Boolean,
                                     optional: true,
                                     conflicting_options: [:thread_sanitizer],
                                     conflict_block: proc do |value|
                                       UI.user_error!("You can't use 'address_sanitizer' and 'thread_sanitizer' options in one run")
                                     end),
        FastlaneCore::ConfigItem.new(key: :thread_sanitizer,
                                     description: "Should the thread sanitizer be turned on?",
                                     is_string: false,
                                     type: Boolean,
                                     optional: true,
                                     conflicting_options: [:address_sanitizer],
                                     conflict_block: proc do |value|
                                       UI.user_error!("You can't use 'thread_sanitizer' and 'address_sanitizer' options in one run")
                                     end),

        # output
        FastlaneCore::ConfigItem.new(key: :open_report,
                                     short_option: "-g",
                                     env_name: "SCAN_OPEN_REPORT",
                                     description: "Should the HTML report be opened when tests are completed?",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :output_directory,
                                     short_option: "-o",
                                     env_name: "SCAN_OUTPUT_DIRECTORY",
                                     description: "The directory in which all reports will be stored",
                                     code_gen_sensitive: true,
                                     code_gen_default_value: "./test_output",
                                     default_value: File.join(containing, "test_output"),
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :output_style,
                                     short_option: "-b",
                                     env_name: "SCAN_OUTPUT_STYLE",
                                     description: "Define how the output should look like. Valid values are: standard, basic, rspec, or raw (disables xcpretty)",
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Invalid output_style #{value}") unless ['standard', 'basic', 'rspec', 'raw'].include?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :output_types,
                                     short_option: "-f",
                                     env_name: "SCAN_OUTPUT_TYPES",
                                     description: "Comma separated list of the output types (e.g. html, junit, json-compilation-database)",
                                     default_value: "html,junit"),
        FastlaneCore::ConfigItem.new(key: :output_files,
                                     env_name: "SCAN_OUTPUT_FILES",
                                     description: "Comma separated list of the output files, corresponding to the types provided by :output_types (order should match). If specifying an output type of json-compilation-database with :use_clang_report_name enabled, that option will take precedence",
                                     conflicting_options: [:custom_report_file_name],
                                     optional: true,
                                     default_value: nil),
        FastlaneCore::ConfigItem.new(key: :buildlog_path,
                                     short_option: "-l",
                                     env_name: "SCAN_BUILDLOG_PATH",
                                     description: "The directory where to store the raw log",
                                     default_value: "#{FastlaneCore::Helper.buildlog_path}/scan",
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :include_simulator_logs,
                                     env_name: "SCAN_INCLUDE_SIMULATOR_LOGS",
                                     description: "If the logs generated by the app (e.g. using NSLog, perror, etc.) in the Simulator should be written to the output_directory",
                                     type: Boolean,
                                     default_value: false,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :suppress_xcode_output,
                                     env_name: "SCAN_SUPPRESS_XCODE_OUTPUT",
                                     description: "Suppress the output of xcodebuild to stdout. Takes precedence over `enabled_xcode_output`. Output is still saved in buildlog_path",
                                     optional: true,
                                     is_string: false),
        FastlaneCore::ConfigItem.new(key: :enabled_xcode_output,
                                     env_name: "SCAN_ENABLED_XCODE_OUTPUT",
                                     type: Array,
                                     description: "List of what parts of xcodebuild output should be printed. Valid values are: 'command' (print xcodebuild spell), 'output' (print real-time output), 'error' (print raw output if the tests fail). Output is still always saved in buildlog_path",
                                     optional: true,
                                     default_value: [:command, :output],
                                     verify_block: proc do |values|
                                       values.each { |value| UI.user_error!("Invalid output type '#{value}'.") unless %w(command output error).include?(value.to_s) }
                                     end),
        FastlaneCore::ConfigItem.new(key: :formatter,
                                     short_option: "-n",
                                     env_name: "SCAN_FORMATTER",
                                     description: "A custom xcpretty formatter to use",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :xcpretty_args,
                                     env_name: "SCAN_XCPRETTY_ARGS",
                                     description: "Pass in xcpretty additional command line arguments (e.g. '--test --no-color' or '--tap --no-utf')",
                                     type: String,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :derived_data_path,
                                     short_option: "-j",
                                     env_name: "SCAN_DERIVED_DATA_PATH",
                                     description: "The directory where build products and other derived data will go",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :should_zip_build_products,
                                     short_option: "-Z",
                                     env_name: "SCAN_SHOULD_ZIP_BUILD_PRODUCTS",
                                     description: "Should zip the derived data build products and place in output path?",
                                     optional: true,
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :result_bundle,
                                     short_option: "-z",
                                     env_name: "SCAN_RESULT_BUNDLE",
                                     is_string: false,
                                     description: "Should an Xcode result bundle be generated in the output directory",
                                     default_value: false,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :use_clang_report_name,
                                     description: "Generate the json compilation database with clang naming convention (compile_commands.json)",
                                     is_string: false,
                                     default_value: false),

        # concurrency
        FastlaneCore::ConfigItem.new(key: :max_concurrent_simulators,
                                     type: Integer,
                                     env_name: "SCAN_MAX_CONCURRENT_SIMULATORS",
                                     description: "Constrain the number of simulator devices on which to test concurrently. Equivalent to -maximum-concurrent-test-simulator-destinations",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :disable_concurrent_testing,
                                     type: Boolean,
                                     default_value: false,
                                     env_name: "SCAN_DISABLE_CONCURRENT_TESTING",
                                     description: "Do not run test bundles in parallel on the specified destinations. Testing will occur on each destination serially. Equivalent to -disable-concurrent-testing",
                                     optional: true),

        # build
        FastlaneCore::ConfigItem.new(key: :skip_build,
                                     description: "Should debug build be skipped before test build?",
                                     short_option: "-r",
                                     env_name: "SCAN_SKIP_BUILD",
                                     is_string: false,
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :test_without_building,
                                     short_option: "-T",
                                     env_name: "SCAN_TEST_WITHOUT_BUILDING",
                                     description: "Test without building, requires a derived data path",
                                     is_string: false,
                                     type: Boolean,
                                     conflicting_options: [:build_for_testing],
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :build_for_testing,
                                     short_option: "-B",
                                     env_name: "SCAN_BUILD_FOR_TESTING",
                                     description: "Build for testing only, does not run tests",
                                     conflicting_options: [:test_without_building],
                                     is_string: false,
                                     type: Boolean,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :sdk,
                                     short_option: "-k",
                                     env_name: "SCAN_SDK",
                                     description: "The SDK that should be used for building the application",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :configuration,
                                     short_option: "-q",
                                     env_name: "SCAN_CONFIGURATION",
                                     description: "The configuration to use when building the app. Defaults to 'Release'",
                                     default_value_dynamic: true,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :xcargs,
                                     short_option: "-x",
                                     env_name: "SCAN_XCARGS",
                                     description: "Pass additional arguments to xcodebuild. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS=\"-ObjC -lstdc++\"",
                                     optional: true,
                                     type: :shell_string),
        FastlaneCore::ConfigItem.new(key: :xcconfig,
                                     short_option: "-y",
                                     env_name: "SCAN_XCCONFIG",
                                     description: "Use an extra XCCONFIG file to build your app",
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("File not found at path '#{File.expand_path(value)}'") unless File.exist?(value)
                                     end),

        # slack
        FastlaneCore::ConfigItem.new(key: :slack_url,
                                     short_option: "-i",
                                     env_name: "SLACK_URL",
                                     sensitive: true,
                                     description: "Create an Incoming WebHook for your Slack group to post results there",
                                     optional: true,
                                     verify_block: proc do |value|
                                       if !value.to_s.empty? && !value.start_with?("https://")
                                         UI.user_error!("Invalid URL, must start with https://")
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :slack_channel,
                                     short_option: "-e",
                                     env_name: "SCAN_SLACK_CHANNEL",
                                     description: "#channel or @username",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :slack_message,
                                     short_option: "-m",
                                     env_name: "SCAN_SLACK_MESSAGE",
                                     description: "The message included with each message posted to slack",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :skip_slack,
                                     description: "Don't publish to slack, even when an URL is given",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :slack_only_on_failure,
                                    description: "Only post on Slack if the tests fail",
                                    is_string: false,
                                    default_value: false),

        # misc
        FastlaneCore::ConfigItem.new(key: :destination,
                                     short_option: "-d",
                                     env_name: "SCAN_DESTINATION",
                                     description: "Use only if you're a pro, use the other options instead",
                                     is_string: false,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :custom_report_file_name,
                                     env_name: "SCAN_CUSTOM_REPORT_FILE_NAME",
                                     description: "Sets custom full report file name when generating a single report",
                                     deprecated: "Use `--output_files` instead",
                                     conflicting_options: [:output_files],
                                     optional: true,
                                     is_string: true)

      ]
    end
  end
  # rubocop:enable Metrics/ClassLength
end
