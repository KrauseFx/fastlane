module Fastlane
  module Actions
    class PodLibLintAction < Action
      # rubocop:disable Metrics/PerceivedComplexity
      def self.run(params)
        command = []

        command << "bundle exec" if params[:use_bundle_exec] && shell_out_should_use_bundle_exec?
        command << "pod lib lint"

        command << params[:podspec] if params[:podspec]
        command << "--verbose" if params[:verbose]
        command << "--allow-warnings" if params[:allow_warnings]
        command << "--sources='#{params[:sources].join(',')}'" if params[:sources]
        command << "--subspec='#{params[:subspec]}'" if params[:subspec]
        command << "--include-podspecs='#{params[:include_podspecs]}'" if params[:include_podspecs]
        command << "--external-podspecs='#{params[:external_podspecs]}'" if params[:external_podspecs]
        command << "--swift-version=#{params[:swift_version]}" if params[:swift_version]
        command << "--use-libraries" if params[:use_libraries]
        command << "--use-modular-headers" if params[:use_modular_headers]
        command << "--fail-fast" if params[:fail_fast]
        command << "--private" if params[:private]
        command << "--quick" if params[:quick]
        command << "--no-clean" if params[:no_clean]
        command << "--no-subspecs" if params[:no_subspecs]
        command << "--platforms=#{params[:platforms]}" if params[:platforms]
        command << "--skip-import-validation" if params[:skip_import_validation]
        command << "--skip-tests" if params[:skip_tests]
        command << "--analyze" if params[:analyze]
        command << "--configuration=#{params[:configuration]}" if params[:configuration]

        result = Actions.sh(command.join(' '))
        UI.success("Pod lib lint successful ⬆️ ")
        return result
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Pod lib lint"
      end

      def self.details
        "Test the syntax of your Podfile by linting the pod against the files of its directory"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :use_bundle_exec,
                                       description: "Use bundle exec when there is a Gemfile presented",
                                       type: Boolean,
                                       default_value: true,
                                       env_name: "FL_POD_LIB_LINT_USE_BUNDLE"),
          FastlaneCore::ConfigItem.new(key: :podspec,
                                       description: "Path of spec to lint",
                                       type: String,
                                       optional: true,
                                       env_name: "FL_POD_LIB_LINT_PODSPEC"),
          FastlaneCore::ConfigItem.new(key: :verbose,
                                       description: "Allow output detail in console",
                                       type: Boolean,
                                       optional: true,
                                       env_name: "FL_POD_LIB_LINT_VERBOSE"),
          FastlaneCore::ConfigItem.new(key: :allow_warnings,
                                       description: "Allow warnings during pod lint",
                                       type: Boolean,
                                       optional: true,
                                       env_name: "FL_POD_LIB_LINT_ALLOW_WARNINGS"),
          FastlaneCore::ConfigItem.new(key: :sources,
                                       description: "The sources of repos you want the pod spec to lint with, separated by commas",
                                       type: Array,
                                       optional: true,
                                       env_name: "FL_POD_LIB_LINT_SOURCES",
                                       verify_block: proc do |value|
                                         UI.user_error!("Sources must be an array.") unless value.kind_of?(Array)
                                       end),
          FastlaneCore::ConfigItem.new(key: :subspec,
                                       description: "A specific subspec to lint instead of the entire spec",
                                       type: String,
                                       optional: true,
                                       env_name: "FL_POD_LIB_LINT_SUBSPEC"),
          FastlaneCore::ConfigItem.new(key: :include_podspecs,
                                       description: "A Glob of additional ancillary podspecs which are used for linting via :path (available since cocoapods >= 1.7)",
                                       type: String,
                                       optional: true,
                                       env_name: "FL_POD_LIB_LINT_INCLUDE_PODSPECS"),
          FastlaneCore::ConfigItem.new(key: :external_podspecs,
                                       description: "A Glob of additional ancillary podspecs which are used for linting via :podspec. If there"\
                                         " are --include-podspecs, then these are removed from them (available since cocoapods >= 1.7)",
                                       type: String,
                                       optional: true,
                                       env_name: "FL_POD_LIB_LINT_EXTERNAL_PODSPECS"),
          FastlaneCore::ConfigItem.new(key: :swift_version,
                                       description: "The SWIFT_VERSION that should be used to lint the spec. This takes precedence over a .swift-version file",
                                       type: String,
                                       optional: true,
                                       env_name: "FL_POD_LIB_LINT_SWIFT_VERSION"),
          FastlaneCore::ConfigItem.new(key: :use_libraries,
                                       description: "Lint uses static libraries to install the spec",
                                       type: Boolean,
                                       default_value: false,
                                       env_name: "FL_POD_LIB_LINT_USE_LIBRARIES"),
          FastlaneCore::ConfigItem.new(key: :use_modular_headers,
                                       description: "Lint using modular libraries (available since cocoapods >= 1.6)",
                                       type: Boolean,
                                       default_value: false,
                                       env_name: "FL_POD_LIB_LINT_USE_MODULAR_HEADERS"),
          FastlaneCore::ConfigItem.new(key: :fail_fast,
                                       description: "Lint stops on the first failing platform or subspec",
                                       type: Boolean,
                                       default_value: false,
                                       env_name: "FL_POD_LIB_LINT_FAIL_FAST"),
          FastlaneCore::ConfigItem.new(key: :private,
                                       description: "Lint skips checks that apply only to public specs",
                                       type: Boolean,
                                       default_value: false,
                                       env_name: "FL_POD_LIB_LINT_PRIVATE"),
          FastlaneCore::ConfigItem.new(key: :quick,
                                       description: "Lint skips checks that would require to download and build the spec",
                                       type: Boolean,
                                       default_value: false,
                                       env_name: "FL_POD_LIB_LINT_QUICK"),
          FastlaneCore::ConfigItem.new(key: :no_clean,
                                       description: "Lint leaves the build directory intact for inspection",
                                       type: Boolean,
                                       default_value: false,
                                       env_name: "FL_POD_LIB_LINT_NO_CLEAN"),
          FastlaneCore::ConfigItem.new(key: :no_subspecs,
                                       description: "Lint skips validation of subspecs",
                                       type: Boolean,
                                       default_value: false,
                                       env_name: "FL_POD_LIB_LINT_NO_SUBSPECS"),
          FastlaneCore::ConfigItem.new(key: :platforms,
                                       description: "Lint against specific platforms (defaults to all platforms supported by "\
                                          "the podspec). Multiple platforms must be comma-delimited (available since cocoapods >= 1.6)",
                                       optional: true,
                                       env_name: "FL_POD_LIB_LINT_PLATFORMS"),
          FastlaneCore::ConfigItem.new(key: :skip_import_validation,
                                       description: "Lint skips validating that the pod can be imported (available since cocoapods >= 1.3)",
                                       type: Boolean,
                                       default_value: false,
                                       env_name: "FL_POD_LIB_LINT_SKIP_IMPORT_VALIDATION"),
          FastlaneCore::ConfigItem.new(key: :skip_tests,
                                       description: "Lint skips building and running tests during validation (available since cocoapods >= 1.3)",
                                       type: Boolean,
                                       default_value: false,
                                       env_name: "FL_POD_LIB_LINT_SKIP_TESTS"),
          FastlaneCore::ConfigItem.new(key: :analyze,
                                       description: "Validate with the Xcode Static Analysis tool (available since cocoapods >= 1.6.1)",
                                       type: Boolean,
                                       default_value: false,
                                       env_name: "FL_POD_LIB_LINT_ANALYZE"),
          FastlaneCore::ConfigItem.new(key: :configuration,
                                       description: "Build using the given configuration (if not provided, configuration defaults to Release)",
                                       type: String,
                                       optional: true,
                                       env_name: "FL_POD_LIB_LINT_CONFIGURATION")
        ]
      end

      def self.output
      end

      def self.return_value
        nil
      end

      def self.authors
        ["thierryxing"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.example_code
        [
          'pod_lib_lint',
          '# Allow output detail in console
          pod_lib_lint(verbose: true)',
          '# Allow warnings during pod lint
          pod_lib_lint(allow_warnings: true)',
          '# If the podspec has a dependency on another private pod, then you will have to supply the sources
          pod_lib_lint(sources: ["https://github.com/username/Specs", "https://github.com/CocoaPods/Specs"])'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
