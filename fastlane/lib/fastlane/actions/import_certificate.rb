require 'shellwords'

module Fastlane
  module Actions
    class ImportCertificateAction < Action
      def self.run(params)
        if params[:keychain_name]
          keychain_path = File.expand_path(File.join("~", "Library", "Keychains", params[:keychain_name]))
        else
          keychain_path = params[:keychain_path]
        end

        if keychain_path.nil?
          UI.user_error!("You either have to set :keychain_name or :keychain_path")
        end

        FastlaneCore::KeychainImporter.import_file(params[:certificate_path], keychain_path, keychain_password: params[:keychain_password], certificate_password: params[:certificate_password], output: params[:log_output])
      end

      def self.description
        "Import certificate from inputfile into a keychain"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :keychain_name,
                                       env_name: "KEYCHAIN_NAME",
                                       description: "Name of the keychain the items should be imported to",
                                       conflicting_options: [:keychain_path],
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :keychain_path,
                                       env_name: "KEYCHAIN_PATH",
                                       description: "Path to the keychain the items should be imported to",
                                       conflicting_options: [:keychain_name],
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :keychain_password,
                                       env_name: "FL_IMPORT_CERT_KEYCHAIN_PASSWORD",
                                       description: "The password for the keychain. Note that for the login keychain this is your user's password",
                                       sensitive: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :certificate_path,
                                       description: "Path to certificate",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :certificate_password,
                                       description: "Certificate password",
                                       sensitive: true,
                                       default_value: "",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :log_output,
                                       description: "If output should be logged to the console",
                                       type: TrueClass,
                                       default_value: false,
                                       optional: true)
        ]
      end

      def self.authors
        ["gin0606", "koenpunt"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.details
        "Import certificates into the current default keychain. Use `create_keychain` to create a new keychain."
      end

      def self.example_code
        [
          'import_certificate(certificate_path: "certs/AppleWWDRCA.cer")',
          'import_certificate(
            certificate_path: "certs/dist.p12",
            certificate_password: ENV["CERTIFICATE_PASSWORD"] || "default"
          )',
          'import_certificate(
            keychain_path: "/keychains/project.keychain",
            certificate_path: "certs/dist.p12",
            certificate_password: ENV["CERTIFICATE_PASSWORD"] || "default"
          )'
        ]
      end

      def self.category
        :code_signing
      end
    end
  end
end
