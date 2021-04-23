module Fastlane
  module Actions
    class SetupCiAction < Action
      def self.run(params)
        unless should_run?(params)
          UI.message("Not running on CI, skipping CI setup")
          return
        end

        case detect_provider(params)
        when 'circleci'
          setup_output_paths
        end

        setup_keychain
      end

      def self.should_run?(params)
        Helper.ci? || params[:force]
      end

      def self.detect_provider(params)
        params[:provider] || (Helper.is_circle_ci? ? 'circleci' : nil)
      end

      def self.setup_keychain
        unless Helper.mac?
          UI.message("Skipping Keychain setup on non-macOS CI Agent")
          return
        end

        unless ENV["MATCH_KEYCHAIN_NAME"].nil?
          UI.message("Skipping Keychain setup as a keychain was already specified")
          return
        end

        keychain_name = "fastlane_tmp_keychain"
        ENV["MATCH_KEYCHAIN_NAME"] = keychain_name
        ENV["MATCH_KEYCHAIN_PASSWORD"] = ""

        UI.message("Creating temporary keychain: \"#{keychain_name}\".")
        Actions::CreateKeychainAction.run(
          name: keychain_name,
          default_keychain: true,
          unlock: true,
          timeout: 3600,
          lock_when_sleeps: true,
          password: "",
          add_to_search_list: true
        )

        UI.message("Enabling match readonly mode.")
        ENV["MATCH_READONLY"] = true.to_s
      end

      def self.setup_output_paths
        unless ENV["FL_OUTPUT_DIR"]
          UI.message("Skipping Log Path setup as FL_OUTPUT_DIR is unset")
          return
        end

        root = Pathname.new(ENV["FL_OUTPUT_DIR"])
        ENV["SCAN_OUTPUT_DIRECTORY"] = (root + "scan").to_s
        ENV["GYM_OUTPUT_DIRECTORY"] = (root + "gym").to_s
        ENV["FL_BUILDLOG_PATH"] = (root + "buildlogs").to_s
        ENV["SCAN_INCLUDE_SIMULATOR_LOGS"] = true.to_s
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Setup the keychain and match to work with CI"
      end

      def self.details
        list = <<-LIST.markdown_list(true)
            Creates a new temporary keychain for use with match
            Switches match to `readonly` mode to not create new profiles/cert on CI
            Sets up log and test result paths to be easily collectible
        LIST

        [
          list,
          "This action helps with CI integration. Add this to the top of your Fastfile if you use CI."
        ].join("\n")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :force,
                                       env_name: "FL_SETUP_CI_FORCE",
                                       description: "Force setup, even if not executed by CI",
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :provider,
                                       env_name: "FL_SETUP_CI_PROVIDER",
                                       description: "CI provider. If none is set, the provider is detected automatically",
                                       is_string: true,
                                       optional: true,
                                       verify_block: proc do |value|
                                         value = value.to_s
                                         # Validate both 'travis' and 'circleci' for backwards compatibility, even
                                         # though only the latter receives special treatment by this action
                                         UI.user_error!("A given CI provider '#{value}' is not supported. Available CI providers: 'travis', 'circleci'") unless ["travis", "circleci"].include?(value)
                                       end)
        ]
      end

      def self.authors
        ["mollyIV", "svenmuennich"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.example_code
        [
          'setup_ci(
            provider: "circleci"
          )'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
