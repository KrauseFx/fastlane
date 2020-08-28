protocol ScanfileProtocol: class {
    /// Path to the workspace file
    var workspace: String? { get }

    /// Path to the project file
    var project: String? { get }

    /// The project's scheme. Make sure it's marked as `Shared`
    var scheme: String? { get }

    /// The name of the simulator type you want to run tests on (e.g. 'iPhone 6')
    var device: String? { get }

    /// Array of devices to run the tests on (e.g. ['iPhone 6', 'iPad Air'])
    var devices: [String]? { get }

    /// Should skip auto detecting of devices if none were specified
    var skipDetectDevices: Bool { get }

    /// Enabling this option will automatically killall Simulator processes before the run
    var forceQuitSimulator: Bool { get }

    /// Enabling this option will automatically erase the simulator before running the application
    var resetSimulator: Bool { get }

    /// Enabling this option will disable the simulator from showing the 'Slide to type' prompt
    var disableSlideToType: Bool { get }

    /// Enabling this option will launch the first simulator prior to calling any xcodebuild command
    var prelaunchSimulator: Bool? { get }

    /// Enabling this option will automatically uninstall the application before running it
    var reinstallApp: Bool { get }

    /// The bundle identifier of the app to uninstall (only needed when enabling reinstall_app)
    var appIdentifier: String? { get }

    /// Array of strings matching Test Bundle/Test Suite/Test Cases to run
    var onlyTesting: String? { get }

    /// Array of strings matching Test Bundle/Test Suite/Test Cases to skip
    var skipTesting: String? { get }

    /// The testplan associated with the scheme that should be used for testing
    var testplan: String? { get }

    /// Array of strings matching test plan configurations to run
    var onlyTestConfigurations: String? { get }

    /// Array of strings matching test plan configurations to skip
    var skipTestConfigurations: String? { get }

    /// Run tests using the provided `.xctestrun` file
    var xctestrun: String? { get }

    /// The toolchain that should be used for building the application (e.g. `com.apple.dt.toolchain.Swift_2_3, org.swift.30p620160816a`)
    var toolchain: String? { get }

    /// Should the project be cleaned before building it?
    var clean: Bool { get }

    /// Should code coverage be generated? (Xcode 7 and up)
    var codeCoverage: Bool? { get }

    /// Should the address sanitizer be turned on?
    var addressSanitizer: Bool? { get }

    /// Should the thread sanitizer be turned on?
    var threadSanitizer: Bool? { get }

    /// Should the HTML report be opened when tests are completed?
    var openReport: Bool { get }

    /// Disable xcpretty formatting of build, similar to `output_style='raw'` but this will also skip the test results table
    var disableXcpretty: Bool? { get }

    /// The directory in which all reports will be stored
    var outputDirectory: String { get }

    /// Define how the output should look like. Valid values are: standard, basic, rspec, or raw (disables xcpretty during xcodebuild)
    var outputStyle: String? { get }

    /// Comma separated list of the output types (e.g. html, junit, json-compilation-database)
    var outputTypes: String { get }

    /// Comma separated list of the output files, corresponding to the types provided by :output_types (order should match). If specifying an output type of json-compilation-database with :use_clang_report_name enabled, that option will take precedence
    var outputFiles: String? { get }

    /// The directory where to store the raw log
    var buildlogPath: String { get }

    /// If the logs generated by the app (e.g. using NSLog, perror, etc.) in the Simulator should be written to the output_directory
    var includeSimulatorLogs: Bool { get }

    /// Suppress the output of xcodebuild to stdout. Output is still saved in buildlog_path
    var suppressXcodeOutput: Bool? { get }

    /// A custom xcpretty formatter to use
    var formatter: String? { get }

    /// Pass in xcpretty additional command line arguments (e.g. '--test --no-color' or '--tap --no-utf')
    var xcprettyArgs: String? { get }

    /// The directory where build products and other derived data will go
    var derivedDataPath: String? { get }

    /// Should zip the derived data build products and place in output path?
    var shouldZipBuildProducts: Bool { get }

    /// Should an Xcode result bundle be generated in the output directory
    var resultBundle: Bool { get }

    /// Generate the json compilation database with clang naming convention (compile_commands.json)
    var useClangReportName: Bool { get }

    /// Specify the exact number of test runners that will be spawned during parallel testing. Equivalent to -parallel-testing-worker-count
    var concurrentWorkers: Int? { get }

    /// Constrain the number of simulator devices on which to test concurrently. Equivalent to -maximum-concurrent-test-simulator-destinations
    var maxConcurrentSimulators: Int? { get }

    /// Do not run test bundles in parallel on the specified destinations. Testing will occur on each destination serially. Equivalent to -disable-concurrent-testing
    var disableConcurrentTesting: Bool { get }

    /// Should debug build be skipped before test build?
    var skipBuild: Bool { get }

    /// Test without building, requires a derived data path
    var testWithoutBuilding: Bool? { get }

    /// Build for testing only, does not run tests
    var buildForTesting: Bool? { get }

    /// The SDK that should be used for building the application
    var sdk: String? { get }

    /// The configuration to use when building the app. Defaults to 'Release'
    var configuration: String? { get }

    /// Pass additional arguments to xcodebuild. Be sure to quote the setting names and values e.g. OTHER_LDFLAGS="-ObjC -lstdc++"
    var xcargs: String? { get }

    /// Use an extra XCCONFIG file to build your app
    var xcconfig: String? { get }

    /// App name to use in slack message and logfile name
    var appName: String? { get }

    /// Target version of the app being build or tested. Used to filter out simulator version
    var deploymentTargetVersion: String? { get }

    /// Create an Incoming WebHook for your Slack group to post results there
    var slackUrl: String? { get }

    /// #channel or @username
    var slackChannel: String? { get }

    /// The message included with each message posted to slack
    var slackMessage: String? { get }

    /// Use webhook's default username and icon settings? (true/false)
    var slackUseWebhookConfiguredUsernameAndIcon: Bool { get }

    /// Overrides the webhook's username property if slack_use_webhook_configured_username_and_icon is false
    var slackUsername: String { get }

    /// Overrides the webhook's image property if slack_use_webhook_configured_username_and_icon is false
    var slackIconUrl: String { get }

    /// Don't publish to slack, even when an URL is given
    var skipSlack: Bool { get }

    /// Only post on Slack if the tests fail
    var slackOnlyOnFailure: Bool { get }

    /// Use only if you're a pro, use the other options instead
    var destination: String? { get }

    /// **DEPRECATED!** Use `--output_files` instead - Sets custom full report file name when generating a single report
    var customReportFileName: String? { get }

    /// Allows for override of the default `xcodebuild` command
    var xcodebuildCommand: String { get }

    /// Sets a custom path for Swift Package Manager dependencies
    var clonedSourcePackagesPath: String? { get }

    /// Should this step stop the build if the tests fail? Set this to false if you're using trainer
    var failBuild: Bool { get }
}

extension ScanfileProtocol {
    var workspace: String? { return nil }
    var project: String? { return nil }
    var scheme: String? { return nil }
    var device: String? { return nil }
    var devices: [String]? { return nil }
    var skipDetectDevices: Bool { return false }
    var forceQuitSimulator: Bool { return false }
    var resetSimulator: Bool { return false }
    var disableSlideToType: Bool { return true }
    var prelaunchSimulator: Bool? { return nil }
    var reinstallApp: Bool { return false }
    var appIdentifier: String? { return nil }
    var onlyTesting: String? { return nil }
    var skipTesting: String? { return nil }
    var testplan: String? { return nil }
    var onlyTestConfigurations: String? { return nil }
    var skipTestConfigurations: String? { return nil }
    var xctestrun: String? { return nil }
    var toolchain: String? { return nil }
    var clean: Bool { return false }
    var codeCoverage: Bool? { return nil }
    var addressSanitizer: Bool? { return nil }
    var threadSanitizer: Bool? { return nil }
    var openReport: Bool { return false }
    var disableXcpretty: Bool? { return nil }
    var outputDirectory: String { return "./test_output" }
    var outputStyle: String? { return nil }
    var outputTypes: String { return "html,junit" }
    var outputFiles: String? { return nil }
    var buildlogPath: String { return "~/Library/Logs/scan" }
    var includeSimulatorLogs: Bool { return false }
    var suppressXcodeOutput: Bool? { return nil }
    var formatter: String? { return nil }
    var xcprettyArgs: String? { return nil }
    var derivedDataPath: String? { return nil }
    var shouldZipBuildProducts: Bool { return false }
    var resultBundle: Bool { return false }
    var useClangReportName: Bool { return false }
    var concurrentWorkers: Int? { return nil }
    var maxConcurrentSimulators: Int? { return nil }
    var disableConcurrentTesting: Bool { return false }
    var skipBuild: Bool { return false }
    var testWithoutBuilding: Bool? { return nil }
    var buildForTesting: Bool? { return nil }
    var sdk: String? { return nil }
    var configuration: String? { return nil }
    var xcargs: String? { return nil }
    var xcconfig: String? { return nil }
    var appName: String? { return nil }
    var deploymentTargetVersion: String? { return nil }
    var slackUrl: String? { return nil }
    var slackChannel: String? { return nil }
    var slackMessage: String? { return nil }
    var slackUseWebhookConfiguredUsernameAndIcon: Bool { return false }
    var slackUsername: String { return "fastlane" }
    var slackIconUrl: String { return "https://fastlane.tools/assets/img/fastlane_icon.png" }
    var skipSlack: Bool { return false }
    var slackOnlyOnFailure: Bool { return false }
    var destination: String? { return nil }
    var customReportFileName: String? { return nil }
    var xcodebuildCommand: String { return "env NSUnbufferedIO=YES xcodebuild" }
    var clonedSourcePackagesPath: String? { return nil }
    var failBuild: Bool { return true }
}

// Please don't remove the lines below
// They are used to detect outdated files
// FastlaneRunnerAPIVersion [0.9.44]
