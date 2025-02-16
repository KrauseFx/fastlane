require 'spaceship'

require 'base64'

require_relative 'manager'
require_relative 'module'

module Sigh
  class DownloadAll
    # Download all valid provisioning profiles
    def download_all(download_xcode_profiles: false)
      if (api_token = Spaceship::ConnectAPI::Token.from(hash: Sigh.config[:api_key], filepath: Sigh.config[:api_key_path]))
        UI.message("Creating authorization token for App Store Connect API")
        Spaceship::ConnectAPI.token = api_token
      elsif !Spaceship::ConnectAPI.token.nil?
        UI.message("Using existing authorization token for App Store Connect API")
      else
        # Team selection passed though FASTLANE_ITC_TEAM_ID and FASTLANE_ITC_TEAM_NAME environment variables
        # Prompts select team if multiple teams and none specified
        UI.message("Starting login with user '#{Sigh.config[:username]}'")
        Spaceship::ConnectAPI.login(Sigh.config[:username], nil, use_portal: true, use_tunes: false)
        UI.message("Successfully logged in")
      end

      if download_xcode_profiles
        UI.deprecated("The App Store Connect API does not support querying for Xcode managed profiles: --download_code_profiles is deprecated")
      end

      case Sigh.config[:platform].to_s
      when 'ios'
        profile_types = [
          Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_STORE,
          Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_INHOUSE,
          Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_ADHOC,
          Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_DEVELOPMENT
        ]
      when 'macos'
        profile_types = [
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_STORE,
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_DEVELOPMENT,
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_DIRECT
        ]

        # As of 2022-06-25, only available with Apple ID auth
        if Spaceship::ConnectAPI.token
          UI.important("Skipping #{Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_INHOUSE}... only available with Apple ID auth")
        else
          profile_types << Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_INHOUSE
        end
      when 'catalyst'
        profile_types = [
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_STORE,
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_DEVELOPMENT,
          Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_DIRECT
        ]

        # As of 2022-06-25, only available with Apple ID auth
        if Spaceship::ConnectAPI.token
          UI.important("Skipping #{Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_INHOUSE}... only available with Apple ID auth")
        else
          profile_types << Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_INHOUSE
        end
      when 'tvos'
        profile_types = [
          Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_STORE,
          Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_INHOUSE,
          Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_ADHOC,
          Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_DEVELOPMENT
        ]
      end

      profiles = Spaceship::ConnectAPI::Profile.all(filter: { profileType: profile_types.join(",") }, includes: "bundleId")
      download_profiles(profiles)
    end

    # @param profiles [Array] Array of all the provisioning profiles we want to download
    def download_profiles(profiles)
      UI.important("No profiles available for download") if profiles.empty?

      profiles.each do |profile|
        if profile.valid?
          UI.message("Downloading profile '#{profile.name}'...")
          download_profile(profile)
        else
          UI.important("Skipping invalid/expired profile '#{profile.name}'")
        end
      end
    end

    def pretty_type(profile_type)
      return Sigh.profile_pretty_type(profile_type)
    end

    # @param profile [ProvisioningProfile] A profile we plan to download and store
    def download_profile(profile)
      FileUtils.mkdir_p(Sigh.config[:output_path])

      type_name = pretty_type(profile.profile_type)
      profile_name = "#{type_name}_#{profile.uuid}_#{profile.bundle_id.identifier}"

      if Sigh.config[:platform].to_s == 'tvos'
        profile_name += "_tvos"
      end

      if ['macos', 'catalyst'].include?(Sigh.config[:platform].to_s)
        profile_name += '.provisionprofile'
      else
        profile_name += '.mobileprovision'
      end

      output_path = File.join(Sigh.config[:output_path], profile_name)
      File.open(output_path, "wb") do |f|
        content = Base64.decode64(profile.profile_content)
        f.write(content)
      end
      Manager.install_profile(output_path, Sigh.config[:keychain_path]) unless Sigh.config[:skip_install]
    end
  end
end
