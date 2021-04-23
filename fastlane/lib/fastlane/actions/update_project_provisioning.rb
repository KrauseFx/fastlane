module Fastlane
  module Actions
    module SharedValues
    end

    class UpdateProjectProvisioningAction < Action
      ROOT_CERTIFICATE_URL = "https://www.apple.com/appleca/AppleIncRootCertificate.cer"
      def self.run(params)
        UI.message("You’re updating provisioning profiles directly in your project, but have you considered easier ways to do code signing?")
        UI.message("https://docs.fastlane.tools/codesigning/GettingStarted/")

        # assign folder from parameter or search for xcodeproj file
        folder = params[:xcodeproj] || Dir["*.xcodeproj"].first

        # validate folder
        project_file_path = File.join(folder, "project.pbxproj")
        UI.user_error!("Could not find path to project config '#{project_file_path}'. Pass the path to your project (not workspace)!") unless File.exist?(project_file_path)

        # download certificate
        unless File.exist?(params[:certificate])
          UI.message("Downloading root certificate from (#{ROOT_CERTIFICATE_URL}) to path '#{params[:certificate]}'")
          File.open(params[:certificate], "w:ASCII-8BIT") do |file|
            file.write(FastlaneCore::Helper.open_uri(ROOT_CERTIFICATE_URL, "rb").read)
          end
        end

        # parsing mobileprovision file
        UI.message("Parsing mobile provisioning profile from '#{params[:profile]}'")
        profile = File.read(params[:profile])
        p7 = OpenSSL::PKCS7.new(profile)
        store = OpenSSL::X509::Store.new
        UI.user_error!("Could not find valid certificate at '#{params[:certificate]}'") unless File.size(params[:certificate]) > 0
        cert = OpenSSL::X509::Certificate.new(File.read(params[:certificate]))
        store.add_cert(cert)
        p7.verify([cert], store)
        data = Plist.parse_xml(p7.data)

        target_filter = params[:target_filter] || params[:build_configuration_filter]
        configuration = params[:build_configuration]
        code_signing_identity = params[:code_signing_identity]

        # manipulate project file
        UI.success("Going to update project '#{folder}' with UUID")
        require 'xcodeproj'

        project = Xcodeproj::Project.open(folder)
        project.targets.each do |target|
          if !target_filter || target.name.match(target_filter) || (target.respond_to?(:product_type) && target.product_type.match(target_filter))
            UI.success("Updating target #{target.name}...")
          else
            UI.important("Skipping target #{target.name} as it doesn't match the filter '#{target_filter}'")
            next
          end

          target.build_configuration_list.build_configurations.each do |build_configuration|
            config_name = build_configuration.name
            if !configuration || config_name.match(configuration)
              UI.success("Updating configuration #{config_name}...")
            else
              UI.important("Skipping configuration #{config_name} as it doesn't match the filter '#{configuration}'")
              next
            end

            if code_signing_identity
              codesign_build_settings_keys = build_configuration.build_settings.keys.select { |key| key.to_s.match(/CODE_SIGN_IDENTITY.*/) }
              codesign_build_settings_keys.each do |setting|
                build_configuration.build_settings[setting] = code_signing_identity
              end
            end

            build_configuration.build_settings["PROVISIONING_PROFILE"] = data["UUID"]
            build_configuration.build_settings["PROVISIONING_PROFILE_SPECIFIER"] = data["Name"]
          end
        end

        project.save

        # complete
        UI.success("Successfully updated project settings in '#{folder}'")
      end

      def self.description
        "Update projects code signing settings from your provisioning profile"
      end

      def self.details
        [
          "You should check out the [code signing guide](https://docs.fastlane.tools/codesigning/getting-started/) before using this action.",
          "This action retrieves a provisioning profile UUID from a provisioning profile (`.mobileprovision`) to set up the Xcode projects' code signing settings in `*.xcodeproj/project.pbxproj`.",
          "The `:target_filter` value can be used to only update code signing for the specified targets.",
          "The `:build_configuration` value can be used to only update code signing for the specified build configurations of the targets passing through the `:target_filter`.",
          "Example usage is the WatchKit Extension or WatchKit App, where you need separate provisioning profiles.",
          "Example: `update_project_provisioning(xcodeproj: \"..\", target_filter: \".*WatchKit App.*\")`."
        ].join("\n")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                                       env_name: "FL_PROJECT_PROVISIONING_PROJECT_PATH",
                                       description: "Path to your Xcode project",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Path to xcode project is invalid") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :profile,
                                       env_name: "FL_PROJECT_PROVISIONING_PROFILE_FILE",
                                       description: "Path to provisioning profile (.mobileprovision)",
                                       default_value: Actions.lane_context[SharedValues::SIGH_PROFILE_PATH],
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Path to provisioning profile is invalid") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :target_filter,
                                       env_name: "FL_PROJECT_PROVISIONING_PROFILE_TARGET_FILTER",
                                       description: "A filter for the target name. Use a standard regex",
                                       optional: true,
                                       is_string: false,
                                       verify_block: proc do |value|
                                         UI.user_error!("target_filter should be Regexp or String") unless [Regexp, String].any? { |type| value.kind_of?(type) }
                                       end),
          FastlaneCore::ConfigItem.new(key: :build_configuration_filter,
                                       env_name: "FL_PROJECT_PROVISIONING_PROFILE_FILTER",
                                       description: "Legacy option, use 'target_filter' instead",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :build_configuration,
                                       env_name: "FL_PROJECT_PROVISIONING_PROFILE_BUILD_CONFIGURATION",
                                       description: "A filter for the build configuration name. Use a standard regex. Applied to all configurations if not specified",
                                       optional: true,
                                       is_string: false,
                                       verify_block: proc do |value|
                                         UI.user_error!("build_configuration should be Regexp or String") unless [Regexp, String].any? { |type| value.kind_of?(type) }
                                       end),
          FastlaneCore::ConfigItem.new(key: :certificate,
                                       env_name: "FL_PROJECT_PROVISIONING_CERTIFICATE_PATH",
                                       description: "Path to apple root certificate",
                                       default_value: "/tmp/AppleIncRootCertificate.cer"),
          FastlaneCore::ConfigItem.new(key: :code_signing_identity,
                                       env_name: "FL_PROJECT_PROVISIONING_CODE_SIGN_IDENTITY",
                                       description: "Code sign identity for build configuration",
                                       optional: true)
        ]
      end

      def self.authors
        ["tobiasstrebitzer", "czechboy0"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.example_code
        [
          'update_project_provisioning(
            xcodeproj: "Project.xcodeproj",
            profile: "./watch_app_store.mobileprovision", # optional if you use sigh
            target_filter: ".*WatchKit Extension.*", # matches name or type of a target
            build_configuration: "Release",
            code_signing_identity: "iPhone Development" # optionally specify the codesigning identity
          )'
        ]
      end

      def self.category
        :code_signing
      end
    end
  end
end
