module Fastlane
  module Actions
    class SwiftlintAction < Action
      def self.run(params)
        if `which swiftlint`.to_s.length == 0 && params[:executable].nil? && !Helper.test?
          UI.user_error!("You have to install swiftlint using `brew install swiftlint` or specify the executable path with the `:executable` option.")
        end

        version = swiftlint_version(executable: params[:executable])
        if params[:mode] == :autocorrect && version < Gem::Version.new('0.5.0') && !Helper.test?
          UI.user_error!("Your version of swiftlint (#{version}) does not support autocorrect mode.\nUpdate swiftlint using `brew update && brew upgrade swiftlint`")
        end

        # See 'Breaking' section release notes here: https://github.com/realm/SwiftLint/releases/tag/0.43.0
        if params[:mode] == :autocorrect && version >= Gem::Version.new('0.43.0')
          UI.deprecated("Your version of swiftlint (#{version}) has deprecated autocorrect mode, please start using fix mode in input param")
          UI.important("For now, switching swiftlint mode `from :autocorrect to :fix` for you 😇")
          params[:mode] = :fix
        elsif params[:mode] == :fix && version < Gem::Version.new('0.43.0')
          UI.important("Your version of swiftlint (#{version}) does not support fix mode.\nUpdate swiftlint using `brew update && brew upgrade swiftlint`")
          UI.important("For now, switching swiftlint mode `from :fix to :autocorrect` for you 😇")
          params[:mode] = :autocorrect
        end

        mode_format = params[:mode] == :fix ? "--" : ""
        command = (params[:executable] || "swiftlint").dup
        command << " #{mode_format}#{params[:mode]}"
        command << optional_flags(params)

        if params[:files]
          if version < Gem::Version.new('0.5.1')
            UI.user_error!("Your version of swiftlint (#{version}) does not support list of files as input.\nUpdate swiftlint using `brew update && brew upgrade swiftlint`")
          end

          files = params[:files].map.with_index(0) { |f, i| "SCRIPT_INPUT_FILE_#{i}=#{f.shellescape}" }.join(" ")
          command = command.prepend("SCRIPT_INPUT_FILE_COUNT=#{params[:files].count} #{files} ")
          command << " --use-script-input-files"
        end

        command << " > #{params[:output_file].shellescape}" if params[:output_file]

        begin
          Actions.sh(command)
        rescue
          handle_swiftlint_error(params[:ignore_exit_status], $?.exitstatus)
          raise if params[:raise_if_swiftlint_error]
        end
      end

      def self.optional_flags(params)
        command = ""
        command << " --path #{params[:path].shellescape}" if params[:path]
        command << supported_option_switch(params, :strict, "0.9.2", true)
        command << " --config #{params[:config_file].shellescape}" if params[:config_file]
        command << " --reporter #{params[:reporter]}" if params[:reporter]
        command << supported_option_switch(params, :quiet, "0.9.0", true)
        command << supported_option_switch(params, :format, "0.11.0", true) if params[:mode] == :autocorrect
        command << supported_no_cache_option(params) if params[:no_cache]
        command << " --compiler-log-path #{params[:compiler_log_path].shellescape}" if params[:compiler_log_path]
        command << supported_option_switch(params, :progress, "0.49.1", true) if params[:progress]
        return command
      end

      # Get current SwiftLint version
      def self.swiftlint_version(executable: nil)
        binary = executable || 'swiftlint'
        Gem::Version.new(`#{binary} version`.chomp)
      end

      def self.supported_no_cache_option(params)
        if [:autocorrect, :fix, :lint].include?(params[:mode])
          return " --no-cache"
        else
          return ""
        end
      end

      # Return "--option" switch if option is on and current SwiftLint version is greater or equal than min version.
      # Return "" otherwise.
      def self.supported_option_switch(params, option, min_version, can_ignore = false)
        return "" unless params[option]
        version = swiftlint_version(executable: params[:executable])
        if version < Gem::Version.new(min_version)
          message = "Your version of swiftlint (#{version}) does not support '--#{option}' option.\nUpdate swiftlint to #{min_version} or above using `brew update && brew upgrade swiftlint`"
          message += "\nThe option will be ignored." if can_ignore
          can_ignore ? UI.important(message) : UI.user_error!(message)
          ""
        else
          " --#{option}"
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Run swift code validation using SwiftLint"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :mode,
                                       env_name: "FL_SWIFTLINT_MODE",
                                       description: "SwiftLint mode: :lint, :fix, :autocorrect or :analyze",
                                       type: Symbol,
                                       default_value: :lint,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :path,
                                       env_name: "FL_SWIFTLINT_PATH",
                                       description: "Specify path to lint",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find path '#{File.expand_path(value)}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :output_file,
                                       env_name: "FL_SWIFTLINT_OUTPUT_FILE",
                                       description: 'Path to output SwiftLint result',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :config_file,
                                       env_name: "FL_SWIFTLINT_CONFIG_FILE",
                                       description: 'Custom configuration file of SwiftLint',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :strict,
                                       env_name: "FL_SWIFTLINT_STRICT",
                                       description: 'Fail on warnings? (true/false)',
                                       default_value: false,
                                       type: Boolean,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :files,
                                       env_name: "FL_SWIFTLINT_FILES",
                                       description: 'List of files to process',
                                       type: Array,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :ignore_exit_status,
                                       env_name: "FL_SWIFTLINT_IGNORE_EXIT_STATUS",
                                       description: "Ignore the exit status of the SwiftLint command, so that serious violations \
                                                    don't fail the build (true/false)",
                                       default_value: false,
                                       type: Boolean,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :raise_if_swiftlint_error,
                                       env_name: "FL_SWIFTLINT_RAISE_IF_SWIFTLINT_ERROR",
                                       description: "Raises an error if swiftlint fails, so you can fail CI/CD jobs if necessary \
                                                    (true/false)",
                                       default_value: false,
                                       type: Boolean,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :reporter,
                                       env_name: "FL_SWIFTLINT_REPORTER",
                                       description: "Choose output reporter. Available: xcode, json, csv, checkstyle, codeclimate, \
                                                     junit, html, emoji, sonarqube, markdown, github-actions-logging",
                                       optional: true,
                                       verify_block: proc do |value|
                                         available = ['xcode', 'json', 'csv', 'checkstyle', 'codeclimate', 'junit', 'html', 'emoji', 'sonarqube', 'markdown', 'github-actions-logging']
                                         UI.important("Known 'reporter' values are '#{available.join("', '")}'. If you're receiving errors from swiftlint related to the reporter, make sure the reporter identifier you're using is correct and it's supported by your version of swiftlint.") unless available.include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :quiet,
                                       env_name: "FL_SWIFTLINT_QUIET",
                                       description: "Don't print status logs like 'Linting <file>' & 'Done linting'",
                                       default_value: false,
                                       type: Boolean,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :executable,
                                       env_name: "FL_SWIFTLINT_EXECUTABLE",
                                       description: "Path to the `swiftlint` executable on your machine",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :format,
                                       env_name: "FL_SWIFTLINT_FORMAT",
                                       description: "Format code when mode is :autocorrect",
                                       default_value: false,
                                       type: Boolean,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :no_cache,
                                       env_name: "FL_SWIFTLINT_NO_CACHE",
                                       description: "Ignore the cache when mode is :autocorrect or :lint",
                                       default_value: false,
                                       type: Boolean,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :compiler_log_path,
                                       env_name: "FL_SWIFTLINT_COMPILER_LOG_PATH",
                                       description: "Compiler log path when mode is :analyze",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find compiler_log_path '#{File.expand_path(value)}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :progress,
                                       env_name: "FL_SWIFTLINT_PROGRESS",
                                       description: "Show a live-updating progress bar instead of each file being processed",
                                       default_value: false,
                                       type: Boolean,
                                       optional: true)
        ]
      end

      def self.output
      end

      def self.return_value
      end

      def self.authors
        ["KrauseFx"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.example_code
        [
          'swiftlint(
            mode: :lint,                          # SwiftLint mode: :lint (default) or :autocorrect
            path: "/path/to/lint",                 # Specify path to lint (optional)
            output_file: "swiftlint.result.json", # The path of the output file (optional)
            config_file: ".swiftlint-ci.yml",     # The path of the configuration file (optional)
            files: [                              # List of files to process (optional)
              "AppDelegate.swift",
              "path/to/project/Model.swift"
            ],
            raise_if_swiftlint_error: true,      # Allow fastlane to raise an error if swiftlint fails
            ignore_exit_status: true              # Allow fastlane to continue even if SwiftLint returns a non-zero exit status

          )'
        ]
      end

      def self.category
        :testing
      end

      def self.handle_swiftlint_error(ignore_exit_status, exit_status)
        if ignore_exit_status
          failure_suffix = 'which would normally fail the build.'
          secondary_message = 'fastlane will continue because the `ignore_exit_status` option was used! 🙈'
        else
          failure_suffix = 'which represents a failure.'
          secondary_message = 'If you want fastlane to continue anyway, use the `ignore_exit_status` option. 🙈'
        end

        UI.important("")
        UI.important("SwiftLint finished with exit code #{exit_status}, #{failure_suffix}")
        UI.important(secondary_message)
        UI.important("")
        UI.user_error!("SwiftLint finished with errors (exit code: #{exit_status})") unless ignore_exit_status
      end
    end
  end
end
