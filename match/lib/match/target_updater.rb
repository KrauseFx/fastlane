require_relative 'module'
require 'xcodeproj'
require 'fastlane_core/project'

module Match
  class TargetUpdater
    INFOPLIST_FILE_KEY = "INFOPLIST_FILE"
    BUNDLE_ID_KEY = "CFBundleIdentifier"
    PRODUCT_BUNDLE_ID_KEY = "PRODUCT_BUNDLE_IDENTIFIER"
    CODE_SIGN_STYLE_KEY = "CODE_SIGN_STYLE"
    CODE_SIGN_STYLE_VALUE = "Manual"
    CODE_SIGN_IDENTITY_KEY = "CODE_SIGN_IDENTITY"
    TEAM_ID_KEY = "DEVELOPMENT_TEAM"
    PROFILE_NAME_KEY = "PROVISIONING_PROFILE_SPECIFIER"

    def self.update_signing(app_identifier, profile_name, team_id, certificate_name)
      all_xcode_projects.each do |project|
        should_save = false
        project.targets.each do |target|
          target.build_configurations.each do |config|
            unless app_identifier == get_bundle_id(config)
              next
            end
            UI.verbose("Found #{app_identifier} in configuration #{config.name} for target #{target.name}")

            set_build_setting(config, CODE_SIGN_STYLE_KEY, CODE_SIGN_STYLE_VALUE)
            UI.verbose("Set Code Sign Style to: Manual for target: #{target.name} for build configuration: #{config.name}")

            set_build_setting(config, CODE_SIGN_IDENTITY_KEY, certificate_name)
            UI.verbose("Set Code Sign Identity to: #{certificate_name} for target: #{target.name} for build configuration: #{config.name}")

            set_build_setting(config, TEAM_ID_KEY, team_id)
            UI.verbose("Set Team ID to: #{team_id} for target: #{target.name} for build configuration: #{config.name}")

            set_build_setting(config, PROFILE_NAME_KEY, profile_name)
            UI.verbose("Set Provisioning Profile Name to: #{profile_name} for target: #{target.name} for build configuration: #{config.name}")

            UI.important("Updated code signing values for target: #{target.name} for build configuration: #{config.name}")

            should_save = true
          end
        end
        if should_save
          project.save
        end
      end
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

    def self.get_bundle_id(build_configuration)
      infoplist_path = build_configuration.build_settings[INFOPLIST_FILE_KEY]
      unless infoplist_path
        return nil
      end

      infoplist_path = "#{File.dirname(Match.project.path)}/#{infoplist_path}"
      unless File.exist?(infoplist_path)
        return nil
      end

      plist_data = Xcodeproj::Plist.read_from_path(infoplist_path)
      bundle_id = plist_data[BUNDLE_ID_KEY]

      # bundle_id from info plist might just be $(PRODUCT_BUNDLE_IDENTIFIER).
      # If this is the case, check the value in build_settings
      if bundle_id&.include?(PRODUCT_BUNDLE_ID_KEY)
        bundle_id = build_configuration.build_settings[PRODUCT_BUNDLE_ID_KEY]
      end

      return bundle_id
    end

    def self.all_xcode_projects
      project = Match.project
      if project.workspace?
        workspace = project.workspace
        return workspace.schemes
                        .values.uniq.reject { |v| v.include?("Pods/Pods.xcodeproj") }
                        .map { |path| Xcodeproj::Project.open(path) }
      else
        return [project.project]
      end
    end
  end
end
