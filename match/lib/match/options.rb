require 'fastlane_core/configuration/config_item'
require 'fastlane/helper/lane_helper'
require 'credentials_manager/appfile_config'
require_relative 'module'

module Match
  # rubocop:disable Metrics/ClassLength
  class Options
    # This is match specific, as users can append storage specific options
    def self.append_option(option)
      self.available_options # to ensure we created the initial `@available_options` array
      @available_options << option
    end

    def self.default_platform
      case Fastlane::Helper::LaneHelper.current_platform.to_s
      when "mac"
        "macos"
      else
        "ios"
      end
    end

    def self.available_options
      user = CredentialsManager::AppfileConfig.try_fetch_value(:apple_dev_portal_id)
      user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)

      [
        # main
        FastlaneCore::ConfigItem.new(key: :type,
                                     env_name: "MATCH_TYPE",
                                     description: "Define the profile type, can be #{Match.environments.join(', ')}",
                                     short_option: "-y",
                                     default_value: 'development',
                                     verify_block: proc do |value|
                                       unless Match.environments.include?(value)
                                         UI.user_error!("Unsupported environment #{value}, must be in #{Match.environments.join(', ')}")
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :additional_cert_types,
                                     env_name: "MATCH_ADDITIONAL_CERT_TYPES",
                                     description: "Create additional cert types needed for macOS installers (valid values: mac_installer_distribution, developer_id_installer)",
                                     optional: true,
                                     type: Array,
                                     verify_block: proc do |values|
                                       types = %w(mac_installer_distribution developer_id_installer)
                                       UI.user_error!("Unsupported types, must be: #{types}") unless (values - types).empty?
                                     end),
        FastlaneCore::ConfigItem.new(key: :readonly,
                                     env_name: "MATCH_READONLY",
                                     description: "Only fetch existing certificates and profiles, don't generate new ones",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :generate_apple_certs,
                                     env_name: "MATCH_GENERATE_APPLE_CERTS",
                                     description: "Create a certificate type for Xcode 11 and later (Apple Development or Apple Distribution)",
                                     type: Boolean,
                                     default_value: FastlaneCore::Helper.mac? && FastlaneCore::Helper.xcode_at_least?('11'),
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :skip_provisioning_profiles,
                                     env_name: "MATCH_SKIP_PROVISIONING_PROFILES",
                                     description: "Skip syncing provisioning profiles",
                                     type: Boolean,
                                     default_value: false),

        FastlaneCore::ConfigItem.new(key: :app_identifier,
                                     short_option: "-a",
                                     env_name: "MATCH_APP_IDENTIFIER",
                                     description: "The bundle identifier(s) of your app (comma-separated string or array of strings)",
                                     type: Array, # we actually allow String and Array here
                                     skip_type_validation: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier),
                                     default_value_dynamic: true),

        # App Store Connect API
        FastlaneCore::ConfigItem.new(key: :api_key_path,
                                     env_names: ["SIGH_API_KEY_PATH", "APP_STORE_CONNECT_API_KEY_PATH"],
                                     description: "Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)",
                                     optional: true,
                                     conflicting_options: [:api_key],
                                     verify_block: proc do |value|
                                       UI.user_error!("Couldn't find API key JSON file at path '#{value}'") unless File.exist?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :api_key,
                                     env_names: ["SIGH_API_KEY", "APP_STORE_CONNECT_API_KEY"],
                                     description: "Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)",
                                     type: Hash,
                                     optional: true,
                                     sensitive: true,
                                     conflicting_options: [:api_key_path]),

        # Apple ID
        FastlaneCore::ConfigItem.new(key: :username,
                                     short_option: "-u",
                                     env_name: "MATCH_USERNAME",
                                     description: "Your Apple ID Username",
                                     optional: true,
                                     default_value: user,
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :team_id,
                                     short_option: "-b",
                                     env_name: "FASTLANE_TEAM_ID",
                                     description: "The ID of your Developer Portal team if you're in multiple teams",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_id),
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :team_name,
                                     short_option: "-l",
                                     env_name: "FASTLANE_TEAM_NAME",
                                     description: "The name of your Developer Portal team if you're in multiple teams",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_name),
                                     default_value_dynamic: true),

        # Storage
        FastlaneCore::ConfigItem.new(key: :storage_mode,
                                     env_name: "MATCH_STORAGE_MODE",
                                     description: "Define where you want to store your certificates",
                                     short_option: "-q",
                                     default_value: 'git',
                                     verify_block: proc do |value|
                                       unless Match.storage_modes.include?(value)
                                         UI.user_error!("Unsupported storage_mode #{value}, must be in #{Match.storage_modes.join(', ')}")
                                       end
                                     end),

        # Storage: Git
        FastlaneCore::ConfigItem.new(key: :git_url,
                                     env_name: "MATCH_GIT_URL",
                                     description: "URL to the git repo containing all the certificates",
                                     optional: false,
                                     short_option: "-r"),
        FastlaneCore::ConfigItem.new(key: :git_branch,
                                     env_name: "MATCH_GIT_BRANCH",
                                     description: "Specific git branch to use",
                                     default_value: 'master'),
        FastlaneCore::ConfigItem.new(key: :git_full_name,
                                     env_name: "MATCH_GIT_FULL_NAME",
                                     description: "git user full name to commit",
                                     optional: true,
                                     default_value: nil),
        FastlaneCore::ConfigItem.new(key: :git_user_email,
                                     env_name: "MATCH_GIT_USER_EMAIL",
                                     description: "git user email to commit",
                                     optional: true,
                                     default_value: nil),
        FastlaneCore::ConfigItem.new(key: :shallow_clone,
                                     env_name: "MATCH_SHALLOW_CLONE",
                                     description: "Make a shallow clone of the repository (truncate the history to 1 revision)",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :clone_branch_directly,
                                     env_name: "MATCH_CLONE_BRANCH_DIRECTLY",
                                     description: "Clone just the branch specified, instead of the whole repo. This requires that the branch already exists. Otherwise the command will fail",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :git_basic_authorization,
                                     env_name: "MATCH_GIT_BASIC_AUTHORIZATION",
                                     sensitive: true,
                                     description: "Use a basic authorization header to access the git repo (e.g.: access via HTTPS, GitHub Actions, etc), usually a string in Base64",
                                     conflicting_options: [:git_bearer_authorization, :git_private_key],
                                     optional: true,
                                     default_value: nil),
        FastlaneCore::ConfigItem.new(key: :git_bearer_authorization,
                                     env_name: "MATCH_GIT_BEARER_AUTHORIZATION",
                                     sensitive: true,
                                     description: "Use a bearer authorization header to access the git repo (e.g.: access to an Azure DevOps repository), usually a string in Base64",
                                     conflicting_options: [:git_basic_authorization, :git_private_key],
                                     optional: true,
                                     default_value: nil),
        FastlaneCore::ConfigItem.new(key: :git_private_key,
                                     env_name: "MATCH_GIT_PRIVATE_KEY",
                                     sensitive: true,
                                     description: "Use a private key to access the git repo (e.g.: access to GitHub repository via Deploy keys), usually a id_rsa named file or the contents hereof",
                                     conflicting_options: [:git_basic_authorization, :git_bearer_authorization],
                                     optional: true,
                                     default_value: nil),

        # Storage: Google Cloud
        FastlaneCore::ConfigItem.new(key: :google_cloud_bucket_name,
                                     env_name: "MATCH_GOOGLE_CLOUD_BUCKET_NAME",
                                     description: "Name of the Google Cloud Storage bucket to use",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :google_cloud_keys_file,
                                     env_name: "MATCH_GOOGLE_CLOUD_KEYS_FILE",
                                     description: "Path to the gc_keys.json file",
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not find keys file at path '#{File.expand_path(value)}'") unless File.exist?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :google_cloud_project_id,
                                     env_name: "MATCH_GOOGLE_CLOUD_PROJECT_ID",
                                     description: "ID of the Google Cloud project to use for authentication",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :skip_google_cloud_account_confirmation,
                                     env_name: "MATCH_SKIP_GOOGLE_CLOUD_ACCOUNT_CONFIRMATION",
                                     description: "Skips confirming to use the system google account",
                                     type: Boolean,
                                     default_value: false),

        # Storage: S3
        FastlaneCore::ConfigItem.new(key: :s3_region,
                                     env_name: "MATCH_S3_REGION",
                                     description: "Name of the S3 region",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :s3_access_key,
                                     env_name: "MATCH_S3_ACCESS_KEY",
                                     description: "S3 access key",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :s3_secret_access_key,
                                     env_name: "MATCH_S3_SECRET_ACCESS_KEY",
                                     description: "S3 secret access key",
                                     sensitive: true,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :s3_bucket,
                                     env_name: "MATCH_S3_BUCKET",
                                     description: "Name of the S3 bucket",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :s3_object_prefix,
                                     env_name: "MATCH_S3_OBJECT_PREFIX",
                                     description: "Prefix to be used on all objects uploaded to S3",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :s3_skip_encryption,
                                     env_name: "MATCH_S3_SKIP_ENCRYPTION",
                                     description: "Skip encryption of all objects uploaded to S3. WARNING: only enable this on S3 buckets with sufficiently restricted permissions and server-side encryption enabled. See https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html",
                                     type: Boolean,
                                     default_value: false),

        # Storage: GitLab Secure Files
        FastlaneCore::ConfigItem.new(key: :gitlab_project,
                                     env_name: "MATCH_GITLAB_PROJECT",
                                     description: "GitLab Project Path (i.e. 'gitlab-org/gitlab')",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :gitlab_host,
                                      env_name: "MATCH_GITLAB_HOST",
                                      default_value: 'https://gitlab.com',
                                      description: "GitLab Host (i.e. 'https://gitlab.com')",
                                      optional: true),
        FastlaneCore::ConfigItem.new(key: :job_token,
                                      env_name: "CI_JOB_TOKEN",
                                      description: "GitLab CI_JOB_TOKEN",
                                      optional: true),
        FastlaneCore::ConfigItem.new(key: :private_token,
                                      env_name: "PRIVATE_TOKEN",
                                      description: "GitLab Access Token",
                                      optional: true),

        # Keychain
        FastlaneCore::ConfigItem.new(key: :keychain_name,
                                     short_option: "-s",
                                     env_name: "MATCH_KEYCHAIN_NAME",
                                     description: "Keychain the items should be imported to",
                                     default_value: "login.keychain"),
        FastlaneCore::ConfigItem.new(key: :keychain_password,
                                     short_option: "-p",
                                     env_name: "MATCH_KEYCHAIN_PASSWORD",
                                     sensitive: true,
                                     description: "This might be required the first time you access certificates on a new mac. For the login/default keychain this is your macOS account password",
                                     optional: true),

        # settings
        FastlaneCore::ConfigItem.new(key: :force,
                                     env_name: "MATCH_FORCE",
                                     description: "Renew the provisioning profiles every time you run match",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :force_for_new_devices,
                                     env_name: "MATCH_FORCE_FOR_NEW_DEVICES",
                                     description: "Renew the provisioning profiles if the device count on the developer portal has changed. Ignored for profile types 'appstore' and 'developer_id'",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :include_mac_in_profiles,
                                     env_name: "MATCH_INCLUDE_MAC_IN_PROFILES",
                                     description: "Include Apple Silicon Mac devices in provisioning profiles for iOS/iPadOS apps",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :include_all_certificates,
                                     env_name: "MATCH_INCLUDE_ALL_CERTIFICATES",
                                     description: "Include all matching certificates in the provisioning profile. Works only for the 'development' provisioning profile type",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :certificate_id,
                                     env_name: "MATCH_CERTIFICATE_ID",
                                     description: "Select certificate by id. Useful if multiple certificates are stored in one place",
                                     type: String,
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :force_for_new_certificates,
                                     env_name:  "MATCH_FORCE_FOR_NEW_CERTIFICATES",
                                     description: "Renew the provisioning profiles if the certificate count on the developer portal has changed. Works only for the 'development' provisioning profile type. Requires 'include_all_certificates' option to be 'true'",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_confirmation,
                                     env_name: "MATCH_SKIP_CONFIRMATION",
                                     description: "Disables confirmation prompts during nuke, answering them with yes",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :force_nuke_dist_certs,
                                     env_name: "MATCH_FORCE_NUKE_DIST_CERTS",
                                     description: "Force nuke distribution and enterprise in-house certs. This will cause apps built with these certs to stop working",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :safe_remove_certs,
                                     env_name: "MATCH_SAFE_REMOVE_CERTS",
                                     description: "Remove certs from repository during nuke without revoking them on the developer portal",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_docs,
                                     env_name: "MATCH_SKIP_DOCS",
                                     description: "Skip generation of a README.md for the created git repository",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :platform,
                                     short_option: '-o',
                                     env_name: "MATCH_PLATFORM",
                                     description: "Set the provisioning profile's platform to work with (i.e. ios, tvos, macos, catalyst)",
                                     default_value: default_platform,
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       value = value.to_s
                                       pt = %w(tvos ios macos catalyst)
                                       UI.user_error!("Unsupported platform, must be: #{pt}") unless pt.include?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :derive_catalyst_app_identifier,
                                     env_name: "MATCH_DERIVE_CATALYST_APP_IDENTIFIER",
                                     description: "Enable this if you have the Mac Catalyst capability enabled and your project was created with Xcode 11.3 or earlier. Prepends 'maccatalyst.' to the app identifier for the provisioning profile mapping",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :template_name,
                                     env_name: "MATCH_PROVISIONING_PROFILE_TEMPLATE_NAME",
                                     description: "The name of provisioning profile template. If the developer account has provisioning profile templates (aka: custom entitlements), the template name can be found by inspecting the Entitlements drop-down while creating/editing a provisioning profile (e.g. \"Apple Pay Pass Suppression Development\")",
                                     optional: true,
                                     default_value: nil),
        FastlaneCore::ConfigItem.new(key: :profile_name,
                                    env_name: "MATCH_PROVISIONING_PROFILE_NAME",
                                    description: "A custom name for the provisioning profile. This will replace the default provisioning profile name if specified",
                                    optional: true,
                                    default_value: nil),
        FastlaneCore::ConfigItem.new(key: :fail_on_name_taken,
                                     env_name: "MATCH_FAIL_ON_NAME_TAKEN",
                                     description: "Should the command fail if it was about to create a duplicate of an existing provisioning profile. It can happen due to issues on Apple Developer Portal, when profile to be recreated was not properly deleted first",
                                     optional: true,
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_certificate_matching,
                                     env_name: "MATCH_SKIP_CERTIFICATE_MATCHING",
                                     description: "Set to true if there is no access to Apple developer portal but there are certificates, keys and profiles provided. Only works with match import action",
                                     optional: true,
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :output_path,
                                     env_name: "MATCH_OUTPUT_PATH",
                                     description: "Path in which to export certificates, key and profile",
                                     optional: true),
        FastlaneCore::ConfigItem.new(key: :skip_set_partition_list,
                                     short_option: "-P",
                                     env_name: "MATCH_SKIP_SET_PARTITION_LIST",
                                     description: "Skips setting the partition list (which can sometimes take a long time). Setting the partition list is usually needed to prevent Xcode from prompting to allow a cert to be used for signing",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :force_legacy_encryption,
                                     env_name: "MATCH_FORCE_LEGACY_ENCRYPTION",
                                     description: "Force encryption to use legacy cbc algorithm for backwards compatibility with older match versions",
                                     type: Boolean,
                                     default_value: false),

        # other
        FastlaneCore::ConfigItem.new(key: :verbose,
                                     env_name: "MATCH_VERBOSE",
                                     description: "Print out extra information and all commands",
                                     type: Boolean,
                                     default_value: false,
                                     verify_block: proc do |value|
                                       FastlaneCore::Globals.verbose = true if value
                                     end)
      ]
    end
  end
  # rubocop:enable Metrics/ClassLength
end
