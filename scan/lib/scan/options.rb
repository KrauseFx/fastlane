require "fastlane_core"
require "credentials_manager"

module Scan
  class Options
    def self.available_options
      containing = Helper.fastlane_enabled? ? './fastlane' : '.'

      [
        self.config_item(key: :workspace,
                         short_option: "-w",
                         env_name: "WORKSPACE",
                         optional: true,
                         description: "Path the workspace file",
                         verify_block: proc do |value|
                           v = File.expand_path(value.to_s)
                           UI.user_error!("Workspace file not found at path '#{v}'") unless File.exist?(v)
                           UI.user_error!("Workspace file invalid") unless File.directory?(v)
                           UI.user_error!("Workspace file is not a workspace, must end with .xcworkspace") unless v.include?(".xcworkspace")
                         end),
        self.config_item(key: :project,
                         short_option: "-p",
                         optional: true,
                         env_name: "PROJECT",
                         description: "Path the project file",
                         verify_block: proc do |value|
                           v = File.expand_path(value.to_s)
                           UI.user_error!("Project file not found at path '#{v}'") unless File.exist?(v)
                           UI.user_error!("Project file invalid") unless File.directory?(v)
                           UI.user_error!("Project file is not a project file, must end with .xcodeproj") unless v.include?(".xcodeproj")
                         end),
        self.config_item(key: :device,
                         short_option: "-a",
                         optional: true,
                         is_string: true,
                         env_name: "DEVICE",
                         description: "The name of the simulator type you want to run tests on (e.g. 'iPhone 6')",
                         conflicting_options: [:devices],
                         conflict_block: proc do |value|
                           UI.user_error!("You can't use 'device' and 'devices' options in one run")
                         end),
        self.config_item(key: :devices,
                         optional: true,
                         is_string: false,
                         env_name: "DEVICES",
                         type: Array,
                         description: "Array of devices to run the tests on (e.g. ['iPhone 6', 'iPad Air'])",
                         conflicting_options: [:device],
                         conflict_block: proc do |value|
                           UI.user_error!("You can't use 'device' and 'devices' options in one run")
                         end),
        self.config_item(key: :scheme,
                         short_option: "-s",
                         optional: true,
                         env_name: "SCHEME",
                         description: "The project's scheme. Make sure it's marked as `Shared`"),
        self.config_item(key: :clean,
                         short_option: "-c",
                         env_name: "CLEAN",
                         description: "Should the project be cleaned before building it?",
                         is_string: false,
                         default_value: false),
        self.config_item(key: :code_coverage,
                         description: "Should generate code coverage (Xcode 7 only)?",
                         is_string: false,
                         default_value: false),
        self.config_item(key: :address_sanitizer,
                         description: "Should turn on the address sanitizer?",
                         is_string: false,
                         default_value: false),
        self.config_item(key: :skip_build,
                         description: "Should skip debug build before test build?",
                         short_option: "-r",
                         env_name: "SKIP_BUILD",
                         is_string: false,
                         default_value: false),
        self.config_item(key: :output_directory,
                         short_option: "-o",
                         env_name: "OUTPUT_DIRECTORY",
                         description: "The directory in which all reports will be stored",
                         default_value: File.join(containing, "test_output")),
        self.config_item(key: :output_style,
                         short_option: "-b",
                         env_name: "OUTPUT_STYLE",
                         description: "Define how the output should look like (standard, basic, rspec or raw)",
                         optional: true,
                         verify_block: proc do |value|
                           UI.user_error!("Invalid output_style #{value}") unless ['standard', 'basic', 'rspec', 'raw'].include?(value)
                         end),
        self.config_item(key: :output_types,
                         short_option: "-f",
                         env_name: "OUTPUT_TYPES",
                         description: "Comma separated list of the output types (e.g. html, junit)",
                         default_value: "html,junit"),
        self.config_item(key: :buildlog_path,
                         short_option: "-l",
                         env_name: "BUILDLOG_PATH",
                         description: "The directory were to store the raw log",
                         default_value: "#{FastlaneCore::Helper.buildlog_path}/scan"),
        self.config_item(key: :formatter,
                         short_option: "-n",
                         env_name: "FORMATTER",
                         description: "A custom xcpretty formatter to use",
                         optional: true),
        self.config_item(key: :derived_data_path,
                         short_option: "-j",
                         env_name: "DERIVED_DATA_PATH",
                         description: "The directory where build products and other derived data will go",
                         optional: true),
        self.config_item(key: :result_bundle,
                         short_option: "-z",
                         env_name: "RESULT_BUNDLE",
                         is_string: false,
                         description: "Produce the result bundle describing what occurred will be placed",
                         optional: true),
        self.config_item(key: :sdk,
                         short_option: "-k",
                         env_name: "SDK",
                         description: "The SDK that should be used for building the application",
                         optional: true),
        self.config_item(key: :open_report,
                         short_option: "-g",
                         env_name: "OPEN_REPORT",
                         description: "Should the HTML report be opened when tests are completed",
                         is_string: false,
                         default_value: false),
        self.config_item(key: :configuration,
                         short_option: "-q",
                         env_name: "CONFIGURATION",
                         description: "The configuration to use when building the app. Defaults to 'Release'",
                         optional: true),
        self.config_item(key: :destination,
                         short_option: "-d",
                         env_name: "DESTINATION",
                         description: "Use only if you're a pro, use the other options instead",
                         is_string: false,
                         optional: true),
        self.config_item(key: :xcargs,
                         short_option: "-x",
                         env_name: "XCARGS",
                         description: "Pass additional arguments to xcodebuild. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS=\"-ObjC -lstdc++\"",
                         optional: true),
        self.config_item(key: :xcconfig,
                         short_option: "-y",
                         env_name: "XCCONFIG",
                         description: "Use an extra XCCONFIG file to build your app",
                         optional: true,
                         verify_block: proc do |value|
                           UI.user_error!("File not found at path '#{File.expand_path(value)}'") unless File.exist?(value)
                         end),
        self.config_item(key: :slack_url,
                         short_option: "-i",
                         env_name: "SLACK_URL",
                         description: "Create an Incoming WebHook for your Slack group to post results there",
                         optional: true,
                         verify_block: proc do |value|
                           UI.user_error!("Invalid URL, must start with https://") unless value.start_with? "https://"
                         end),
        self.config_item(key: :slack_channel,
                         short_option: "-e",
                         env_name: "SLACK_CHANNEL",
                         description: "#channel or @username",
                         optional: true),
        self.config_item(key: :slack_message,
                         short_option: "-m",
                         env_name: "SLACK_MESSAGE",
                         description: "The message included with each message posted to slack",
                         optional: true),
        self.config_item(key: :skip_slack,
                         description: "Don't publish to slack, even when an URL is given",
                         is_string: false,
                         default_value: false),
        self.config_item(key: :slack_only_on_failure,
                         description: "Only post on Slack if the tests fail",
                         is_string: false,
                         default_value: false),
        self.config_item(key: :use_clang_report_name,
                         description: "Generate the json compilation database with clang naming convention (compile_commands.json)",
                         is_string: false,
                         default_value: false),
        self.config_item(key: :custom_report_file_name,
                         description: "Sets custom full report file name",
                         optional: true,
                         is_string: true)
      ]
    end
  end
end
