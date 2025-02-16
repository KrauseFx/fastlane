module Fastlane
  module Actions
    class CocoapodsAction < Action
      # rubocop:disable Metrics/PerceivedComplexity
      def self.run(params)
        Actions.verify_gem!('cocoapods')
        cmd = []

        unless params[:podfile].nil?
          if params[:podfile].end_with?('Podfile')
            podfile_folder = File.dirname(params[:podfile])
          else
            podfile_folder = params[:podfile]
          end
          cmd << ["cd '#{podfile_folder}' &&"]
        end

        cmd << params[:environment_variables] if params[:environment_variables]

        cmd << ['bundle exec'] if use_bundle_exec?(params)
        cmd << ['pod install']

        cmd << '--no-clean' unless params[:clean]
        cmd << '--no-integrate' unless params[:integrate]
        cmd << '--clean-install' if params[:clean_install] && pod_version_at_least("1.7", params)
        cmd << '--allow-root' if params[:allow_root] && pod_version_at_least("1.10", params)
        cmd << '--repo-update' if params[:repo_update]
        cmd << '--silent' if params[:silent]
        cmd << '--verbose' if params[:verbose]
        cmd << '--no-ansi' unless params[:ansi]
        cmd << '--deployment' if params[:deployment]

        Actions.sh(cmd.join(' '), error_callback: lambda { |result|
          if !params[:repo_update] && params[:try_repo_update_on_error]
            cmd << '--repo-update'
            Actions.sh(cmd.join(' '), error_callback: lambda { |retry_result|
              call_error_callback(params, retry_result)
            })
          else
            call_error_callback(params, result)
          end
        })
      end

      def self.use_bundle_exec?(params)
        params[:use_bundle_exec] && shell_out_should_use_bundle_exec?
      end

      def self.pod_version(params)
        use_bundle_exec?(params) ? `bundle exec pod --version` : `pod --version`
      end

      def self.pod_version_at_least(at_least_version, params)
        version = pod_version(params)
        return Gem::Version.new(version) >= Gem::Version.new(at_least_version)
      end

      def self.call_error_callback(params, result)
        if params[:error_callback]
          Dir.chdir(FastlaneCore::FastlaneFolder.path) do
            params[:error_callback].call(result)
          end
        else
          UI.shell_error!(result)
        end
      end

      def self.description
        "Runs `pod install` for the project"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repo_update,
                                       env_name: "FL_COCOAPODS_REPO_UPDATE",
                                       description: "Add `--repo-update` flag to `pod install` command",
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :clean_install,
                                       env_name: "FL_COCOAPODS_CLEAN_INSTALL",
                                       description: "Execute a full pod installation ignoring the content of the project cache",
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :silent,
                                       env_name: "FL_COCOAPODS_SILENT",
                                       description: "Execute command without logging output",
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :verbose,
                                       env_name: "FL_COCOAPODS_VERBOSE",
                                       description: "Show more debugging information",
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :ansi,
                                       env_name: "FL_COCOAPODS_ANSI",
                                       description: "Show output with ANSI codes",
                                       type: Boolean,
                                       default_value: true),
          FastlaneCore::ConfigItem.new(key: :use_bundle_exec,
                                       env_name: "FL_COCOAPODS_USE_BUNDLE_EXEC",
                                       description: "Use bundle exec when there is a Gemfile presented",
                                       type: Boolean,
                                       default_value: true),
          FastlaneCore::ConfigItem.new(key: :podfile,
                                       env_name: "FL_COCOAPODS_PODFILE",
                                       description: "Explicitly specify the path to the Cocoapods' Podfile. You can either set it to the Podfile's path or to the folder containing the Podfile file",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Could not find Podfile") unless File.exist?(value) || Helper.test?
                                       end),
          FastlaneCore::ConfigItem.new(key: :error_callback,
                                       description: 'A callback invoked with the command output if there is a non-zero exit status',
                                       optional: true,
                                       type: :string_callback),
          FastlaneCore::ConfigItem.new(key: :try_repo_update_on_error,
                                       env_name: "FL_COCOAPODS_TRY_REPO_UPDATE_ON_ERROR",
                                       description: 'Retry with --repo-update if action was finished with error',
                                       optional: true,
                                       default_value: false,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :deployment,
                                       env_name: "FL_COCOAPODS_DEPLOYMENT",
                                       description: 'Disallow any changes to the Podfile or the Podfile.lock during installation',
                                       optional: true,
                                       default_value: false,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :allow_root,
                                       env_name: "FL_COCOAPODS_ALLOW_ROOT",
                                       description: 'Allows CocoaPods to run as root',
                                       optional: true,
                                       default_value: false,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :environment_variables,
                                       env_name: "FL_COCOAPODS_ENVIRONMENT_VARIABLES",
                                       description: "Environment variables when running pod install command",
                                       optional: true,
                                       default_value: nil,
                                       type: Array),

          # Deprecated
          FastlaneCore::ConfigItem.new(key: :clean,
                                       env_name: "FL_COCOAPODS_CLEAN",
                                       description: "(Option renamed as clean_install) Remove SCM directories",
                                       deprecated: true,
                                       type: Boolean,
                                       default_value: true),
          FastlaneCore::ConfigItem.new(key: :integrate,
                                       env_name: "FL_COCOAPODS_INTEGRATE",
                                       description: "(Option removed from cocoapods) Integrate the Pods libraries into the Xcode project(s)",
                                       deprecated: true,
                                       type: Boolean,
                                       default_value: true)
        ]
        # Please don't add a version parameter to the `cocoapods` action. If you need to specify a version when running
        # `cocoapods`, please start using a Gemfile and lock the version there
        # More information https://docs.fastlane.tools/getting-started/ios/setup/#use-a-gemfile
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.authors
        ["KrauseFx", "tadpol", "birmacher", "Liquidsoul"]
      end

      def self.details
        "If you use [CocoaPods](http://cocoapods.org) you can use the `cocoapods` integration to run `pod install` before building your app."
      end

      def self.example_code
        [
          'cocoapods',
          'cocoapods(
            clean_install: true,
            podfile: "./CustomPodfile"
          )'
        ]
      end

      def self.category
        :building
      end
    end
  end
end
