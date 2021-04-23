require 'spaceship'

require 'base64'

require 'fastlane_core/print_table'
require 'fastlane_core/cert_checker'
require_relative 'module'

module Sigh
  class Runner
    attr_accessor :spaceship

    # Uses the spaceship to create or download a provisioning profile
    # returns the path the newly created provisioning profile (in /tmp usually)
    def run
      FastlaneCore::PrintTable.print_values(config: Sigh.config,
                                         hide_keys: [:output_path],
                                             title: "Summary for sigh #{Fastlane::VERSION}")

      if api_token
        UI.message("Creating authorization token for App Store Connect API")
        Spaceship::ConnectAPI.token = api_token
      else
        # Username is now optional since addition of App Store Connect API Key
        # Force asking for username to prompt user if not already set
        Sigh.config.fetch(:username, force_ask: true)

        # Team selection passed though FASTLANE_ITC_TEAM_ID and FASTLANE_ITC_TEAM_NAME environment variables
        # Prompts select team if multiple teams and none specified
        UI.message("Starting login with user '#{Sigh.config[:username]}'")
        Spaceship::ConnectAPI.login(Sigh.config[:username], nil, use_portal: true, use_tunes: false)
        UI.message("Successfully logged in")
      end

      profiles = [] if Sigh.config[:skip_fetch_profiles]
      profiles ||= fetch_profiles # download the profile if it's there

      if profiles.count > 0
        UI.success("Found #{profiles.count} matching profile(s)")
        profile = profiles.first

        if Sigh.config[:force]
          # Recreating the profile ensures it has all of the requested properties (cert, name, etc.)
          UI.important("Recreating the profile")
          profile.delete!
          profile = create_profile!
        end
      else
        UI.user_error!("No matching provisioning profile found and can not create a new one because you enabled `readonly`") if Sigh.config[:readonly]
        UI.important("No existing profiles found, that match the certificates you have installed locally! Creating a new provisioning profile for you")
        ensure_app_exists!
        profile = create_profile!
      end

      UI.user_error!("Something went wrong fetching the latest profile") unless profile

      if [Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_INHOUSE, Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_INHOUSE].include?(profile_type)
        ENV["SIGH_PROFILE_ENTERPRISE"] = "1"
      else
        ENV.delete("SIGH_PROFILE_ENTERPRISE")
      end

      return download_profile(profile)
    end

    def api_token
      @api_token ||= Spaceship::ConnectAPI::Token.create(**Sigh.config[:api_key]) if Sigh.config[:api_key]
      @api_token ||= Spaceship::ConnectAPI::Token.from_json_file(Sigh.config[:api_key_path]) if Sigh.config[:api_key_path]
      return @api_token
    end

    # The kind of provisioning profile we're interested in
    def profile_type
      return @profile_type if @profile_type

      case Sigh.config[:platform]
      when "ios"
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_STORE
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_INHOUSE if Spaceship::ConnectAPI.client.in_house?
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_ADHOC if Sigh.config[:adhoc]
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_DEVELOPMENT if Sigh.config[:development]
      when "tvos"
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_STORE
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_INHOUSE if Spaceship::ConnectAPI.client.in_house?
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_ADHOC if Sigh.config[:adhoc]
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_DEVELOPMENT if Sigh.config[:development]
      when "macos"
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_STORE
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_DEVELOPMENT if Sigh.config[:development]
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_DIRECT if Sigh.config[:developer_id]
      when "catalyst"
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_STORE
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_DEVELOPMENT if Sigh.config[:development]
        @profile_type = Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_DIRECT if Sigh.config[:developer_id]
      end

      @profile_type
    end

    # Fetches a profile matching the user's search requirements
    def fetch_profiles
      UI.message("Fetching profiles...")

      # Filtering on 'profileType' seems to be undocumented as of 2020-07-30
      # but works on both web session and official API
      results = Spaceship::ConnectAPI::Profile.all(filter: { profileType: profile_type }, includes: "bundleId,certificates").select do |profile|
        profile.bundle_id.identifier == Sigh.config[:app_identifier]
      end

      results = results.find_all do |current_profile|
        if current_profile.valid? || Sigh.config[:force]
          true
        else
          UI.message("Provisioning Profile '#{current_profile.name}' is not valid, skipping this one...")
          false
        end
      end

      # Take the provisioning profile name into account
      results = filter_profiles_by_name(results) if Sigh.config[:provisioning_name].to_s.length > 0
      return results if Sigh.config[:skip_certificate_verification]

      UI.message("Verifying certificates...")
      return results.find_all do |current_profile|
        installed = false

        # Attempts to download all certificates from this profile
        # for checking if they are installed.
        # `cert.download_raw` can fail if the user is a
        # "member" and not an a "admin"
        raw_certs = current_profile.certificates.map do |cert|
          begin
            raw_cert = Base64.decode64(cert.certificate_content)
          rescue => error
            UI.important("Cannot download cert #{cert.id} - #{error.message}")
            raw_cert = nil
          end
          { downloaded: raw_cert, cert: cert }
        end

        # Makes sure we have the certificate installed on the local machine
        raw_certs.each do |current_cert|
          # Skip certificates that failed to download
          next unless current_cert[:downloaded]
          file = Tempfile.new('cert')
          file.write(current_cert[:downloaded].force_encoding('UTF-8'))
          file.close
          if FastlaneCore::CertChecker.installed?(file.path)
            installed = true
          else
            UI.message("Certificate for Provisioning Profile '#{current_profile.name}' not available locally: #{current_cert[:cert].id}, skipping this one...")
          end
        end

        # Don't need to check if certificate is valid because it comes with the
        # profile in the response
        installed
      end
    end

    def profile_type_pretty_type
      return Sigh.profile_pretty_type(profile_type)
    end

    # Create a new profile and return it
    def create_profile!
      app_identifier = Sigh.config[:app_identifier]
      name = Sigh.config[:provisioning_name] || [app_identifier, profile_type_pretty_type].join(' ')

      unless Sigh.config[:skip_fetch_profiles]
        profile = Spaceship::ConnectAPI::Profile.all.find { |p| p.name == name }
        if profile
          UI.user_error!("The name '#{name}' is already taken, and fail_on_name_taken is true") if Sigh.config[:fail_on_name_taken]
          UI.error("The name '#{name}' is already taken, using another one.")
          name += " #{Time.now.to_i}"
        end
      end

      bundle_id = Spaceship::ConnectAPI::BundleId.find(app_identifier)
      unless bundle_id
        UI.user_error!("Could not find App with App Identifier '#{Sigh.config[:app_identifier]}'")
      end

      UI.important("Creating new provisioning profile for '#{Sigh.config[:app_identifier]}' with name '#{name}' for '#{Sigh.config[:platform]}' platform")

      Spaceship::ConnectAPI::Profile.create(
        name: name,
        profile_type: profile_type,
        bundle_id_id: bundle_id.id,
        certificate_ids: certificates_to_use.map(&:id),
        device_ids: devices_to_use.map(&:id),
        template_name: Sigh.config[:template_name]
      )
    end

    def filter_profiles_by_name(profiles)
      filtered = profiles.select { |p| p.name.strip == Sigh.config[:provisioning_name].strip }
      if Sigh.config[:ignore_profiles_with_different_name]
        profiles = filtered
      elsif (filtered || []).count > 0
        profiles = filtered
      end
      profiles
    end

    def fetch_certificates(certificate_types)
      filter = {
        certificateType: certificate_types.join(',')
      }
      return Spaceship::ConnectAPI::Certificate.all(filter: filter)
    end

    def certificates_for_profile_and_platform
      types = []

      case Sigh.config[:platform].to_s
      when 'ios', 'tvos'
        if profile_type == Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_DEVELOPMENT || profile_type == Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_DEVELOPMENT
          types = [
            Spaceship::ConnectAPI::Certificate::CertificateType::DEVELOPMENT,
            Spaceship::ConnectAPI::Certificate::CertificateType::IOS_DEVELOPMENT
          ]
        elsif profile_type == Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_INHOUSE || profile_type == Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_INHOUSE
          # Enterprise accounts don't have access to Apple Distribution certificates
          types = [
            Spaceship::ConnectAPI::Certificate::CertificateType::IOS_DISTRIBUTION
          ]
        # handles case where the desired certificate type is adhoc but the account is an enterprise account
        # the apple dev portal api has a weird quirk in it where if you query for distribution certificates
        # for enterprise accounts, you get nothing back even if they exist.
        elsif (profile_type == Spaceship::ConnectAPI::Profile::ProfileType::IOS_APP_ADHOC || profile_type == Spaceship::ConnectAPI::Profile::ProfileType::TVOS_APP_ADHOC) && Spaceship::ConnectAPI.client && Spaceship::ConnectAPI.client.in_house?
          # Enterprise accounts don't have access to Apple Distribution certificates
          types = [
            Spaceship::ConnectAPI::Certificate::CertificateType::IOS_DISTRIBUTION
          ]
        else
          types = [
            Spaceship::ConnectAPI::Certificate::CertificateType::DISTRIBUTION,
            Spaceship::ConnectAPI::Certificate::CertificateType::IOS_DISTRIBUTION
          ]
        end

      when 'macos', 'catalyst'
        if profile_type == Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_DEVELOPMENT || profile_type == Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_DEVELOPMENT
          types = [
            Spaceship::ConnectAPI::Certificate::CertificateType::DEVELOPMENT,
            Spaceship::ConnectAPI::Certificate::CertificateType::MAC_APP_DEVELOPMENT
          ]
        elsif profile_type == Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_STORE || profile_type == Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_STORE
          types = [
            Spaceship::ConnectAPI::Certificate::CertificateType::DISTRIBUTION,
            Spaceship::ConnectAPI::Certificate::CertificateType::MAC_APP_DISTRIBUTION
          ]
        elsif profile_type == Spaceship::ConnectAPI::Profile::ProfileType::MAC_APP_DIRECT || profile_type == Spaceship::ConnectAPI::Profile::ProfileType::MAC_CATALYST_APP_DIRECT
          types = [
            Spaceship::ConnectAPI::Certificate::CertificateType::DEVELOPER_ID_APPLICATION
          ]
        else
          types = [
            Spaceship::ConnectAPI::Certificate::CertificateType::DISTRIBUTION,
            Spaceship::ConnectAPI::Certificate::CertificateType::MAC_APP_DISTRIBUTION
          ]
        end
      end

      fetch_certificates(types)
    end

    def devices_to_use
      # Only use devices if development or adhoc
      return [] if !Sigh.config[:development] && !Sigh.config[:adhoc]

      device_classes = case Sigh.config[:platform].to_s
                       when 'ios'
                         [
                           Spaceship::ConnectAPI::Device::DeviceClass::APPLE_WATCH,
                           Spaceship::ConnectAPI::Device::DeviceClass::IPAD,
                           Spaceship::ConnectAPI::Device::DeviceClass::IPHONE,
                           Spaceship::ConnectAPI::Device::DeviceClass::IPOD
                         ]
                       when 'tvos'
                         [Spaceship::ConnectAPI::Device::DeviceClass::APPLE_TV]
                       when 'macos', 'catalyst'
                         [Spaceship::ConnectAPI::Device::DeviceClass::MAC]
                       end

      if api_token
        return Spaceship::ConnectAPI::Device.all.select do |device|
          device_classes.include?(device.device_class)
        end
      else
        filter = { deviceClass: device_classes.join(",") }
        return Spaceship::ConnectAPI::Device.all(filter: filter)
      end
    end

    # Certificate to use based on the current distribution mode
    def certificates_to_use
      certificates = certificates_for_profile_and_platform

      # Filter them
      certificates = certificates.find_all do |c|
        if Sigh.config[:cert_id]
          next unless c.id == Sigh.config[:cert_id].strip
        end

        if Sigh.config[:cert_owner_name]
          next unless c.display_name.strip == Sigh.config[:cert_owner_name].strip
        end

        true
      end

      # verify certificates
      if Helper.mac?
        unless Sigh.config[:skip_certificate_verification]
          certificates = certificates.find_all do |c|
            file = Tempfile.new('cert')
            raw_data = Base64.decode64(c.certificate_content)
            file.write(raw_data.force_encoding("UTF-8"))
            file.close

            FastlaneCore::CertChecker.installed?(file.path)
          end
        end
      end

      if certificates.count > 1 && !Sigh.config[:development]
        UI.important("Found more than one code signing identity. Choosing the first one. Check out `fastlane sigh --help` to see all available options.")
        UI.important("Available Code Signing Identities for current filters:")
        certificates.each do |c|
          str = ["\t- Name:", c.display_name, "- ID:", c.id + " - Expires", Time.parse(c.expiration_date).strftime("%Y-%m-%d")].join(" ")
          UI.message(str.green)
        end
      end

      if certificates.count == 0
        filters = ""
        filters << "Owner Name: '#{Sigh.config[:cert_owner_name]}' " if Sigh.config[:cert_owner_name]
        filters << "Certificate ID: '#{Sigh.config[:cert_id]}' " if Sigh.config[:cert_id]
        UI.important("No certificates for filter: #{filters}") if filters.length > 0
        message = "Could not find a matching code signing identity for type '#{profile_type_pretty_type}'. "
        message += "It is recommended to use match to manage code signing for you, more information on https://codesigning.guide. "
        message += "If you don't want to do so, you can also use cert to generate a new one: https://fastlane.tools/cert"
        UI.user_error!(message)
      end

      return certificates if Sigh.config[:development] # development profiles support multiple certificates
      return [certificates.first]
    end

    # Downloads and stores the provisioning profile
    def download_profile(profile)
      UI.important("Downloading provisioning profile...")
      profile_name ||= "#{profile_type_pretty_type}_#{Sigh.config[:app_identifier]}"

      if Sigh.config[:platform].to_s == 'tvos'
        profile_name += "_tvos"
      elsif Sigh.config[:platform].to_s == 'catalyst'
        profile_name += "_catalyst"
      end

      if ['macos', 'catalyst'].include?(Sigh.config[:platform].to_s)
        profile_name += '.provisionprofile'
      else
        profile_name += '.mobileprovision'
      end

      tmp_path = Dir.mktmpdir("profile_download")
      output_path = File.join(tmp_path, profile_name)
      File.open(output_path, "wb") do |f|
        content = Base64.decode64(profile.profile_content)
        f.write(content)
      end

      UI.success("Successfully downloaded provisioning profile...")
      return output_path
    end

    # Makes sure the current App ID exists. If not, it will show an appropriate error message
    def ensure_app_exists!
      # Only ensuring by app identifier
      # We used to ensure by platform (IOS and MAC_OS) but now apps are
      # always UNIVERSAL as of 2020-07-30
      return if Spaceship::ConnectAPI::BundleId.find(Sigh.config[:app_identifier])
      print_produce_command(Sigh.config)
      UI.user_error!("Could not find App with App Identifier '#{Sigh.config[:app_identifier]}'")
    end

    def print_produce_command(config)
      UI.message("")
      UI.message("==========================================".yellow)
      UI.message("Could not find App ID with bundle identifier '#{config[:app_identifier]}'")
      UI.message("You can easily generate a new App ID on the Developer Portal using 'produce':")
      UI.message("")
      UI.message("fastlane produce -u #{config[:username]} -a #{config[:app_identifier]} --skip_itc".yellow)
      UI.message("")
      UI.message("You will be asked for any missing information, like the full name of your app")
      UI.message("If the app should also be created on App Store Connect, remove the " + "--skip_itc".yellow + " from the command above")
      UI.message("==========================================".yellow)
      UI.message("")
    end
  end
end
