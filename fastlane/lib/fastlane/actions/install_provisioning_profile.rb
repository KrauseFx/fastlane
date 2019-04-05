require 'shellwords'

module Fastlane
  module Actions
    class InstallProvisioningProfileAction < Action
      def self.run(params)
        absolute_path = File.expand_path(params[:provisioning_profile_path])
        FastlaneCore::ProvisioningProfile.install(absolute_path)
      end

      def self.description
        "Install provisioning profile from inputfile"
      end

      def self.details
        "Install provisioning profile from inputfile for current user"
      end

      def self.authors
        ["SofteqDG"]
      end

      def self.category
        :code_signing
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :provisioning_profile_path,
                                  env_name: "FL_INSTALL_PROVISIONING_PROFILE_PATH",
                               description: "Path to provisioning profile",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                absolute_path = File.expand_path(value)
                                unless File.exist?(absolute_path)
                                  UI.user_error!("Failed installation of provisioning profile from file at path: '#{value}'")
                                end
                              end)
        ]
      end

      def self.return_value
        "The absolute path to the installed provisioning profile"
      end

      def self.example_code
        [
          'install_provisioning_profile(provisioning_profile_path: "profiles/profile.mobileprovision")'
        ]
      end
    end
  end
end
