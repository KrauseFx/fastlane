module Fastlane
  module Actions
    # Resigns the ipa
    class ResignAction < Action
      def self.run(params)
        require 'sigh'

        # try to resign the ipa
        if Sigh::Resign.resign(params[:ipa], params[:signing_identity], params[:provisioning_profile], params[:entitlements], params[:version], params[:display_name], params[:short_version], params[:bundle_version], params[:bundle_id], params[:appclip_bundle_id], params[:use_app_entitlements], params[:keychain_path])
          UI.success('Successfully re-signed .ipa 🔏.')
        else
          UI.user_error!("Failed to re-sign .ipa")
        end
      end

      def self.description
        "Codesign an existing ipa file"
      end

      def self.example_code
        [
          'resign(
            ipa: "path/to/ipa", # can omit if using the `ipa` action
            signing_identity: "iPhone Distribution: Luka Mirosevic (0123456789)",
            provisioning_profile: "path/to/profile", # can omit if using the _sigh_ action
          )',
          '# You may provide multiple provisioning profiles if the application contains nested
          # applications or app extensions, which need their own provisioning profile.
          # You can do so by passing an array of provisioning profile strings or a hash
          # that associates provisioning profile values to bundle identifier keys.
          resign(
            ipa: "path/to/ipa", # can omit if using the `ipa` action
            signing_identity: "iPhone Distribution: Luka Mirosevic (0123456789)",
            provisioning_profile: {
              "com.example.awesome-app" => "path/to/profile",
              "com.example.awesome-app.app-extension" => "path/to/app-extension/profile"
            }
          )'
        ]
      end

      def self.category
        :code_signing
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :ipa,
                                       env_name: "FL_RESIGN_IPA",
                                       description: "Path to the ipa file to resign. Optional if you use the _gym_ or _xcodebuild_ action",
                                       default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find ipa file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :signing_identity,
                                       env_name: "FL_RESIGN_SIGNING_IDENTITY",
                                       description: "Code signing identity to use. e.g. `iPhone Distribution: Luka Mirosevic (0123456789)`"),
          FastlaneCore::ConfigItem.new(key: :entitlements,
                                       env_name: "FL_RESIGN_ENTITLEMENTS",
                                       description: "Path to the entitlement file to use, e.g. `myApp/MyApp.entitlements`",
                                       conflicting_options: [:use_app_entitlements],
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :provisioning_profile,
                                       env_name: "FL_RESIGN_PROVISIONING_PROFILE",
                                       description: "Path to your provisioning_profile. Optional if you use _sigh_",
                                       default_value: Actions.lane_context[SharedValues::SIGH_PROFILE_PATH],
                                       default_value_dynamic: true,
                                       skip_type_validation: true, # allows Hash, Array
                                       verify_block: proc do |value|
                                         files = case value
                                                 when Hash then value.values
                                                 when Enumerable then value
                                                 else [value]
                                                 end
                                         files.each do |file|
                                           UI.user_error!("Couldn't find provisioning profile at path '#{file}'") unless File.exist?(file)
                                         end
                                       end),
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: "FL_RESIGN_VERSION",
                                       description: "Version number to force resigned ipa to use. Updates both `CFBundleShortVersionString` and `CFBundleVersion` values in `Info.plist`. Applies for main app and all nested apps or extensions",
                                       conflicting_options: [:short_version, :bundle_version],
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :display_name,
                                       env_name: "FL_DISPLAY_NAME",
                                       description: "Display name to force resigned ipa to use",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :short_version,
                                       env_name: "FL_RESIGN_SHORT_VERSION",
                                       description: "Short version string to force resigned ipa to use (`CFBundleShortVersionString`)",
                                       conflicting_options: [:version],
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :bundle_version,
                                       env_name: "FL_RESIGN_BUNDLE_VERSION",
                                       description: "Bundle version to force resigned ipa to use (`CFBundleVersion`)",
                                       conflicting_options: [:version],
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :bundle_id,
                                       env_name: "FL_RESIGN_BUNDLE_ID",
                                       description: "Set new bundle ID during resign (`CFBundleIdentifier`)",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :appclip_bundle_id,
                                       env_name: "FL_RESIGN_APPCLIP_BUNDLE_ID",
                                       description: "Set new AppClip bundle ID during resign (`CFBundleIdentifier`)",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :use_app_entitlements,
                                       env_name: "FL_USE_APP_ENTITLEMENTS",
                                       description: "Extract app bundle codesigning entitlements and combine with entitlements from new provisioning profile",
                                       conflicting_options: [:entitlements],
                                       type: Boolean,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :keychain_path,
                                       env_name: "FL_RESIGN_KEYCHAIN_PATH",
                                       description: "Provide a path to a keychain file that should be used by `/usr/bin/codesign`",
                                       optional: true)
        ]
      end

      def self.author
        "lmirosevic"
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
