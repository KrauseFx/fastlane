require 'fastlane_core/configuration/config_item'
require 'credentials_manager/appfile_config'

require_relative 'module'

module Pilot
  # rubocop:disable Metrics/ClassLength
  # rubocop:disable Metrics/PerceivedComplexity
  class Options
    def self.available_options
      user = CredentialsManager::AppfileConfig.try_fetch_value(:itunes_connect_id)
      user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)

      [
        FastlaneCore::ConfigItem.new(key: :api_key_path,
                                     env_names: ["PILOT_API_KEY_PATH", "APP_STORE_CONNECT_API_KEY_PATH"],
                                     description: "Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)",
                                     optional: true,
                                     conflicting_options: [:username],
                                     verify_block: proc do |value|
                                       UI.user_error!("Couldn't find API key JSON file at path '#{value}'") unless File.exist?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :api_key,
                                     env_names: ["PILOT_API_KEY", "APP_STORE_CONNECT_API_KEY"],
                                     description: "Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)",
                                     type: Hash,
                                     optional: true,
                                     sensitive: true,
                                     conflicting_options: [:api_key_path, :username]),

        # app upload info
        FastlaneCore::ConfigItem.new(key: :username,
                                     short_option: "-u",
                                     env_name: "PILOT_USERNAME",
                                     description: "Your Apple ID Username",
                                     optional: true,
                                     default_value: user,
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :app_identifier,
                                     short_option: "-a",
                                     env_name: "PILOT_APP_IDENTIFIER",
                                     description: "The bundle identifier of the app to upload or manage testers (optional)",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     # This incorrect env name is here for backwards compatibility
                                     default_value: ENV["TESTFLIGHT_APP_IDENTITIFER"] || CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier),
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :app_platform,
                                     short_option: "-m",
                                     env_name: "PILOT_PLATFORM",
                                     description: "The platform to use (optional)",
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("The platform can only be ios, appletvos, osx, or xros") unless ['ios', 'appletvos', 'osx', 'xros'].include?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :apple_id,
                                     short_option: "-p",
                                     env_name: "PILOT_APPLE_ID",
                                     description: "Apple ID property in the App Information section in App Store Connect",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     default_value: ENV["TESTFLIGHT_APPLE_ID"],
                                     default_value_dynamic: true,
                                     type: String,
                                     verify_block: proc do |value|
                                       error_message = "`apple_id` value is incorrect. The correct value should be taken from Apple ID property in the App Information section in App Store Connect."

                                       # Validate if the value is not an email address
                                       UI.user_error!(error_message) if value =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

                                       # Validate if the value is not a bundle identifier
                                       UI.user_error!(error_message) if value =~ /^[A-Za-x]{2,6}((?!-)\.[A-Za-z0-9-]{1,63}(?<!-))+$/i
                                     end),
        FastlaneCore::ConfigItem.new(key: :ipa,
                                     short_option: "-i",
                                     optional: true,
                                     env_name: "PILOT_IPA",
                                     description: "Path to the ipa file to upload",
                                     code_gen_sensitive: true,
                                     default_value: Dir["*.ipa"].sort_by { |x| File.mtime(x) }.last,
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       value = File.expand_path(value)
                                       UI.user_error!("Could not find ipa file at path '#{value}'") unless File.exist?(value)
                                       UI.user_error!("'#{value}' doesn't seem to be an ipa file") unless value.end_with?(".ipa")
                                     end,
                                     conflicting_options: [:pkg],
                                     conflict_block: proc do |value|
                                       UI.user_error!("You can't use 'ipa' and '#{value.key}' options in one run.")
                                     end),
        FastlaneCore::ConfigItem.new(key: :pkg,
                                     short_option: "-P",
                                     optional: true,
                                     env_name: "PILOT_PKG",
                                     description: "Path to your pkg file",
                                     code_gen_sensitive: true,
                                     default_value: Dir["*.pkg"].sort_by { |x| File.mtime(x) }.last,
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not find pkg file at path '#{File.expand_path(value)}'") unless File.exist?(value)
                                       UI.user_error!("'#{value}' doesn't seem to be a pkg file") unless value.end_with?(".pkg")
                                     end,
                                     conflicting_options: [:ipa],
                                     conflict_block: proc do |value|
                                       UI.user_error!("You can't use 'pkg' and '#{value.key}' options in one run.")
                                     end),

        # app review info
        FastlaneCore::ConfigItem.new(key: :demo_account_required,
                                     type: Boolean,
                                     env_name: "DEMO_ACCOUNT_REQUIRED",
                                     description: "Do you need a demo account when Apple does review?",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :beta_app_review_info,
                                     type: Hash,
                                     env_name: "PILOT_BETA_APP_REVIEW_INFO",
                                     description: "Beta app review information for contact info and demo account",
                                     optional: true,
                                     verify_block: proc do |values|
                                       valid_keys = %w(contact_email contact_first_name contact_last_name contact_phone demo_account_required demo_account_name demo_account_password notes)
                                       values.keys.each { |value| UI.user_error!("Invalid key '#{value}'") unless valid_keys.include?(value.to_s) }
                                     end),

        # app detail
        FastlaneCore::ConfigItem.new(key: :localized_app_info,
                                     type: Hash,
                                     env_name: "PILOT_LOCALIZED_APP_INFO",
                                     description: "Localized beta app test info for description, feedback email, marketing url, and privacy policy",
                                     optional: true,
                                     verify_block: proc do |lang_values|
                                       valid_keys = %w(feedback_email marketing_url privacy_policy_url tv_os_privacy_policy_url description)
                                       lang_values.values.each do |values|
                                         values.keys.each { |value| UI.user_error!("Invalid key '#{value}'") unless valid_keys.include?(value.to_s) }
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :beta_app_description,
                                     short_option: "-d",
                                     optional: true,
                                     env_name: "PILOT_BETA_APP_DESCRIPTION",
                                     description: "Provide the 'Beta App Description' when uploading a new build"),
        FastlaneCore::ConfigItem.new(key: :beta_app_feedback_email,
                                     short_option: "-n",
                                     optional: true,
                                     env_name: "PILOT_BETA_APP_FEEDBACK",
                                     description: "Provide the beta app email when uploading a new build"),

        # build review info
        FastlaneCore::ConfigItem.new(key: :localized_build_info,
                                     type: Hash,
                                     env_name: "PILOT_LOCALIZED_BUILD_INFO",
                                     description: "Localized beta app test info for what's new",
                                     optional: true,
                                     verify_block: proc do |lang_values|
                                       valid_keys = %w(whats_new)
                                       lang_values.values.each do |values|
                                         values.keys.each { |value| UI.user_error!("Invalid key '#{value}'") unless valid_keys.include?(value.to_s) }
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :changelog,
                                     short_option: "-w",
                                     optional: true,
                                     env_name: "PILOT_CHANGELOG",
                                     description: "Provide the 'What to Test' text when uploading a new build"),
        FastlaneCore::ConfigItem.new(key: :skip_submission,
                                     short_option: "-s",
                                     env_name: "PILOT_SKIP_SUBMISSION",
                                     description: "Skip the distributing action of pilot and only upload the ipa file",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_waiting_for_build_processing,
                                     short_option: "-z",
                                     env_name: "PILOT_SKIP_WAITING_FOR_BUILD_PROCESSING",
                                     description: "If set to true, the `distribute_external` option won't work and no build will be distributed to testers. " \
                                      "(You might want to use this option if you are using this action on CI and have to pay for 'minutes used' on your CI plan). " \
                                      "If set to `true` and a changelog is provided, it will partially wait for the build to appear on AppStore Connect so the changelog can be set, and skip the remaining processing steps",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :update_build_info_on_upload,
                                     deprecated: true,
                                     short_option: "-x",
                                     env_name: "PILOT_UPDATE_BUILD_INFO_ON_UPLOAD",
                                     description: "Update build info immediately after validation. This is deprecated and will be removed in a future release. App Store Connect no longer supports setting build info until after build processing has completed, which is when build info is updated by default",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :app_clip_invocations,
                                     env_name: "APP_CLIP_INVOCATIONS",
                                     description: "Add beta app clip invocations to your builds in TestFlight",
                                     optional: true,
                                     type: Array,
                                     verify_block: proc do |app_clip_invocations|
                                       UI.user_error!("Could not evaluate array from '#{app_clip_invocations}'") unless app_clip_invocations.kind_of?(Array)

                                       app_clip_invocations.each do |invocation|
                                         UI.user_error!("Each app clip invocation must contain a url.") unless invocation[:url]
                                         UI.user_error!("Each app clip invocation must contain a localized title.") unless invocation[:title] && invocation[:title].kind_of?(Hash)
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :overwrite_app_clip_invocations,
                                     env_name: "OVERWRITE_APP_CLIP_INVOCATIONS",
                                     description: "Clear all previous beta app clip invocations before adding new ones",
                                     optional: true,
                                     type: Boolean,
                                     default_value: false),

        # distribution
        FastlaneCore::ConfigItem.new(key: :distribute_only,
                                     short_option: "-D",
                                     env_name: "PILOT_DISTRIBUTE_ONLY",
                                     description: "Distribute a previously uploaded build (equivalent to the `fastlane pilot distribute` command)",
                                     default_value: false,
                                     type: Boolean),
        FastlaneCore::ConfigItem.new(key: :uses_non_exempt_encryption,
                                     short_option: "-X",
                                     env_name: "PILOT_USES_NON_EXEMPT_ENCRYPTION",
                                     description: "Provide the 'Uses Non-Exempt Encryption' for export compliance. This is used if there is 'ITSAppUsesNonExemptEncryption' is not set in the Info.plist",
                                     default_value: false,
                                     type: Boolean),
        FastlaneCore::ConfigItem.new(key: :distribute_external,
                                     is_string: false,
                                     env_name: "PILOT_DISTRIBUTE_EXTERNAL",
                                     description: "Should the build be distributed to external testers? If set to true, use of `groups` option is required",
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :notify_external_testers,
                                    is_string: false,
                                    env_name: "PILOT_NOTIFY_EXTERNAL_TESTERS",
                                    description: "Should notify external testers? (Not setting a value will use App Store Connect's default which is to notify)",
                                    optional: true),
        FastlaneCore::ConfigItem.new(key: :app_version,
                                     env_name: "PILOT_APP_VERSION",
                                     description: "The version number of the application build to distribute. If the version number is not specified, then the most recent build uploaded to TestFlight will be distributed. If specified, the most recent build for the version number will be distributed",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :build_number,
                                     env_name: "PILOT_BUILD_NUMBER",
                                     description: "The build number of the application build to distribute. If the build number is not specified, the most recent build is distributed",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :expire_previous_builds,
                                     is_string: false,
                                     env_name: "PILOT_EXPIRE_PREVIOUS_BUILDS",
                                     description: "Should expire previous builds?",
                                     default_value: false),

        # testers
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
                                       UI.user_error!("Please pass a valid email address") unless value.include?("@")
                                     end),
        FastlaneCore::ConfigItem.new(key: :testers_file_path,
                                     short_option: "-c",
                                     env_name: "PILOT_TESTERS_FILE",
                                     description: "Path to a CSV file of testers",
                                     default_value: "./testers.csv",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :groups,
                                     short_option: "-g",
                                     env_name: "PILOT_GROUPS",
                                     description: "Associate tester to one group or more by group name / group id. E.g. `-g \"Team 1\",\"Team 2\"` This is required when `distribute_external` option is set to true or when we want to add a tester to one or more external testing groups ",
                                     optional: true,
                                     type: Array,
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not evaluate array from '#{value}'") unless value.kind_of?(Array)
                                     end),

        # app store connect teams
        FastlaneCore::ConfigItem.new(key: :team_id,
                                     short_option: "-q",
                                     env_name: "PILOT_TEAM_ID",
                                     description: "The ID of your App Store Connect team if you're in multiple teams",
                                     optional: true,
                                     is_string: false, # as we also allow integers, which we convert to strings anyway
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_id),
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_ITC_TEAM_ID"] = value.to_s
                                     end),
        FastlaneCore::ConfigItem.new(key: :team_name,
                                     short_option: "-r",
                                     env_name: "PILOT_TEAM_NAME",
                                     description: "The name of your App Store Connect team if you're in multiple teams",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_name),
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_ITC_TEAM_NAME"] = value.to_s
                                     end),
        FastlaneCore::ConfigItem.new(key: :dev_portal_team_id,
                                     env_name: "PILOT_DEV_PORTAL_TEAM_ID",
                                     description: "The short ID of your team in the developer portal, if you're in multiple teams. Different from your iTC team ID!",
                                     optional: true,
                                     is_string: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_id),
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_TEAM_ID"] = value.to_s
                                     end),
        # rubocop:disable Layout/LineLength
        FastlaneCore::ConfigItem.new(key: :itc_provider,
                                     env_name: "PILOT_ITC_PROVIDER",
                                     description: "The provider short name to be used with the iTMSTransporter to identify your team. This value will override the automatically detected provider short name. To get provider short name run `pathToXcode.app/Contents/Applications/Application\\ Loader.app/Contents/itms/bin/iTMSTransporter -m provider -u 'USERNAME' -p 'PASSWORD' -account_type itunes_connect -v off`. The short names of providers should be listed in the second column",
                                     optional: true),
        # rubocop:enable Layout/LineLength

        # waiting and uploaded build
        FastlaneCore::ConfigItem.new(key: :wait_processing_interval,
                                     short_option: "-k",
                                     env_name: "PILOT_WAIT_PROCESSING_INTERVAL",
                                     description: "Interval in seconds to wait for App Store Connect processing",
                                     default_value: 30,
                                     type: Integer,
                                     verify_block: proc do |value|
                                       UI.user_error!("Please enter a valid positive number of seconds") unless value.to_i > 0
                                     end),
        FastlaneCore::ConfigItem.new(key: :wait_processing_timeout_duration,
                                     env_name: "PILOT_WAIT_PROCESSING_TIMEOUT_DURATION",
                                     description: "Timeout duration in seconds to wait for App Store Connect processing. If set, after exceeding timeout duration, this will `force stop` to wait for App Store Connect processing and exit with exception",
                                     optional: true,
                                     type: Integer,
                                     verify_block: proc do |value|
                                       UI.user_error!("Please enter a valid positive number of seconds") unless value.to_i > 0
                                     end),
        FastlaneCore::ConfigItem.new(key: :wait_for_uploaded_build,
                                     env_name: "PILOT_WAIT_FOR_UPLOADED_BUILD",
                                     deprecated: "No longer needed with the transition over to the App Store Connect API",
                                     description: "Use version info from uploaded ipa file to determine what build to use for distribution. If set to false, latest processing or any latest build will be used",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :reject_build_waiting_for_review,
                                     short_option: "-b",
                                     env_name: "PILOT_REJECT_PREVIOUS_BUILD",
                                     description: "Expire previous if it's 'waiting for review'",
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :submit_beta_review,
                                     env_name: "PILOT_DISTRIBUTE_EXTERNAL",
                                     description: "Send the build for a beta review",
                                     type: Boolean,
                                     default_value: true)
      ]
    end
  end
  # rubocop:enable Metrics/ClassLength
  # rubocop:enable Metrics/PerceivedComplexity
end
