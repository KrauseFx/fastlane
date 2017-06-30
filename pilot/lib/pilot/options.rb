require "fastlane_core"
require "credentials_manager"

module Pilot
  class Options
    def self.available_options
      user = CredentialsManager::AppfileConfig.try_fetch_value(:itunes_connect_id)
      user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)

      [
        FastlaneCore::ConfigItem.new(key: :username,
                                     short_option: "-u",
                                     env_name: "PILOT_USERNAME",
                                     description: "Your Apple ID Username",
                                     default_value: user),
        FastlaneCore::ConfigItem.new(key: :app_identifier,
                                     short_option: "-a",
                                     env_name: "PILOT_APP_IDENTIFIER",
                                     description: "The bundle identifier of the app to upload or manage testers (optional)",
                                     optional: true,
                                     default_value: ENV["TESTFLIGHT_APP_IDENTITIFER"] || CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)),
        FastlaneCore::ConfigItem.new(key: :app_platform,
                                     short_option: "-m",
                                     env_name: "PILOT_PLATFORM",
                                     description: "The platform to use (optional)",
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("The platform can only be ios, appletvos, or osx") unless ['ios', 'appletvos', 'osx'].include? value
                                     end),
        FastlaneCore::ConfigItem.new(key: :ipa,
                                     short_option: "-i",
                                     optional: true,
                                     env_name: "PILOT_IPA",
                                     description: "Path to the ipa file to upload",
                                     default_value: Dir["*.ipa"].sort_by { |x| File.mtime(x) }.last,
                                     verify_block: proc do |value|
                                       value = File.expand_path(value)
                                       UI.user_error!("Could not find ipa file at path '#{value}'") unless File.exist? value
                                       UI.user_error!("'#{value}' doesn't seem to be an ipa file") unless value.end_with? ".ipa"
                                     end),
        FastlaneCore::ConfigItem.new(key: :changelog,
                                     short_option: "-w",
                                     optional: true,
                                     env_name: "PILOT_CHANGELOG",
                                     description: "Provide the what's new text when uploading a new build"),
        FastlaneCore::ConfigItem.new(key: :beta_app_description,
                                     short_option: "-d",
                                     optional: true,
                                     env_name: "PILOT_BETA_APP_DESCRIPTION",
                                     description: "Provide the beta app description when uploading a new build"),
        FastlaneCore::ConfigItem.new(key: :beta_app_feedback_email,
                                     short_option: "-n",
                                     optional: true,
                                     env_name: "PILOT_BETA_APP_FEEDBACK",
                                     description: "Provide the beta app email when uploading a new build"),
        FastlaneCore::ConfigItem.new(key: :skip_submission,
                                     short_option: "-s",
                                     env_name: "PILOT_SKIP_SUBMISSION",
                                     description: "Skip the distributing action of pilot and only upload the ipa file",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_waiting_for_build_processing,
                                     short_option: "-z",
                                     env_name: "PILOT_SKIP_WAITING_FOR_BUILD_PROCESSING",
                                     description: "Don't wait for the build to process. If set to true, the changelog won't be set, `distribute_external` option won't work and no build will be distributed to testers",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :update_build_info_on_upload,
                                     deprecated: true,
                                     short_option: "-x",
                                     env_name: "PILOT_UPDATE_BUILD_INFO_ON_UPLOAD",
                                     description: "Update build info immediately after validation. This is deprecated and will be removed in a future release. iTunesConnect no longer supports setting build info until after build processing has completed, which is when build info is updated by default",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :apple_id,
                                     short_option: "-p",
                                     env_name: "PILOT_APPLE_ID",
                                     description: "The unique App ID provided by iTunes Connect",
                                     optional: true,
                                     default_value: ENV["TESTFLIGHT_APPLE_ID"]),
        FastlaneCore::ConfigItem.new(key: :distribute_external,
                                     is_string: false,
                                     env_name: "PILOT_DISTRIBUTE_EXTERNAL",
                                     description: "Should the build be distributed to external testers?",
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :first_name,
                                     short_option: "-f",
                                     env_name: "PILOT_TESTER_FIRST_NAME",
                                     description: "The tester's first name",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :last_name,
                                     short_option: "-l",
                                     env_name: "PILOT_TESTER_LAST_NAME",
                                     description: "The tester's last name",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :email,
                                     short_option: "-e",
                                     env_name: "PILOT_TESTER_EMAIL",
                                     description: "The tester's email",
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Please pass a valid email address") unless value.include? "@"
                                     end),
        FastlaneCore::ConfigItem.new(key: :testers_file_path,
                                     short_option: "-c",
                                     env_name: "PILOT_TESTERS_FILE",
                                     description: "Path to a CSV file of testers",
                                     default_value: "./testers.csv",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :wait_processing_interval,
                                     short_option: "-k",
                                     env_name: "PILOT_WAIT_PROCESSING_INTERVAL",
                                     description: "Interval in seconds to wait for iTunes Connect processing",
                                     default_value: 30,
                                     type: Integer,
                                     verify_block: proc do |value|
                                       UI.user_error!("Please enter a valid positive number of seconds") unless value.to_i > 0
                                     end),
        FastlaneCore::ConfigItem.new(key: :team_id,
                                     short_option: "-q",
                                     env_name: "PILOT_TEAM_ID",
                                     description: "The ID of your iTunes Connect team if you're in multiple teams",
                                     optional: true,
                                     is_string: false, # as we also allow integers, which we convert to strings anyway
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_id),
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_ITC_TEAM_ID"] = value.to_s
                                     end),
        FastlaneCore::ConfigItem.new(key: :team_name,
                                     short_option: "-r",
                                     env_name: "PILOT_TEAM_NAME",
                                     description: "The name of your iTunes Connect team if you're in multiple teams",
                                     optional: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_name),
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_ITC_TEAM_NAME"] = value.to_s
                                     end),
        FastlaneCore::ConfigItem.new(key: :dev_portal_team_id,
                                     env_name: "PILOT_DEV_PORTAL_TEAM_ID",
                                     description: "The short ID of your team in the developer portal, if you're in multiple teams. Different from your iTC team ID!",
                                     optional: true,
                                     is_string: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_id),
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_TEAM_ID"] = value.to_s
                                     end),
        FastlaneCore::ConfigItem.new(key: :itc_provider,
                                     env_name: "PILOT_ITC_PROVIDER",
                                     description: "The provider short name to be used with the iTMSTransporter to identify your team",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :groups,
                                     short_option: "-g",
                                     env_name: "PILOT_GROUPS",
                                     description: "Associate tester to one group or more by group name / group id. E.g. '-g \"Team 1\",\"Team 2\"'",
                                     optional: true,
                                     type: Array,
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not evaluate array from '#{value}'") unless value.kind_of?(Array)
                                     end)
      ]
    end
  end
end
