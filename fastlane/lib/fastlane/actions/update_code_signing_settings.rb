require 'xcodeproj'
module Fastlane
  module Actions
    class UpdateCodeSigningSettingsAction < Action
      def self.run(params)
        FastlaneCore::PrintTable.print_values(config: params, title: "Summary for code signing settings")
        path = params[:path]
        path = File.join(File.expand_path(path), "project.pbxproj")

        project = Xcodeproj::Project.open(params[:path])
        UI.user_error!("Could not find path to project config '#{path}'. Pass the path to your project (not workspace)!") unless File.exist?(path)
        UI.message("Updating the Automatic Codesigning flag to #{params[:use_automatic_signing] ? 'enabled' : 'disabled'} for the given project '#{path}'")

        if project.isTooOldForFastlaneCodesigning?
          UI.user_error!("Seems to be a very old project file format - please open your project file in a more recent version of Xcode")
          return false
        end

        changed_targets = []
        changed_build_configurations = []

        project.targets.each do |target|
          if params[:targets]
            unless params[:targets].include?(target.name)
              UI.important("Skipping #{target.name} not selected (#{params[:targets].join(',')})")
              next
            end
          end

          target.build_configurations.each do |config|
            if params[:build_configurations]
              unless params[:build_configurations].include?(config.name)
                UI.important("Skipping #{config.name} not selected (#{params[:build_configurations].join(',')})")
                next
              end
            end

            style_value = params[:use_automatic_signing] ? 'Automatic' : 'Manual'
            development_team_setting = params[:sdk] ? "DEVELOPMENT_TEAM[sdk=#{params[:sdk]}]" : "DEVELOPMENT_TEAM"
            code_sign_identity_setting = params[:sdk] ? "CODE_SIGN_IDENTITY[sdk=#{params[:sdk]}]" : "CODE_SIGN_IDENTITY"
            provisioning_profile_setting = params[:sdk] ? "PROVISIONING_PROFILE_SPECIFIER[sdk=#{params[:sdk]}]" : "PROVISIONING_PROFILE_SPECIFIER"

            set_build_setting(config, "CODE_SIGN_STYLE", style_value)

            if params[:team_id]
              set_build_setting(config, development_team_setting, params[:team_id])
              UI.important("Set Team id to: #{params[:team_id]} for target: #{target.name} for build configuration: #{config.name}")
            end
            if params[:code_sign_identity]
              set_build_setting(config, code_sign_identity_setting, params[:code_sign_identity])
              UI.important("Set Code Sign identity to: #{params[:code_sign_identity]} for target: #{target.name} for build configuration: #{config.name}")
            end
            if params[:profile_name]
              set_build_setting(config, provisioning_profile_setting, params[:profile_name])
              UI.important("Set Provisioning Profile name to: #{params[:profile_name]} for target: #{target.name} for build configuration: #{config.name}")
            end
            if params[:entitlements_file_path]
              set_build_setting(config, "CODE_SIGN_ENTITLEMENTS", params[:entitlements_file_path])
              UI.important("Set Entitlements file path to: #{params[:entitlements_file_path]} for target: #{target.name} for build configuration: #{config.name}")
            end
            # Since Xcode 8, this is no longer needed, you simply use PROVISIONING_PROFILE_SPECIFIER
            if params[:profile_uuid]
              set_build_setting(config, "PROVISIONING_PROFILE", params[:profile_uuid])
              UI.important("Set Provisioning Profile UUID to: #{params[:profile_uuid]} for target: #{target.name} for build configuration: #{config.name}")
            end
            if params[:bundle_identifier]
              set_build_setting(config, "PRODUCT_BUNDLE_IDENTIFIER", params[:bundle_identifier])
              UI.important("Set Bundle identifier to: #{params[:bundle_identifier]} for target: #{target.name} for build configuration: #{config.name}")
            end

            changed_build_configurations << config.name
          end

          changed_targets << target.name
        end
        project.save

        if changed_targets.empty?
          UI.important("None of the specified targets has been modified")
          UI.important("available targets:")
          project.targets.each do |target|
            UI.important("\t* #{target.name}")
          end
        else
          UI.success("Successfully updated project settings to use Code Sign Style = '#{params[:use_automatic_signing] ? 'Automatic' : 'Manual'}'")
          UI.success("Modified Targets:")
          changed_targets.each do |target|
            UI.success("\t * #{target}")
          end

          UI.success("Modified Build Configurations:")
          changed_build_configurations.each do |name|
            UI.success("\t * #{name}")
          end
        end

        params[:use_automatic_signing]
      end

      def self.set_build_setting(configuration, name, value)
        # Iterate over any keys that start with this name
        # This will also set keys that have filtering like [sdk=iphoneos*]
        keys = configuration.build_settings.keys.select { |key| key.to_s.match(/#{name}.*/) }
        keys.each do |key|
          configuration.build_settings[key] = value
        end

        # Explicitly set the key with value if keys don't exist
        configuration.build_settings[name] = value
      end

      def self.description
        "Configures Xcode's Codesigning options"
      end

      def self.details
        "Configures Xcode's Codesigning options of all targets in the project"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :path,
                                       env_name: "FL_PROJECT_SIGNING_PROJECT_PATH",
                                       description: "Path to your Xcode project",
                                       code_gen_sensitive: true,
                                       default_value: Dir['*.xcodeproj'].first,
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Path is invalid") unless File.exist?(File.expand_path(value))
                                       end),
          FastlaneCore::ConfigItem.new(key: :use_automatic_signing,
                                       env_name: "FL_PROJECT_USE_AUTOMATIC_SIGNING",
                                       description: "Defines if project should use automatic signing",
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :sdk,
                                       env_name: "FASTLANE_BUILD_SDK",
                                       optional: true,
                                       description: "Build target SDKs (iphoneos*, macosx*, iphonesimulator*)"),
          FastlaneCore::ConfigItem.new(key: :team_id,
                                       env_name: "FASTLANE_TEAM_ID",
                                       optional: true,
                                       description: "Team ID, is used when upgrading project"),
          FastlaneCore::ConfigItem.new(key: :targets,
                                       env_name: "FL_PROJECT_SIGNING_TARGETS",
                                       optional: true,
                                       type: Array,
                                       description: "Specify targets you want to toggle the signing mech. (default to all targets)"),
          FastlaneCore::ConfigItem.new(key: :build_configurations,
                                       env_name: "FL_PROJECT_SIGNING_BUILD_CONFIGURATIONS",
                                       optional: true,
                                       type: Array,
                                       description: "Specify build_configurations you want to toggle the signing mech. (default to all configurations)"),
          FastlaneCore::ConfigItem.new(key: :code_sign_identity,
                                       env_name: "FL_CODE_SIGN_IDENTITY",
                                       description: "Code signing identity type (iPhone Developer, iPhone Distribution)",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :entitlements_file_path,
                                       env_name: "FL_CODE_SIGN_ENTITLEMENTS_FILE_PATH",
                                       description: "Path to your entitlements file",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :profile_name,
                                       env_name: "FL_PROVISIONING_PROFILE_SPECIFIER",
                                       description: "Provisioning profile name to use for code signing",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :profile_uuid,
                                       env_name: "FL_PROVISIONING_PROFILE",
                                       description: "Provisioning profile UUID to use for code signing",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :bundle_identifier,
                                       env_name: "FL_APP_IDENTIFIER",
                                       description: "Application Product Bundle Identifier",
                                       optional: true)
        ]
      end

      def self.output
      end

      def self.example_code
        [
          ' # manual code signing
          update_code_signing_settings(
            use_automatic_signing: false,
            path: "demo-project/demo/demo.xcodeproj"
          )',
          ' # automatic code signing
          update_code_signing_settings(
            use_automatic_signing: true,
            path: "demo-project/demo/demo.xcodeproj"
          )',
          ' # more advanced manual code signing
          update_code_signing_settings(
            use_automatic_signing: false,
            path: "demo-project/demo/demo.xcodeproj",
            team_id: "QABC123DEV",
            bundle_identifier: "com.demoapp.QABC123DEV",
            code_sign_identity: "iPhone Distribution",
            sdk: "iphoneos*",
            profile_name: "Demo App Deployment Profile",
            entitlements_file_path: "Demo App/generated/New.entitlements"
          )'
        ]
      end

      def self.category
        :code_signing
      end

      def self.return_value
        "The current status (boolean) of codesigning after modification"
      end

      def self.authors
        ["mathiasAichinger", "hjanuschka", "p4checo", "portellaa", "aeons", "att55", "abcdev"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end

module Xcodeproj
  class Project
    # we have to have the helper function here
    # otherwise rubocop checking shows too complex function Fastlane.Actions.UpdateCodeSigningSettingsAction.run()
    def isTooOldForFastlaneCodesigning?
      return root_object.attributes["TargetAttributes"].nil? && object_version.to_i < 55
    end
  end
end
