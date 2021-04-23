require 'fastlane_core/configuration/config_item'
require 'credentials_manager/appfile_config'

module Supply
  class Options
    # rubocop:disable Metrics/PerceivedComplexity
    def self.available_options
      @options ||= [
        FastlaneCore::ConfigItem.new(key: :package_name,
                                     env_name: "SUPPLY_PACKAGE_NAME",
                                     short_option: "-p",
                                     description: "The package name of the application to use",
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:package_name),
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :version_name,
                                     env_name: "SUPPLY_VERSION_NAME",
                                     short_option: "-n",
                                     optional: true,
                                     description: "Version name (used when uploading new apks/aabs) - defaults to 'versionName' in build.gradle or AndroidManifest.xml",
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:version_name),
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :version_code,
                                     env_name: "SUPPLY_VERSION_CODE",
                                     short_option: "-C",
                                     optional: true,
                                     type: Integer,
                                     description: "Version code (used when updating rollout or promoting specific versions)",
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:version_code),
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :release_status,
                                     env_name: "SUPPLY_RELEASE_STATUS",
                                     short_option: "-e",
                                     optional: true,
                                     description: "Release status (used when uploading new apks/aabs) - valid values are #{Supply::ReleaseStatus::ALL.join(', ')}",
                                     default_value: Supply::ReleaseStatus::COMPLETED,
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                                     UI.user_error!("Value must be one of '#{Supply::RELEASE_STATUS}'") unless Supply::ReleaseStatus::ALL.include?(value)
                                                   end),
        FastlaneCore::ConfigItem.new(key: :track,
                                     short_option: "-a",
                                     env_name: "SUPPLY_TRACK",
                                     description: "The track of the application to use. The default available tracks are: #{Supply::Tracks::DEFAULTS.join(', ')}",
                                     default_value: Supply::Tracks::DEFAULT,
                                     type: String,
                                     verify_block: proc do |value|
                                       UI.user_error!("'rollout' is no longer a valid track name - please use 'production' instead") if value.casecmp('rollout').zero?
                                     end),
        FastlaneCore::ConfigItem.new(key: :rollout,
                                     short_option: "-r",
                                     description: "The percentage of the user fraction when uploading to the rollout track (setting to 1 will complete the rollout)",
                                     optional: true,
                                     verify_block: proc do |value|
                                       min = 0.0
                                       max = 1.0
                                       UI.user_error!("Invalid value '#{value}', must be greater than #{min} and less than #{max}") unless value.to_f > min && value.to_f <= max
                                     end),
        FastlaneCore::ConfigItem.new(key: :metadata_path,
                                     env_name: "SUPPLY_METADATA_PATH",
                                     short_option: "-m",
                                     optional: true,
                                     description: "Path to the directory containing the metadata files",
                                     default_value: (Dir["./fastlane/metadata/android"] + Dir["./metadata"]).first,
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :key,
                                     env_name: "SUPPLY_KEY",
                                     short_option: "-k",
                                     conflicting_options: [:json_key],
                                     deprecated: 'Use `--json_key` instead',
                                     description: "The p12 File used to authenticate with Google",
                                     code_gen_sensitive: true,
                                     default_value: Dir["*.p12"].first || CredentialsManager::AppfileConfig.try_fetch_value(:keyfile),
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not find p12 file at path '#{File.expand_path(value)}'") unless File.exist?(File.expand_path(value))
                                     end),
        FastlaneCore::ConfigItem.new(key: :issuer,
                                     env_name: "SUPPLY_ISSUER",
                                     short_option: "-i",
                                     conflicting_options: [:json_key],
                                     deprecated: 'Use `--json_key` instead',
                                     description: "The issuer of the p12 file (email address of the service account)",
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:issuer),
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       UI.important("DEPRECATED --issuer OPTION. Use --json_key instead")
                                     end),
        FastlaneCore::ConfigItem.new(key: :json_key,
                                     env_name: "SUPPLY_JSON_KEY",
                                     short_option: "-j",
                                     conflicting_options: [:issuer, :key, :json_key_data],
                                     optional: true, # this shouldn't be optional but is until --key and --issuer are completely removed
                                     description: "The path to a file containing service account JSON, used to authenticate with Google",
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:json_key_file),
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not find service account json file at path '#{File.expand_path(value)}'") unless File.exist?(File.expand_path(value))
                                       UI.user_error!("'#{value}' doesn't seem to be a JSON file") unless FastlaneCore::Helper.json_file?(File.expand_path(value))
                                     end),
        FastlaneCore::ConfigItem.new(key: :json_key_data,
                                     env_name: "SUPPLY_JSON_KEY_DATA",
                                     short_option: "-c",
                                     conflicting_options: [:issuer, :key, :json_key],
                                     optional: true,
                                     description: "The raw service account JSON data used to authenticate with Google",
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:json_key_data_raw),
                                     default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       begin
                                         JSON.parse(value)
                                       rescue JSON::ParserError
                                         UI.user_error!("Could not parse service account json  JSON::ParseError")
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :apk,
                                     env_name: "SUPPLY_APK",
                                     description: "Path to the APK file to upload",
                                     short_option: "-b",
                                     conflicting_options: [:apk_paths, :aab, :aab_paths],
                                     code_gen_sensitive: true,
                                     default_value: Dir["*.apk"].last || Dir[File.join("app", "build", "outputs", "apk", "app-Release.apk")].last,
                                     default_value_dynamic: true,
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not find apk file at path '#{value}'") unless File.exist?(value)
                                       UI.user_error!("apk file is not an apk") unless value.end_with?('.apk')
                                     end),
        FastlaneCore::ConfigItem.new(key: :apk_paths,
                                     env_name: "SUPPLY_APK_PATHS",
                                     conflicting_options: [:apk, :aab, :aab_paths],
                                     code_gen_sensitive: true,
                                     optional: true,
                                     type: Array,
                                     description: "An array of paths to APK files to upload",
                                     short_option: "-u",
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not evaluate array from '#{value}'") unless value.kind_of?(Array)
                                       value.each do |path|
                                         UI.user_error!("Could not find apk file at path '#{path}'") unless File.exist?(path)
                                         UI.user_error!("file at path '#{path}' is not an apk") unless path.end_with?('.apk')
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :aab,
                                     env_name: "SUPPLY_AAB",
                                     description: "Path to the AAB file to upload",
                                     short_option: "-f",
                                     conflicting_options: [:apk, :apk_paths, :aab_paths],
                                     code_gen_sensitive: true,
                                     default_value: Dir["*.aab"].last || Dir[File.join("app", "build", "outputs", "bundle", "release", "bundle.aab")].last,
                                     default_value_dynamic: true,
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not find aab file at path '#{value}'") unless File.exist?(value)
                                       UI.user_error!("aab file is not an aab") unless value.end_with?('.aab')
                                     end),
        FastlaneCore::ConfigItem.new(key: :aab_paths,
                                     env_name: "SUPPLY_AAB_PATHS",
                                     conflicting_options: [:apk, :apk_paths, :aab],
                                     code_gen_sensitive: true,
                                     optional: true,
                                     type: Array,
                                     description: "An array of paths to AAB files to upload",
                                     short_option: "-z",
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not evaluate array from '#{value}'") unless value.kind_of?(Array)
                                       value.each do |path|
                                         UI.user_error!("Could not find aab file at path '#{path}'") unless File.exist?(path)
                                         UI.user_error!("file at path '#{path}' is not an aab") unless path.end_with?('.aab')
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :skip_upload_apk,
                                     env_name: "SUPPLY_SKIP_UPLOAD_APK",
                                     optional: true,
                                     description: "Whether to skip uploading APK",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_upload_aab,
                                     env_name: "SUPPLY_SKIP_UPLOAD_AAB",
                                     optional: true,
                                     description: "Whether to skip uploading AAB",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_upload_metadata,
                                     env_name: "SUPPLY_SKIP_UPLOAD_METADATA",
                                     optional: true,
                                     description: "Whether to skip uploading metadata, changelogs not included",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_upload_changelogs,
                                     env_name: "SUPPLY_SKIP_UPLOAD_CHANGELOGS",
                                     optional: true,
                                     description: "Whether to skip uploading changelogs",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_upload_images,
                                     env_name: "SUPPLY_SKIP_UPLOAD_IMAGES",
                                     optional: true,
                                     description: "Whether to skip uploading images, screenshots not included",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :skip_upload_screenshots,
                                     env_name: "SUPPLY_SKIP_UPLOAD_SCREENSHOTS",
                                     optional: true,
                                     description: "Whether to skip uploading SCREENSHOTS",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :track_promote_to,
                                     env_name: "SUPPLY_TRACK_PROMOTE_TO",
                                     optional: true,
                                     description: "The track to promote to. The default available tracks are: #{Supply::Tracks::DEFAULTS.join(', ')}",
                                     verify_block: proc do |value|
                                       UI.user_error!("'rollout' is no longer a valid track name - please use 'production' instead") if value.casecmp('rollout').zero?
                                     end),
        FastlaneCore::ConfigItem.new(key: :validate_only,
                                     env_name: "SUPPLY_VALIDATE_ONLY",
                                     optional: true,
                                     description: "Only validate changes with Google Play rather than actually publish",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :mapping,
                                     env_name: "SUPPLY_MAPPING",
                                     description: "Path to the mapping file to upload (mapping.txt or native-debug-symbols.zip alike)",
                                     short_option: "-d",
                                     conflicting_options: [:mapping_paths],
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not find mapping file at path '#{value}'") unless File.exist?(value)
                                     end),
        FastlaneCore::ConfigItem.new(key: :mapping_paths,
                                     env_name: "SUPPLY_MAPPING_PATHS",
                                     conflicting_options: [:mapping],
                                     optional: true,
                                     type: Array,
                                     description: "An array of paths to mapping files to upload (mapping.txt or native-debug-symbols.zip alike)",
                                     short_option: "-s",
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not evaluate array from '#{value}'") unless value.kind_of?(Array)
                                       value.each do |path|
                                         UI.user_error!("Could not find mapping file at path '#{path}'") unless File.exist?(path)
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :root_url,
                                     env_name: "SUPPLY_ROOT_URL",
                                     description: "Root URL for the Google Play API. The provided URL will be used for API calls in place of https://www.googleapis.com/",
                                     optional: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Could not parse URL '#{value}'") unless value =~ URI::DEFAULT_PARSER.make_regexp
                                     end),
        FastlaneCore::ConfigItem.new(key: :check_superseded_tracks,
                                     env_name: "SUPPLY_CHECK_SUPERSEDED_TRACKS",
                                     optional: true,
                                     description: "Check the other tracks for superseded versions and disable them",
                                     deprecated: "Google Play does this automatically now",
                                     type: Boolean,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :timeout,
                                     env_name: "SUPPLY_TIMEOUT",
                                     optional: true,
                                     description: "Timeout for read, open, and send (in seconds)",
                                     type: Integer,
                                     default_value: 300),
        FastlaneCore::ConfigItem.new(key: :deactivate_on_promote,
                                     env_name: "SUPPLY_DEACTIVATE_ON_PROMOTE",
                                     optional: true,
                                     description: "When promoting to a new track, deactivate the binary in the origin track",
                                     deprecated: "Google Play does this automatically now",
                                     type: Boolean,
                                     default_value: true),
        FastlaneCore::ConfigItem.new(key: :version_codes_to_retain,
                                     optional: true,
                                     type: Array,
                                     description: "An array of version codes to retain when publishing a new APK",
                                     verify_block: proc do |version_codes|
                                       version_codes = version_codes.map(&:to_i)
                                       UI.user_error!("Could not evaluate array from '#{version_codes}'") unless version_codes.kind_of?(Array)
                                       version_codes.each do |version_code|
                                         UI.user_error!("Version code '#{version_code}' is not an integer") if version_code == 0
                                       end
                                     end),
        FastlaneCore::ConfigItem.new(key: :in_app_update_priority,
                                     env_name: "SUPPLY_IN_APP_UPDATE_PRIORITY",
                                     optional: true,
                                     type: Integer,
                                     description: "In-app update priority for all the newly added apks in the release. Can take values between [0,5]",
                                     verify_block: proc do |in_app_update_priority|
                                       in_app_update_priority = in_app_update_priority.to_i
                                       UI.user_error!("Invalid in_app_update_priority value '#{in_app_update_priority}'. Values must be between [0,5]") unless (0..5).member?(in_app_update_priority)
                                     end),
        FastlaneCore::ConfigItem.new(key: :obb_main_references_version,
                                     env_name: "SUPPLY_OBB_MAIN_REFERENCES_VERSION",
                                     description: "References version of 'main' expansion file",
                                     optional: true,
                                     type: Numeric),
        FastlaneCore::ConfigItem.new(key: :obb_main_file_size,
                                     env_name: "SUPPLY_OBB_MAIN_FILE SIZE",
                                     description: "Size of 'main' expansion file in bytes",
                                     optional: true,
                                     type: Numeric),
        FastlaneCore::ConfigItem.new(key: :obb_patch_references_version,
                                     env_name: "SUPPLY_OBB_PATCH_REFERENCES_VERSION",
                                     description: "References version of 'patch' expansion file",
                                     optional: true,
                                     type: Numeric),
        FastlaneCore::ConfigItem.new(key: :obb_patch_file_size,
                                     env_name: "SUPPLY_OBB_PATCH_FILE SIZE",
                                     description: "Size of 'patch' expansion file in bytes",
                                     optional: true,
                                     type: Numeric),
        FastlaneCore::ConfigItem.new(key: :ack_bundle_installation_warning,
                                     env_name: "ACK_BUNDLE_INSTALLATION_WARNING",
                                     description: "Must be set to true if the bundle installation may trigger a warning on user devices (e.g can only be downloaded over wifi). Typically this is required for bundles over 150MB",
                                     optional: true,
                                     type: Boolean,
                                     default_value: false)

      ]
    end
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
