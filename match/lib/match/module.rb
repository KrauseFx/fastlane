require 'spaceship'

require 'fastlane_core/helper'
require 'fastlane/boolean'

module Match
  Helper = FastlaneCore::Helper # you gotta love Ruby: Helper.* should use the Helper class contained in FastlaneCore
  UI = FastlaneCore::UI
  Boolean = Fastlane::Boolean
  ROOT = Pathname.new(File.expand_path('../../..', __FILE__))
  DESCRIPTION = "Easily sync your certificates and profiles across your team"

  def self.environments
    return %w(appstore adhoc development enterprise developer_id mac_installer_distribution developer_id_installer)
  end

  def self.storage_modes
    return %w(git google_cloud s3 gitlab_secure_files)
  end

  def self.profile_type_sym(type)
    return type.to_sym
  end

  def self.cert_type_sym(type)
    # To determine certificate types to fetch from the portal, we use `Sigh.certificate_types_for_profile_and_platform`, and it returns typed `Spaceship::ConnectAPI::Certificate::CertificateType` with the same values but uppercased, so we downcase them here
    type = type.to_s.downcase
    return :mac_installer_distribution if type == "mac_installer_distribution"
    return :developer_id_installer if type == "developer_id_installer"
    return :developer_id_application if type == "developer_id"
    return :enterprise if type == "enterprise"
    return :development if type == "development"
    return :distribution if ["adhoc", "appstore", "distribution"].include?(type)
    raise "Unknown cert type: '#{type}'"
  end

  # Converts provisioning profile type (i.e. development, enterprise) to an array of profile types
  # That can be used for filtering when using Spaceship::ConnectAPI::Profile API
  def self.profile_types(prov_type)
    case prov_type.to_sym
    when :appstore
      return [
        Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_STORE,
        Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_STORE,
        Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_STORE,
        Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_STORE
      ]
    when :development
      return [
        Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_DEVELOPMENT,
        Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_DEVELOPMENT,
        Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_DEVELOPMENT,
        Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_DEVELOPMENT
      ]
    when :enterprise
      profiles = [
        Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_INHOUSE,
        Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_INHOUSE
      ]

      # As of 2022-06-25, only available with Apple ID auth
      if Spaceship::ConnectAPI.token
        UI.important("Skipping #{Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_INHOUSE} and #{Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_INHOUSE}... only available with Apple ID auth")
      else
        profiles += [
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_INHOUSE,
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_INHOUSE
        ]
      end

      return profiles
    when :adhoc
      return [
        Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_ADHOC,
        Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_ADHOC
      ]
    when :developer_id
      return [
        Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_DIRECT,
        Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_DIRECT
      ]
    else
      raise "Unknown provisioning type '#{prov_type}'"
    end
  end

  class << self
    attr_accessor :project
  end
end
