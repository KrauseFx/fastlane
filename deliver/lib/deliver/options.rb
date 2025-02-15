require 'fastlane_core/configuration/config_item'
require 'credentials_manager/appfile_config'

require_relative 'module'

module Deliver
  # rubocop:disable Metrics/ClassLength
  class Options
    def self.available_options
      user = CredentialsManager::AppfileConfig.try_fetch_value(:itunes_connect_id)
      user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)
      user ||= ENV["DELIVER_USER"]

      [
        FastlaneCore::ConfigItem.new(key: :api_key_path,
                                     env_names: ["DELIVER_API_KEY_PATH", "APP_STORE_CONNECT_API_KEY_PATH"],
                                     description: "Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)",
                                     optional: true,
                                     conflicting_options: [:api_key],
                                     verify_block: proc do |value|
                                       UI.user_error!("Couldn't find API key JSON file at path '#{value}'") unless File.exist?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :api_key,
                                     env_names: ["DELIVER_API_KEY", "APP_STORE_CONNECT_API_KEY"],
                                     description: "Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)",
                                     type: Hash,
                                     optional: true,
                                     sensitive: true,
                                     conflicting_options: [:api_key_path]),

        FastlaneCore::ConfigItem.new(key: :username,
                                     short_option: "-u",
                                     env_name: "DELIVER_USERNAME",
                                     description: "Your Apple ID Username",
                                     optional: true,
                                     default_value: user,
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :app_identifier,
                                     short_option: "-a",
                                     env_name: "DELIVER_APP_IDENTIFIER",
                                     description: "The bundle identifier of your app",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier),
                                     default_value_dynamic: true),
        # version
        FastlaneCore::ConfigItem.new(key: :app_version,
                                     short_option: '-z',
                                     env_name: "DELIVER_APP_VERSION",
                                     description: "The version that should be edited or created",
                                     optional: true),

        FastlaneCore::ConfigItem.new(key: :app_version_build,
                                     description: "The build version number (CFBundleVersion)",
                                     optional: true),

        # binary / build
        FastlaneCore::ConfigItem.new(key: :ipa,
                                     short_option: "-i",
                                     optional: true,
                                     env_name: "DELIVER_IPA_PATH",
                                     description: "Path to your ipa file",
                                     code_gen_sensitive: true,
                                     default_value: Dir["*.ipa"].sort_by { |x| File.mtime(x) }.last,
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not find ipa file at path '#{File.expand_path(value)}'") unless File.exist?(value)
                                       UI.user_error!("'#{value}' doesn't seem to be an ipa file") unless value.end_with?(".ipa")
                                     end,
                                     conflicting_options: [:pkg],
                                     conflict_block: proc do |value|
                                       UI.user_error!("You can't use 'ipa' and '#{value.key}' options in one run.")
                                     end),
        FastlaneCore::ConfigItem.new(key: :pkg,
                                     short_option: "-c",
                                     optional: true,
                                     env_name: "DELIVER_PKG_PATH",
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
        FastlaneCore::ConfigItem.new(key: :build_number,
                                     short_option: "-n",
                                     env_name: "DELIVER_BUILD_NUMBER",
                                     description: "If set the given build number (already uploaded to iTC) will be used instead of the current built one",
                                     optional: true,
                                     conflicting_options: [:ipa, :pkg],
                                     conflict_block: proc do |value|
                                       UI.user_error!("You can't use 'build_number' and '#{value.key}' options in one run.")
                                     end),
        FastlaneCore::ConfigItem.new(key: :platform,
                                     short_option: "-j",
                                     env_name: "DELIVER_PLATFORM",
                                     description: "The platform to use (optional)",
                                     optional: true,
                                     default_value: "ios",
                                     verify_block: proc do |value|
                                       UI.user_error!("The platform can only be ios, appletvos/tvos, xros or osx") unless %w(ios appletvos tvos xros osx).include?(value)
                                     end),

        # live version
        FastlaneCore::ConfigItem.new(key: :edit_live,
                                     short_option: "-o",
                                     optional: true,
                                     default_value: false,
                                     env_name: "DELIVER_EDIT_LIVE",
                                     description: "Modify live metadata, this option disables ipa upload and screenshot upload",
                                     type: Boolean),
        FastlaneCore::ConfigItem.new(key: :use_live_version,
                                     env_name: "DELIVER_USE_LIVE_VERSION",
                                     description: "Force usage of live version rather than edit version",
                                     type: Boolean,
                                     default_value: false),

        # paths
        FastlaneCore::ConfigItem.new(key: :metadata_path,
                                     short_option: '-m',
                                     env_name: "DELIVER_METADATA_PATH",
                                     description: "Path to the folder containing the metadata files",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :screenshots_path,
                                     short_option: '-w',
                                     env_name: "DELIVER_SCREENSHOTS_PATH",
                                     description: "Path to the folder containing the screenshots",
                                     optional: true),

        # skip
        FastlaneCore::ConfigItem.new(key: :skip_binary_upload,
                                     env_name: "DELIVER_SKIP_BINARY_UPLOAD",
                                     description: "Skip uploading an ipa or pkg to App Store Connect",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_screenshots,
                                     env_name: "DELIVER_SKIP_SCREENSHOTS",
                                     description: "Don't upload the screenshots",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_metadata,
                                     env_name: "DELIVER_SKIP_METADATA",
                                     description: "Don't upload the metadata (e.g. title, description). This will still upload screenshots",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_app_version_update,
                                     env_name: "DELIVER_SKIP_APP_VERSION_UPDATE",
                                     description: "Don’t create or update the app version that is being prepared for submission",
                                     type: Boolean,
                                     default_value: false),

        # how to operate
        FastlaneCore::ConfigItem.new(key: :force,
                                     short_option: "-f",
                                     env_name: "DELIVER_FORCE",
                                     description: "Skip verification of HTML preview file",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :overwrite_screenshots,
                                     env_name: "DELIVER_OVERWRITE_SCREENSHOTS",
                                     description: "Clear all previously uploaded screenshots before uploading the new ones",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :screenshot_processing_timeout,
                                     env_name: "DELIVER_SCREENSHOT_PROCESSING_TIMEOUT",
                                     description: "Timeout in seconds to wait before considering screenshot processing as failed, used to handle cases where uploads to the App Store are stuck in processing",
                                     type: Integer,
                                     default_value: 3600),
        FastlaneCore::ConfigItem.new(key: :sync_screenshots,
                                     env_name: "DELIVER_SYNC_SCREENSHOTS",
                                     description: "Sync screenshots with local ones. This is currently beta option so set true to 'FASTLANE_ENABLE_BETA_DELIVER_SYNC_SCREENSHOTS' environment variable as well",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :submit_for_review,
                                     env_name: "DELIVER_SUBMIT_FOR_REVIEW",
                                     description: "Submit the new version for Review after uploading everything",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :verify_only,
                                     env_name: "DELIVER_VERIFY_ONLY",
                                     description: "Verifies archive with App Store Connect without uploading",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :reject_if_possible,
                                     env_name: "DELIVER_REJECT_IF_POSSIBLE",
                                     description: "Rejects the previously submitted build if it's in a state where it's possible",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :version_check_wait_retry_limit,
                                     env_name: "DELIVER_VERSION_CHECK_WAIT_RETRY_LIMIT",
                                     description: "After submitting a new version, App Store Connect takes some time to recognize the new version and we must wait until it's available before attempting to upload metadata for it. There is a mechanism that will check if it's available and retry with an exponential backoff if it's not available yet. " \
                                     "This option specifies how many times we should retry before giving up. Setting this to a value below 5 is not recommended and will likely cause failures. Increase this parameter when Apple servers seem to be degraded or slow",
                                     type: Integer,
                                     default_value: 7,
                                     verify_block: proc do |value|
                                       UI.user_error!("'#{value}' needs to be greater than 0") if value <= 0
                                     end),

        # release
        FastlaneCore::ConfigItem.new(key: :automatic_release,
                                     env_name: "DELIVER_AUTOMATIC_RELEASE",
                                     description: "Should the app be automatically released once it's approved? (Cannot be used together with `auto_release_date`)",
                                     type: Boolean,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :auto_release_date,
                                     env_name: "DELIVER_AUTO_RELEASE_DATE",
                                     description: "Date in milliseconds for automatically releasing on pending approval (Cannot be used together with `automatic_release`)",
                                     type: Integer,
                                     optional: true,
                                     conflicting_options: [:automatic_release],
                                     conflict_block: proc do |value|
                                       UI.user_error!("You can't use 'auto_release_date' and '#{value.key}' options together.")
                                     end,
                                     verify_block: proc do |value|
                                       now_in_ms = Time.now.to_i * 1000
                                       if value < now_in_ms
                                         UI.user_error!("'#{value}' needs to be in the future and in milliseconds (current time is '#{now_in_ms}')")
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :phased_release,
                                     env_name: "DELIVER_PHASED_RELEASE",
                                     description: "Enable the phased release feature of iTC",
                                     optional: true,
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :reset_ratings,
                                    env_name: "DELIVER_RESET_RATINGS",
                                    description: "Reset the summary rating when you release a new version of the application",
                                    optional: true,
                                    type: Boolean,
                                    default_value: false),

        # other app configuration
        FastlaneCore::ConfigItem.new(key: :price_tier,
                                     short_option: "-r",
                                     env_name: "DELIVER_PRICE_TIER",
                                     description: "The price tier of this application",
                                     type: Integer,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :app_rating_config_path,
                                     short_option: "-g",
                                     env_name: "DELIVER_APP_RATING_CONFIG_PATH",
                                     description: "Path to the app rating's config",
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not find config file at path '#{File.expand_path(value)}'") unless File.exist?(value)
                                       UI.user_error!("'#{value}' doesn't seem to be a JSON file") unless FastlaneCore::Helper.json_file?(File.expand_path(value))
                                     end),
        FastlaneCore::ConfigItem.new(key: :submission_information,
                                     short_option: "-b",
                                     description: "Extra information for the submission (e.g. compliance specifications)",
                                     type: Hash,
                                     optional: true),

        # affiliation
        FastlaneCore::ConfigItem.new(key: :team_id,
                                     short_option: "-k",
                                     env_name: "DELIVER_TEAM_ID",
                                     description: "The ID of your App Store Connect team if you're in multiple teams",
                                     optional: true,
                                     skip_type_validation: true, # as we also allow integers, which we convert to strings anyway
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_id),
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_ITC_TEAM_ID"] = value.to_s
                                     end),
        FastlaneCore::ConfigItem.new(key: :team_name,
                                     short_option: "-e",
                                     env_name: "DELIVER_TEAM_NAME",
                                     description: "The name of your App Store Connect team if you're in multiple teams",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_name),
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_ITC_TEAM_NAME"] = value.to_s
                                     end),
        FastlaneCore::ConfigItem.new(key: :dev_portal_team_id,
                                     short_option: "-s",
                                     env_name: "DELIVER_DEV_PORTAL_TEAM_ID",
                                     description: "The short ID of your Developer Portal team, if you're in multiple teams. Different from your iTC team ID!",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_id),
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_TEAM_ID"] = value.to_s
                                     end),
        FastlaneCore::ConfigItem.new(key: :dev_portal_team_name,
                                     short_option: "-y",
                                     env_name: "DELIVER_DEV_PORTAL_TEAM_NAME",
                                     description: "The name of your Developer Portal team if you're in multiple teams",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_name),
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       ENV["FASTLANE_TEAM_NAME"] = value.to_s
                                     end),
        # rubocop:disable Layout/LineLength
        FastlaneCore::ConfigItem.new(key: :itc_provider,
                                     env_name: "DELIVER_ITC_PROVIDER",
                                     description: "The provider short name to be used with the iTMSTransporter to identify your team. This value will override the automatically detected provider short name. To get provider short name run `pathToXcode.app/Contents/Applications/Application\\ Loader.app/Contents/itms/bin/iTMSTransporter -m provider -u 'USERNAME' -p 'PASSWORD' -account_type itunes_connect -v off`. The short names of providers should be listed in the second column",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_provider),
                                     default_value_dynamic: true),
        # rubocop:enable Layout/LineLength

        # precheck
        FastlaneCore::ConfigItem.new(key: :run_precheck_before_submit,
                                     short_option: "-x",
                                     env_name: "DELIVER_RUN_PRECHECK_BEFORE_SUBMIT",
                                     description: "Run precheck before submitting to app review",
                                     type: Boolean,
                                     default_value: true),
        FastlaneCore::ConfigItem.new(key: :precheck_default_rule_level,
                                     short_option: "-d",
                                     env_name: "DELIVER_PRECHECK_DEFAULT_RULE_LEVEL",
                                     description: "The default precheck rule level unless otherwise configured",
                                     type: Symbol,
                                     default_value: :warn),

        # App Metadata
        FastlaneCore::ConfigItem.new(key: :individual_metadata_items,
                                     env_names: ["DELIVER_INDIVUDAL_METADATA_ITEMS", "DELIVER_INDIVIDUAL_METADATA_ITEMS"], # The version with typo must be deprecated
                                     description: "An array of localized metadata items to upload individually by language so that errors can be identified. E.g. ['name', 'keywords', 'description']. Note: slow",
                                     deprecated: "Removed after the migration to the new App Store Connect API in June 2020",
                                     type: Array,
                                     optional: true),

        # Non Localised
        FastlaneCore::ConfigItem.new(key: :app_icon,
                                     env_name: "DELIVER_APP_ICON_PATH",
                                     description: "Metadata: The path to the app icon",
                                     deprecated: "Removed after the migration to the new App Store Connect API in June 2020",
                                     optional: true,
                                     short_option: "-l"),
        FastlaneCore::ConfigItem.new(key: :apple_watch_app_icon,
                                     env_name: "DELIVER_APPLE_WATCH_APP_ICON_PATH",
                                     description: "Metadata: The path to the Apple Watch app icon",
                                     deprecated: "Removed after the migration to the new App Store Connect API in June 2020",
                                     optional: true,
                                     short_option: "-q"),
        FastlaneCore::ConfigItem.new(key: :copyright,
                                     env_name: "DELIVER_COPYRIGHT",
                                     description: "Metadata: The copyright notice",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :primary_category,
                                     env_name: "DELIVER_PRIMARY_CATEGORY",
                                     description: "Metadata: The english name of the primary category (e.g. `Business`, `Books`)",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :secondary_category,
                                     env_name: "DELIVER_SECONDARY_CATEGORY",
                                     description: "Metadata: The english name of the secondary category (e.g. `Business`, `Books`)",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :primary_first_sub_category,
                                     env_name: "DELIVER_PRIMARY_FIRST_SUB_CATEGORY",
                                     description: "Metadata: The english name of the primary first sub category (e.g. `Educational`, `Puzzle`)",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :primary_second_sub_category,
                                     env_name: "DELIVER_PRIMARY_SECOND_SUB_CATEGORY",
                                     description: "Metadata: The english name of the primary second sub category (e.g. `Educational`, `Puzzle`)",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :secondary_first_sub_category,
                                     env_name: "DELIVER_SECONDARY_FIRST_SUB_CATEGORY",
                                     description: "Metadata: The english name of the secondary first sub category (e.g. `Educational`, `Puzzle`)",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :secondary_second_sub_category,
                                     env_name: "DELIVER_SECONDARY_SECOND_SUB_CATEGORY",
                                     description: "Metadata: The english name of the secondary second sub category (e.g. `Educational`, `Puzzle`)",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :trade_representative_contact_information,
                                     description: "Metadata: A hash containing the trade representative contact information",
                                     optional: true,
                                     deprecated: "This is no longer used by App Store Connect",
                                     type: Hash),
        FastlaneCore::ConfigItem.new(key: :app_review_information,
                                     description: "Metadata: A hash containing the review information",
                                     optional: true,
                                     type: Hash),
        FastlaneCore::ConfigItem.new(key: :app_review_attachment_file,
                                     env_name: "DELIVER_APP_REVIEW_ATTACHMENT_FILE",
                                     description: "Metadata: Path to the app review attachment file",
                                     optional: true),
        # Localised
        FastlaneCore::ConfigItem.new(key: :description,
                                     description: "Metadata: The localised app description",
                                     optional: true,
                                     type: Hash),
        FastlaneCore::ConfigItem.new(key: :name,
                                     description: "Metadata: The localised app name",
                                     optional: true,
                                     type: Hash),
        FastlaneCore::ConfigItem.new(key: :subtitle,
                                     description: "Metadata: The localised app subtitle",
                                     optional: true,
                                     type: Hash,
                                     verify_block: proc do |value|
                                       UI.user_error!(":subtitle must be a hash, with the language being the key") unless value.kind_of?(Hash)
                                     end),
        FastlaneCore::ConfigItem.new(key: :keywords,
                                     description: "Metadata: An array of localised keywords",
                                     optional: true,
                                     type: Hash,
                                     verify_block: proc do |value|
                                       UI.user_error!(":keywords must be a hash, with the language being the key") unless value.kind_of?(Hash)
                                       value.each do |language, keywords|
                                         # Auto-convert array to string
                                         keywords = keywords.join(", ") if keywords.kind_of?(Array)
                                         value[language] = keywords

                                         UI.user_error!("keywords must be a hash with all values being strings") unless keywords.kind_of?(String)
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :promotional_text,
                                     description: "Metadata: An array of localised promotional texts",
                                     optional: true,
                                     type: Hash,
                                     verify_block: proc do |value|
                                       UI.user_error!(":keywords must be a hash, with the language being the key") unless value.kind_of?(Hash)
                                     end),
        FastlaneCore::ConfigItem.new(key: :release_notes,
                                     description: "Metadata: Localised release notes for this version",
                                     optional: true,
                                     type: Hash),
        FastlaneCore::ConfigItem.new(key: :privacy_url,
                                     description: "Metadata: Localised privacy url",
                                     optional: true,
                                     type: Hash),
        FastlaneCore::ConfigItem.new(key: :apple_tv_privacy_policy,
                                     description: "Metadata: Localised Apple TV privacy policy text",
                                     optional: true,
                                     type: Hash),
        FastlaneCore::ConfigItem.new(key: :support_url,
                                     description: "Metadata: Localised support url",
                                     optional: true,
                                     type: Hash),
        FastlaneCore::ConfigItem.new(key: :marketing_url,
                                     description: "Metadata: Localised marketing url",
                                     optional: true,
                                     type: Hash),
        # The verify_block has been removed from here and verification now happens in Deliver::DetectValues
        # Verification needed Spaceship::Tunes.client which required the Deliver::Runner to already by started
        FastlaneCore::ConfigItem.new(key: :languages,
                                     env_name: "DELIVER_LANGUAGES",
                                     description: "Metadata: List of languages to activate",
                                     type: Array,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :ignore_language_directory_validation,
                                     env_name: "DELIVER_IGNORE_LANGUAGE_DIRECTORY_VALIDATION",
                                     description: "Ignore errors when invalid languages are found in metadata and screenshot directories",
                                     default_value: false,
                                     type: Boolean),
        FastlaneCore::ConfigItem.new(key: :precheck_include_in_app_purchases,
                                     env_name: "PRECHECK_INCLUDE_IN_APP_PURCHASES",
                                     description: "Should precheck check in-app purchases?",
                                     type: Boolean,
                                     optional: true,
                                     default_value: true),

        # internal
        FastlaneCore::ConfigItem.new(key: :app,
                                     short_option: "-p",
                                     env_name: "DELIVER_APP_ID",
                                     description: "The (spaceship) app ID of the app you want to use/modify",
                                     optional: true,
                                     type: Integer)
      ]
    end
  end
  # rubocop:enable Metrics/ClassLength
end
