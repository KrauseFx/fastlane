module Fastlane
  module Actions
    class SpmAction < Action
      def self.run(params)
        cmd = ["swift"]

        cmd << (package_commands.include?(params[:command]) ? "package" : params[:command])
        cmd << "--scratch-path #{params[:scratch_path]}" if params[:scratch_path]
        cmd << "--build-path #{params[:build_path]}" if params[:build_path]
        cmd << "--package-path #{params[:package_path]}" if params[:package_path]
        cmd << "--configuration #{params[:configuration]}" if params[:configuration]
        cmd << "--disable-sandbox" if params[:disable_sandbox]
        cmd << "--skip-update" if params[:skip_update]
        cmd << "--verbose" if params[:verbose]
        cmd << "--very-verbose" if params[:very_verbose]
        if params[:simulator]
          simulator_platform = simulator_platform(simulator: params[:simulator], simulator_arch: params[:simulator_arch])
          simulator_sdk = simulator_sdk(simulator: params[:simulator])
          simulator_sdk_suffix = simulator_sdk_suffix(simulator: params[:simulator])
          simulator_flags = [
            "-Xswiftc", "-sdk",
            "-Xswiftc", "$(xcrun --sdk #{params[:simulator]} --show-sdk-path)",
            "-Xswiftc", "-target",
            "-Xswiftc", "#{simulator_platform}#{simulator_sdk}#{simulator_sdk_suffix}"
          ]
          cmd += simulator_flags
        end
        cmd << params[:command] if package_commands.include?(params[:command])
        cmd << "--enable-code-coverage" if params[:enable_code_coverage] && (params[:command] == 'generate-xcodeproj' || params[:command] == 'test')
        cmd << "--parallel" if params[:parallel] && params[:command] == 'test'
        if params[:xcconfig]
          cmd << "--xcconfig-overrides #{params[:xcconfig]}"
        end
        if params[:xcpretty_output]
          cmd += ["2>&1", "|", "xcpretty", "--#{params[:xcpretty_output]}"]
          if params[:xcpretty_args]
            cmd << (params[:xcpretty_args]).to_s
          end
          cmd = %w(set -o pipefail &&) + cmd
        end

        FastlaneCore::CommandExecutor.execute(command: cmd.join(" "),
                                              print_all: true,
                                              print_command: true)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Runs Swift Package Manager on your project"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :command,
                                       env_name: "FL_SPM_COMMAND",
                                       description: "The swift command (one of: #{available_commands.join(', ')})",
                                       default_value: "build",
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass a valid command. Use one of the following: #{available_commands.join(', ')}") unless available_commands.include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :enable_code_coverage,
                                       env_name: "FL_SPM_ENABLE_CODE_COVERAGE",
                                       description: "Enables code coverage for the generated Xcode project when using the 'generate-xcodeproj' and the 'test' command",
                                       type: Boolean,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :scratch_path,
                                       env_name: "FL_SPM_SCRATCH_PATH",
                                       description: "Specify build/cache directory [default: ./.build]",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :parallel,
                                       env_name: "FL_SPM_PARALLEL",
                                       description: "Enables running tests in parallel when using the 'test' command",
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :build_path,
                                       env_name: "FL_SPM_BUILD_PATH",
                                       description: "Specify build/cache directory [default: ./.build]",
                                       deprecated: "`build_path` option is deprecated, use `scratch_path` instead",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :package_path,
                                       env_name: "FL_SPM_PACKAGE_PATH",
                                       description: "Change working directory before any other operation",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :xcconfig,
                                       env_name: "FL_SPM_XCCONFIG",
                                       description: "Use xcconfig file to override swift package generate-xcodeproj defaults",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :configuration,
                                       short_option: "-c",
                                       env_name: "FL_SPM_CONFIGURATION",
                                       description: "Build with configuration (debug|release) [default: debug]",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass a valid configuration: (debug|release)") unless valid_configurations.include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :disable_sandbox,
                                       env_name: "FL_SPM_DISABLE_SANDBOX",
                                       description: "Disable using the sandbox when executing subprocesses",
                                       optional: true,
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :xcpretty_output,
                                       env_name: "FL_SPM_XCPRETTY_OUTPUT",
                                       description: "Specifies the output type for xcpretty. eg. 'test', or 'simple'",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass a valid xcpretty output type: (#{xcpretty_output_types.join('|')})") unless xcpretty_output_types.include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :xcpretty_args,
                                       env_name: "FL_SPM_XCPRETTY_ARGS",
                                       description: "Pass in xcpretty additional command line arguments (e.g. '--test --no-color' or '--tap --no-utf'), requires xcpretty_output to be specified also",
                                       type: String,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :skip_update,
                                       env_name: "FL_SPM_SKIP_UPDATE",
                                       description: "Skip updating dependencies from their remote during a resolution",
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :verbose,
                                       short_option: "-v",
                                       env_name: "FL_SPM_VERBOSE",
                                       description: "Increase verbosity of informational output",
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :very_verbose,
                                       short_option: "-V",
                                       env_name: "FL_SPM_VERY_VERBOSE",
                                       description: "Increase verbosity to include debug output",
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :simulator,
                                       env_name: "FL_SPM_SIMULATOR",
                                       description: "Specifies the simulator to pass for Swift Compiler (one of: #{valid_simulators.join(', ')})",
                                       type: String,
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass a valid simulator. Use one of the following: #{valid_simulators.join(', ')}") unless valid_simulators.include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :simulator_arch,
                                       env_name: "FL_SPM_SIMULATOR_ARCH",
                                       description: "Specifies the architecture of the simulator to pass for Swift Compiler (one of: #{valid_architectures.join(', ')}). Requires the simulator option to be specified also, otherwise, it's ignored",
                                       type: String,
                                       optional: false,
                                       default_value: "arm64",
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass a valid simulator architecture. Use one of the following: #{valid_architectures.join(', ')}") unless valid_architectures.include?(value)
                                       end)
        ]
      end

      def self.authors
        ["fjcaetano", "nxtstep"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'spm',
          'spm(
            command: "build",
            scratch_path: "./build",
            configuration: "release"
          )',
          'spm(
            command: "generate-xcodeproj",
            xcconfig: "Package.xcconfig"
          )',
          'spm(
            command: "test",
            parallel: true
          )',
          'spm(
            simulator: "iphonesimulator"
          )',
          'spm(
            simulator: "macosx",
            simulator_arch: "arm64"
          )'
        ]
      end

      def self.category
        :building
      end

      def self.available_commands
        %w(build test) + self.package_commands
      end

      def self.package_commands
        %w(clean reset update resolve generate-xcodeproj init)
      end

      def self.valid_configurations
        %w(debug release)
      end

      def self.xcpretty_output_types
        %w(simple test knock tap)
      end

      def self.valid_simulators
        %w(iphonesimulator macosx)
      end

      def self.valid_architectures
        %w(x86_64 arm64)
      end

      def self.simulator_platform(params)
        platform_suffix = params[:simulator] == "iphonesimulator" ? "ios" : "macosx"
        "#{params[:simulator_arch]}-apple-#{platform_suffix}"
      end

      def self.simulator_sdk(params)
        "$(xcrun --sdk #{params[:simulator]} --show-sdk-version | cut -d '.' -f 1)"
      end

      def self.simulator_sdk_suffix(params)
        return "" unless params[:simulator] == "iphonesimulator"
        "-simulator"
      end
    end
  end
end
