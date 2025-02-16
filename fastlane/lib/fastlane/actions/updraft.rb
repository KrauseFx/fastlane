module Fastlane
  module Actions
    module SharedValues
    end

    class UpdraftAction < Action
      def self.run(params)
        begin
          UI.important("Collecting the necessary data to upload...")

          path = params[:ipa] || params[:apk] || params[:aab]
          UI.user_error!("Please provide ipa, apk or aab file") unless path

          git_url = Helper.backticks("git remote get-url origin").to_s
          git_branch = Actions.git_branch.to_s
          git_tag = Helper.backticks("git tag -l --points-at HEAD").to_s
          git_commit_hash = Helper.backticks("git rev-parse HEAD").to_s

          whats_new = params[:changelog]

          if params[:ipa]
            bundle_version = Fastlane::Actions::GetIpaInfoPlistValueAction.run(ipa: params[:ipa], key: "CFBundleVersion").to_s
          end

          build_type = other_action.is_ci? ? "CI" : "Fastlane"

          curl_command = "curl -X PUT"
          curl_command << " -F 'app=@#{path}'"
          curl_command << " -F 'custom_git_url=#{git_url}'"
          curl_command << " -F 'custom_git_branch=#{git_branch}'"
          curl_command << " -F 'custom_git_tag=#{git_tag}'"
          curl_command << " -F 'custom_git_commit_hash=#{git_commit_hash}'"
          curl_command << " -F 'whats_new=#{whats_new}'"
          curl_command << " -F 'custom_bundle_version=#{bundle_version}'"
          curl_command << " -F 'build_type=#{build_type}'"
          curl_command << " " << params[:upload_url]
          curl_command << " --http1.1"

          UI.important("Uploading build to Updraft. This might take a while...")

          FastlaneCore::CommandExecutor.execute(
            command: curl_command,
            print_all: false,
            error: proc do |error_output|
              UI.crash!("Uploading to Updraft failed!")
            end
            )

          UI.success("Successfully uploaded build to Updraft!")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.category
        :beta
      end

      def self.description
        "Upload a release to getupdraft.com for testing"
      end

      def self.details
        [
          "You can run this directly after Gym to upload the build that was created, or set your own .ipa path.",
          "In all cases, you will need to provide a URL for uploading to. You can get this in your Updraft Project Settings"
        ].join("\n")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :upload_url,
            optional: false,
            env_name: "UPDRAFT_URL",
            description: "Project Specific API Upload URL. You can get this in your Updraft Project Settings",
            sensitive: true,
            verify_block: proc do |value|
              UI.user_error!("No URL for Updraft given, pass using `upload_url: 'url'`") unless value.to_s.length > 0
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :ipa,
            optional: true,
            default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
            default_value_dynamic: true,
            conflicting_options: [:apk, :aab],
            env_name: "UPDRAFT_IPA_PATH",
            description: "Path to your ipa file",
            verify_block: proc do |value|
              UI.user_error!("Could not find ipa file at path '#{File.expand_path(value)}'") unless File.exist?(value)
              UI.user_error("'#{value}' doesn't seem to be an ipa file") unless value.end_with?(".ipa")
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :apk,
            optional: true,
            default_value: Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH],
            default_value_dynamic: true,
            conflicting_options: [:ipa, :aab],
            env_name: "UPDRAFT_APK_PATH",
            description: "Path to your apk file",
            verify_block: proc do |value|
              UI.user_error!("Could not find apk file at path '#{File.expand_path(value)}'") unless File.exist?(value)
              UI.user_error("'#{value}' doesn't seem to be an apk file") unless value.end_with?(".apk")
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :aab,
            optional: true,
            default_value: Actions.lane_context[SharedValues::GRADLE_AAB_OUTPUT_PATH],
            default_value_dynamic: true,
            conflicting_options: [:ipa, :apk],
            env_name: "UPDRAFT_AAB_PATH",
            description: "Path to your aab file",
            verify_block: proc do |value|
              UI.user_error!("Could not find aab file at path '#{File.expand_path(value)}'") unless File.exist?(value)
              UI.user_error("'#{value}' doesn't seem to be an aab file") unless value.end_with?(".aab")
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :changelog,
            optional: true,
            default_value: Helper.backticks("git log -1 --pretty=%B").to_s.strip,
            default_value_dynamic: true,
            env_name: "CHANGE_LOG",
            description: "Write version changes"
          )
        ]
      end

      def self.example_code
        [
          'updraft(
            upload_url: "https://getupdraft.com/api/app_upload/123a4ab5678c91234cec567891b2babc/dde1cd23f4567a8cbdb91d23456b7c89/",
            ipa: "./fastlane/ipa_file.ipa",
            changelog: "New cool feature for iOS",
          )',
          'updraft(
            upload_url: "https://getupdraft.com/api/app_upload/987a6ab5432c19876cec543219b8babc/dde1cd23f4567a8cbdb91d23456b7c89/",
            apk: "./fastlane/apk_file.apk",
            changelog: "New cool feature for Android",
           )',
          'updraft(
            upload_url: "https://getupdraft.com/api/app_upload/987a6ab5432c19876cec543219b8babc/dde1cd23f4567a8cbdb91d23456b7c89/",
            aab: "./fastlane/aab_file.aab",
            changelog: "Upload app bundle to Store",
           )'
        ]
      end

      def self.authors
        ["astulz"]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end
