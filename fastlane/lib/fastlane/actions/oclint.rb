module Fastlane
  module Actions
    module SharedValues
      FL_OCLINT_REPORT_PATH = :FL_OCLINT_REPORT_PATH
    end

    class OclintAction < Action
      # rubocop:disable Metrics/PerceivedComplexity
      def self.run(params)
        oclint_path = params[:oclint_path]
        if `which #{oclint_path}`.to_s.empty? && !Helper.test?
          UI.user_error!("You have to install oclint or provide path to oclint binary. Fore more details: ") + "http://docs.oclint.org/en/stable/intro/installation.html".yellow
        end

        compile_commands = params[:compile_commands]
        compile_commands_dir = params[:compile_commands]
        UI.user_error!("Could not find json compilation database at path '#{compile_commands}'") unless File.exist?(compile_commands)

        # We'll attempt to sort things out so that we support receiving either a path to a
        # 'compile_commands.json' file (as our option asks for), or a path to a directory
        # *containing* a 'compile_commands.json' file (as oclint actually wants)
        if File.file?(compile_commands_dir)
          compile_commands_dir = File.dirname(compile_commands_dir)
        else
          compile_commands = File.join(compile_commands_dir, 'compile_commands.json')
        end

        if params[:select_reqex]
          UI.important("'select_reqex' parameter is deprecated. Please use 'select_regex' instead.")
          select_regex = params[:select_reqex]
        end

        select_regex = params[:select_regex] if params[:select_regex] # Overwrite deprecated select_reqex
        select_regex = ensure_regex_is_not_string!(select_regex)

        exclude_regex = params[:exclude_regex]
        exclude_regex = ensure_regex_is_not_string!(exclude_regex)

        files = JSON.parse(File.read(compile_commands)).map do |compile_command|
          file = compile_command['file']
          File.exist?(file) ? file : File.join(compile_command['directory'], file)
        end

        files.uniq!
        files.select! do |file|
          file_ruby = file.gsub('\ ', ' ')
          File.exist?(file_ruby) and
            (!select_regex or file_ruby =~ select_regex) and
            (!exclude_regex or file_ruby !~ exclude_regex)
        end

        command_prefix = [
          'cd',
          File.expand_path('.').shellescape,
          '&&'
        ].join(' ')

        report_type = params[:report_type]
        report_path = params[:report_path] || 'oclint_report.' + report_type

        oclint_args = ["-report-type=#{report_type}", "-o=#{report_path}"]

        oclint_args << "-list-enabled-rules" if params[:list_enabled_rules]

        if params[:rc]
          UI.important("It's recommended to use 'thresholds' instead of deprecated 'rc' parameter")
          oclint_args << "-rc=#{params[:rc]}" if params[:rc] # Deprecated
        end

        oclint_args << ensure_array_is_not_string!(params[:thresholds]).map { |t| "-rc=#{t}" } if params[:thresholds]
        # Escape ' in rule names with \' when passing on to shell command
        oclint_args << params[:enable_rules].map { |r| "-rule #{r.shellescape}" } if params[:enable_rules]
        oclint_args << params[:disable_rules].map { |r| "-disable-rule #{r.shellescape}" } if params[:disable_rules]

        oclint_args << "-max-priority-1=#{params[:max_priority_1]}" if params[:max_priority_1]
        oclint_args << "-max-priority-2=#{params[:max_priority_2]}" if params[:max_priority_2]
        oclint_args << "-max-priority-3=#{params[:max_priority_3]}" if params[:max_priority_3]

        oclint_args << "-enable-clang-static-analyzer" if params[:enable_clang_static_analyzer]
        oclint_args << "-enable-global-analysis" if params[:enable_global_analysis]
        oclint_args << "-allow-duplicated-violations" if params[:allow_duplicated_violations]
        oclint_args << "-p #{compile_commands_dir.shellescape}"

        oclint_args << "-extra-arg=#{params[:extra_arg]}" if params[:extra_arg]

        command = [
          command_prefix,
          oclint_path,
          oclint_args,
          '"' + files.join('" "') + '"'
        ].join(' ')

        Actions.lane_context[SharedValues::FL_OCLINT_REPORT_PATH] = File.expand_path(report_path)

        return Action.sh(command)
      end

      # return a proper regex object if regex string is single-quoted
      def self.ensure_regex_is_not_string!(regex)
        return regex unless regex.kind_of?(String)

        Regexp.new(regex)
      end

      # return a proper array of strings if array string is single-quoted
      def self.ensure_array_is_not_string!(array)
        return array unless array.kind_of?(String)

        array.split(',')
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Lints implementation files with OCLint"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :oclint_path,
                                       env_name: 'FL_OCLINT_PATH',
                                       description: 'The path to oclint binary',
                                       default_value: 'oclint',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :compile_commands,
                                       env_name: 'FL_OCLINT_COMPILE_COMMANDS',
                                       description: 'The json compilation database, use xctool reporter \'json-compilation-database\'',
                                       default_value: 'compile_commands.json',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :select_reqex, # select_reqex is deprecated, remove as soon as possible
                                       env_name: 'FL_OCLINT_SELECT_REQEX',
                                       description: 'Select all files matching this reqex',
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :select_regex,
                                       env_name: 'FL_OCLINT_SELECT_REGEX',
                                       description: 'Select all files matching this regex',
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :exclude_regex,
                                       env_name: 'FL_OCLINT_EXCLUDE_REGEX',
                                       description: 'Exclude all files matching this regex',
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :report_type,
                                       env_name: 'FL_OCLINT_REPORT_TYPE',
                                       description: 'The type of the report (default: html)',
                                       default_value: 'html',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :report_path,
                                       env_name: 'FL_OCLINT_REPORT_PATH',
                                       description: 'The reports file path',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :list_enabled_rules,
                                       env_name: "FL_OCLINT_LIST_ENABLED_RULES",
                                       description: "List enabled rules",
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :rc,
                                       env_name: 'FL_OCLINT_RC',
                                       description: 'Override the default behavior of rules',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :thresholds,
                                       env_name: 'FL_OCLINT_THRESHOLDS',
                                       description: 'List of rule thresholds to override the default behavior of rules',
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :enable_rules,
                                       env_name: 'FL_OCLINT_ENABLE_RULES',
                                       description: 'List of rules to pick explicitly',
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :disable_rules,
                                       env_name: 'FL_OCLINT_DISABLE_RULES',
                                       description: 'List of rules to disable',
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :max_priority_1,
                                       env_name: 'FL_OCLINT_MAX_PRIOTITY_1',
                                       description: 'The max allowed number of priority 1 violations',
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :max_priority_2,
                                       env_name: 'FL_OCLINT_MAX_PRIOTITY_2',
                                       description: 'The max allowed number of priority 2 violations',
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :max_priority_3,
                                       env_name: 'FL_OCLINT_MAX_PRIOTITY_3',
                                       description: 'The max allowed number of priority 3 violations',
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :enable_clang_static_analyzer,
                                       env_name: "FL_OCLINT_ENABLE_CLANG_STATIC_ANALYZER",
                                       description: "Enable Clang Static Analyzer, and integrate results into OCLint report",
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :enable_global_analysis,
                                       env_name: "FL_OCLINT_ENABLE_GLOBAL_ANALYSIS",
                                       description: "Compile every source, and analyze across global contexts (depends on number of source files, could results in high memory load)",
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :allow_duplicated_violations,
                                       env_name: "FL_OCLINT_ALLOW_DUPLICATED_VIOLATIONS",
                                       description: "Allow duplicated violations in the OCLint report",
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :extra_arg,
                                       env_name: 'FL_OCLINT_EXTRA_ARG',
                                       description: 'Additional argument to append to the compiler command line',
                                       optional: true)
        ]
      end
      # rubocop:enable Metrics/PerceivedComplexity

      def self.output
        [
          ['FL_OCLINT_REPORT_PATH', 'The reports file path']
        ]
      end

      def self.author
        'HeEAaD'
      end

      def self.is_supported?(platform)
        true
      end

      def self.details
        "Run the static analyzer tool [OCLint](http://oclint.org) for your project. You need to have a `compile_commands.json` file in your _fastlane_ directory or pass a path to your file."
      end

      def self.example_code
        [
          'oclint(
            compile_commands: "commands.json",    # The JSON compilation database, use xctool reporter "json-compilation-database"
            select_regex: /ViewController.m/,     # Select all files matching this regex
            exclude_regex: /Test.m/,              # Exclude all files matching this regex
            report_type: "pmd",                   # The type of the report (default: html)
            max_priority_1: 10,                   # The max allowed number of priority 1 violations
            max_priority_2: 100,                  # The max allowed number of priority 2 violations
            max_priority_3: 1000,                 # The max allowed number of priority 3 violations
            thresholds: [                         # Override the default behavior of rules
              "LONG_LINE=200",
              "LONG_METHOD=200"
            ],
            enable_rules: [                       # List of rules to pick explicitly
              "DoubleNegative",
              "SwitchStatementsDon\'TNeedDefaultWhenFullyCovered"
            ],
            disable_rules: ["GotoStatement"],     # List of rules to disable
            list_enabled_rules: true,             # List enabled rules
            enable_clang_static_analyzer: true,   # Enable Clang Static Analyzer, and integrate results into OCLint report
            enable_global_analysis: true,         # Compile every source, and analyze across global contexts (depends on number of source files, could results in high memory load)
            allow_duplicated_violations: true,    # Allow duplicated violations in the OCLint report
            extra_arg: "-Wno-everything"          # Additional argument to append to the compiler command line
          )'
        ]
      end

      def self.category
        :testing
      end
    end
  end
end
