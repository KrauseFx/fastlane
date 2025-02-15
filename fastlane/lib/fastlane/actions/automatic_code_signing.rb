require 'xcodeproj'
module Fastlane
  module Actions
    class AutomaticCodeSigningAction < Action
      def self.run(params)
        UI.deprecated("The `automatic_code_signing` action has been deprecated,")
        UI.deprecated("Please use `update_code_signing_settings` action instead.")
        FastlaneCore::PrintTable.print_values(config: params, title: "Summary for Automatic Codesigning")
        path = params[:path]
        path = File.join(File.expand_path(path), "project.pbxproj")

        project = Xcodeproj::Project.open(params[:path])
        UI.user_error!("Could not find path to project config '#{path}'. Pass the path to your project (not workspace)!") unless File.exist?(path)
        UI.message("Updating the Automatic Codesigning flag to #{params[:use_automatic_signing] ? 'enabled' : 'disabled'} for the given project '#{path}'")

        if project.root_object.attributes["TargetAttributes"].nil? && project.object_version.to_i < 55
          UI.user_error!("Seems to be a very old project file format - please open your project file in a more recent version of Xcode")
          return false
        end

        target_dictionary = project.targets.map { |f| { name: f.name, uuid: f.uuid, build_configuration_list: f.build_configuration_list } }
        target_attributes = project.root_object.attributes["TargetAttributes"]
        changed_targets = []

        # make sure TargetAttributes exist for all targets
        target_dictionary.each do |props|
          unless target_attributes.key?(props[:uuid])
            target_attributes[props[:uuid]] = {}
          end
        end

        target_attributes.each do |target, sett|
          found_target = target_dictionary.detect { |h| h[:uuid] == target }
          if params[:targets]
            # get target name
            unless params[:targets].include?(found_target[:name])
              UI.important("Skipping #{found_target[:name]} not selected (#{params[:targets].join(',')})")
              next
            end
          end

          style_value = params[:use_automatic_signing] ? 'Automatic' : 'Manual'
          build_configuration_list = found_target[:build_configuration_list]
          build_configuration_list.set_setting("CODE_SIGN_STYLE", style_value)
          sett["ProvisioningStyle"] = style_value

          if params[:team_id]
            sett["DevelopmentTeam"] = params[:team_id]
            build_configuration_list.set_setting("DEVELOPMENT_TEAM", params[:team_id])
            UI.important("Set Team id to: #{params[:team_id]} for target: #{found_target[:name]}")
          end
          if params[:code_sign_identity]
            build_configuration_list.set_setting("CODE_SIGN_IDENTITY", params[:code_sign_identity])

            # We also need to update the value if it was overridden for a specific SDK
            build_configuration_list.build_configurations.each do |build_configuration|
              codesign_build_settings_keys = build_configuration.build_settings.keys.select { |key| key.to_s.match(/CODE_SIGN_IDENTITY.*/) }
              codesign_build_settings_keys.each do |setting|
                build_configuration_list.set_setting(setting, params[:code_sign_identity])
              end
            end
            UI.important("Set Code Sign identity to: #{params[:code_sign_identity]} for target: #{found_target[:name]}")
          end
          if params[:profile_name]
            build_configuration_list.set_setting("PROVISIONING_PROFILE_SPECIFIER", params[:profile_name])
            UI.important("Set Provisioning Profile name to: #{params[:profile_name]} for target: #{found_target[:name]}")
          end
          # Since Xcode 8, this is no longer needed, you simply use PROVISIONING_PROFILE_SPECIFIER
          if params[:profile_uuid]
            build_configuration_list.set_setting("PROVISIONING_PROFILE", params[:profile_uuid])
            UI.important("Set Provisioning Profile UUID to: #{params[:profile_uuid]} for target: #{found_target[:name]}")
          end
          if params[:bundle_identifier]
            build_configuration_list.set_setting("PRODUCT_BUNDLE_IDENTIFIER", params[:bundle_identifier])
            UI.important("Set Bundle identifier to: #{params[:bundle_identifier]} for target: #{found_target[:name]}")
          end

          changed_targets << found_target[:name]
        end
        project.save

        if changed_targets.empty?
          UI.important("None of the specified targets has been modified")
          UI.important("available targets:")
          target_dictionary.each do |target|
            UI.important("\t* #{target[:name]}")
          end
        else
          UI.success("Successfully updated project settings to use Code Sign Style = '#{params[:use_automatic_signing] ? 'Automatic' : 'Manual'}'")
          UI.success("Modified Targets:")
          changed_targets.each do |target|
            UI.success("\t * #{target}")
          end
        end

        params[:use_automatic_signing]
      end

      def self.alias_used(action_alias, params)
        params[:use_automatic_signing] = true if action_alias == "enable_automatic_code_signing"
      end

      def self.aliases
        ["enable_automatic_code_signing", "disable_automatic_code_signing"]
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
          FastlaneCore::ConfigItem.new(key: :team_id,
                                       env_name: "FASTLANE_TEAM_ID",
                                       optional: true,
                                       description: "Team ID, is used when upgrading project"),
          FastlaneCore::ConfigItem.new(key: :targets,
                                       env_name: "FL_PROJECT_SIGNING_TARGETS",
                                       optional: true,
                                       type: Array,
                                       description: "Specify targets you want to toggle the signing mech. (default to all targets)"),
          FastlaneCore::ConfigItem.new(key: :code_sign_identity,
                                       env_name: "FL_CODE_SIGN_IDENTITY",
                                       description: "Code signing identity type (iPhone Developer, iPhone Distribution)",
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
          '# enable automatic code signing
          enable_automatic_code_signing',
          'enable_automatic_code_signing(
            path: "demo-project/demo/demo.xcodeproj"
          )',
          '# disable automatic code signing
          disable_automatic_code_signing',
          'disable_automatic_code_signing(
            path: "demo-project/demo/demo.xcodeproj"
          )',
          '# also set team id
          disable_automatic_code_signing(
            path: "demo-project/demo/demo.xcodeproj",
            team_id: "XXXX"
          )',
          '# Only specific targets
          disable_automatic_code_signing(
            path: "demo-project/demo/demo.xcodeproj",
            use_automatic_signing: false,
            targets: ["demo"]
          )
          ',
          ' # via generic action
          automatic_code_signing(
            path: "demo-project/demo/demo.xcodeproj",
            use_automatic_signing: false
          )',
          'automatic_code_signing(
            path: "demo-project/demo/demo.xcodeproj",
            use_automatic_signing: true
          )'

        ]
      end

      def self.category
        :deprecated
      end

      def self.deprecated_notes
        "Please use `update_code_signing_settings` action instead."
      end

      def self.return_value
        "The current status (boolean) of codesigning after modification"
      end

      def self.authors
        ["mathiasAichinger", "hjanuschka", "p4checo", "portellaa", "aeons"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
