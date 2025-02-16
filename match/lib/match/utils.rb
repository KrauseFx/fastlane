require 'fastlane_core/keychain_importer'
require 'openssl'
require_relative 'module'

module Match
  class Utils
    def self.import(item_path, keychain, password: nil, skip_set_partition_list: false)
      keychain_path = FastlaneCore::Helper.keychain_path(keychain)
      FastlaneCore::KeychainImporter.import_file(item_path, keychain_path, keychain_password: password, skip_set_partition_list: skip_set_partition_list, output: FastlaneCore::Globals.verbose?)
    end

    # Fill in an environment variable, ready to be used in _xcodebuild_
    def self.fill_environment(key, value)
      UI.important("Setting environment variable '#{key}' to '#{value}'") if FastlaneCore::Globals.verbose?
      ENV[key] = value
    end

    def self.environment_variable_name(app_identifier: nil, type: nil, platform: :ios)
      base_environment_variable_name(app_identifier: app_identifier, type: type, platform: platform).join("_")
    end

    def self.environment_variable_name_team_id(app_identifier: nil, type: nil, platform: :ios)
      (base_environment_variable_name(app_identifier: app_identifier, type: type, platform: platform) + ["team-id"]).join("_")
    end

    def self.environment_variable_name_profile_name(app_identifier: nil, type: nil, platform: :ios)
      (base_environment_variable_name(app_identifier: app_identifier, type: type, platform: platform) + ["profile-name"]).join("_")
    end

    def self.environment_variable_name_profile_path(app_identifier: nil, type: nil, platform: :ios)
      (base_environment_variable_name(app_identifier: app_identifier, type: type, platform: platform) + ["profile-path"]).join("_")
    end

    def self.environment_variable_name_certificate_name(app_identifier: nil, type: nil, platform: :ios)
      (base_environment_variable_name(app_identifier: app_identifier, type: type, platform: platform) + ["certificate-name"]).join("_")
    end

    def self.get_cert_info(cer_certificate)
      # can receive a certificate path or the file data
      begin
        if File.exist?(cer_certificate)
          cer_certificate = File.binread(cer_certificate)
        end
      rescue ArgumentError
        # cert strings have null bytes; suppressing output
      end

      cert = OpenSSL::X509::Certificate.new(cer_certificate)

      # openssl output:
      # subject= /UID={User ID}/CN={Certificate Name}/OU={Certificate User}/O={Organisation}/C={Country}
      cert_info = cert.subject.to_s.gsub(/\s*subject=\s*/, "").tr("/", "\n")
      out_array = cert_info.split("\n")
      openssl_keys_to_readable_keys = {
           'UID' => 'User ID',
           'CN' => 'Common Name',
           'OU' => 'Organisation Unit',
           'O' => 'Organisation',
           'C' => 'Country',
           'notBefore' => 'Start Datetime',
           'notAfter' => 'End Datetime'
       }

      return out_array.map { |x| x.split(/=+/) if x.include?("=") }
                      .compact
                      .map { |k, v| [openssl_keys_to_readable_keys.fetch(k, k), v] }
                      .push([openssl_keys_to_readable_keys.fetch("notBefore"), cert.not_before])
                      .push([openssl_keys_to_readable_keys.fetch("notAfter"), cert.not_after])
    rescue => ex
      UI.error("get_cert_info: #{ex}")
      return {}
    end

    def self.is_cert_valid?(cer_certificate_path)
      cert = OpenSSL::X509::Certificate.new(File.binread(cer_certificate_path))
      now = Time.now.utc
      return (now <=> cert.not_after) == -1
    end

    def self.base_environment_variable_name(app_identifier: nil, type: nil, platform: :ios)
      if platform.to_s == :ios.to_s
        ["sigh", app_identifier, type] # We keep the ios profiles without the platform for backwards compatibility
      else
        ["sigh", app_identifier, type, platform.to_s]
      end
    end
  end
end
