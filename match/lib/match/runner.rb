require 'fastlane_core/cert_checker'
require 'fastlane_core/provisioning_profile'
require 'fastlane_core/print_table'
require 'spaceship/client'
require_relative 'generator'
require_relative 'module'
require_relative 'table_printer'
require_relative 'spaceship_ensure'
require_relative 'utils'

require_relative 'storage'
require_relative 'encryption'

module Match
  class Runner
    attr_accessor :files_to_commit
    attr_accessor :spaceship

    attr_accessor :storage

    # rubocop:disable Metrics/PerceivedComplexity
    def run(params)
      self.files_to_commit = []

      FileUtils.mkdir_p(params[:output_path]) if params[:output_path]

      FastlaneCore::PrintTable.print_values(config: params,
                                             title: "Summary for match #{Fastlane::VERSION}")

      update_optional_values_depending_on_storage_type(params)

      # Choose the right storage and encryption implementations
      self.storage = Storage.for_mode(params[:storage_mode], {
        git_url: params[:git_url],
        shallow_clone: params[:shallow_clone],
        skip_docs: params[:skip_docs],
        git_branch: params[:git_branch],
        git_full_name: params[:git_full_name],
        git_user_email: params[:git_user_email],
        clone_branch_directly: params[:clone_branch_directly],
        git_basic_authorization: params[:git_basic_authorization],
        git_bearer_authorization: params[:git_bearer_authorization],
        git_private_key: params[:git_private_key],
        type: params[:type].to_s,
        generate_apple_certs: params[:generate_apple_certs],
        platform: params[:platform].to_s,
        google_cloud_bucket_name: params[:google_cloud_bucket_name].to_s,
        google_cloud_keys_file: params[:google_cloud_keys_file].to_s,
        google_cloud_project_id: params[:google_cloud_project_id].to_s,
        s3_region: params[:s3_region],
        s3_access_key: params[:s3_access_key],
        s3_secret_access_key: params[:s3_secret_access_key],
        s3_bucket: params[:s3_bucket],
        s3_object_prefix: params[:s3_object_prefix],
        readonly: params[:readonly],
        username: params[:readonly] ? nil : params[:username], # only pass username if not readonly
        team_id: params[:team_id],
        team_name: params[:team_name],
        api_key_path: params[:api_key_path],
        api_key: params[:api_key]
      })
      storage.download

      # Init the encryption only after the `storage.download` was called to have the right working directory
      encryption = Encryption.for_storage_mode(params[:storage_mode], {
        git_url: params[:git_url],
        working_directory: storage.working_directory
      })
      encryption.decrypt_files if encryption

      unless params[:readonly]
        self.spaceship = SpaceshipEnsure.new(params[:username], params[:team_id], params[:team_name], api_token(params))
        if params[:type] == "enterprise" && !Spaceship.client.in_house?
          UI.user_error!("You defined the profile type 'enterprise', but your Apple account doesn't support In-House profiles")
        end
      end

      if params[:app_identifier].kind_of?(Array)
        app_identifiers = params[:app_identifier]
      else
        app_identifiers = params[:app_identifier].to_s.split(/\s*,\s*/).uniq
      end

      # sometimes we get an array with arrays, this is a bug. To unblock people using match, I suggest we flatten!
      # then in the future address the root cause of https://github.com/fastlane/fastlane/issues/11324
      app_identifiers.flatten!

      # Verify the App ID (as we don't want 'match' to fail at a later point)
      if spaceship
        app_identifiers.each do |app_identifier|
          spaceship.bundle_identifier_exists(username: params[:username], app_identifier: app_identifier, platform: params[:platform])
        end
      end

      # Certificate
      cert_id = fetch_certificate(params: params, working_directory: storage.working_directory)

      # Mac Installer Distribution Certificate
      additional_cert_types = params[:additional_cert_types] || []
      cert_ids = additional_cert_types.map do |additional_cert_type|
        fetch_certificate(params: params, working_directory: storage.working_directory, specific_cert_type: additional_cert_type)
      end

      cert_ids << cert_id
      spaceship.certificates_exists(username: params[:username], certificate_ids: cert_ids) if spaceship

      # Provisioning Profiles
      unless params[:skip_provisioning_profiles]
        app_identifiers.each do |app_identifier|
          loop do
            break if fetch_provisioning_profile(params: params,
                                        certificate_id: cert_id,
                                        app_identifier: app_identifier,
                                    working_directory: storage.working_directory)
          end
        end
      end

      if self.files_to_commit.count > 0 && !params[:readonly]
        encryption.encrypt_files if encryption
        storage.save_changes!(files_to_commit: self.files_to_commit)
      end

      # Print a summary table for each app_identifier
      app_identifiers.each do |app_identifier|
        TablePrinter.print_summary(app_identifier: app_identifier, type: params[:type], platform: params[:platform])
      end

      UI.success("All required keys, certificates and provisioning profiles are installed 🙌".green)
    rescue Spaceship::Client::UnexpectedResponse, Spaceship::Client::InvalidUserCredentialsError, Spaceship::Client::NoUserCredentialsError => ex
      UI.error("An error occurred while verifying your certificates and profiles with the Apple Developer Portal.")
      UI.error("If you already have your certificates stored in git, you can run `fastlane match` in readonly mode")
      UI.error("to just install the certificates and profiles without accessing the Dev Portal.")
      UI.error("To do so, just pass `readonly: true` to your match call.")
      raise ex
    ensure
      storage.clear_changes if storage
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def api_token(params)
      @api_token ||= Spaceship::ConnectAPI::Token.create(**params[:api_key]) if params[:api_key]
      @api_token ||= Spaceship::ConnectAPI::Token.from_json_file(params[:api_key_path]) if params[:api_key_path]
      return @api_token
    end

    # Used when creating a new certificate or profile
    def prefixed_working_directory
      return self.storage.prefixed_working_directory
    end

    # Be smart about optional values here
    # Depending on the storage mode, different values are required
    def update_optional_values_depending_on_storage_type(params)
      if params[:storage_mode] != "git"
        params.option_for_key(:git_url).optional = true
      end
    end

    def fetch_certificate(params: nil, working_directory: nil, specific_cert_type: nil)
      cert_type = Match.cert_type_sym(specific_cert_type || params[:type])

      certs = Dir[File.join(prefixed_working_directory, "certs", cert_type.to_s, "*.cer")]
      keys = Dir[File.join(prefixed_working_directory, "certs", cert_type.to_s, "*.p12")]

      if certs.count == 0 || keys.count == 0
        UI.important("Couldn't find a valid code signing identity for #{cert_type}... creating one for you now")
        UI.crash!("No code signing identity found and can not create a new one because you enabled `readonly`") if params[:readonly]
        cert_path = Generator.generate_certificate(params, cert_type, prefixed_working_directory, specific_cert_type: specific_cert_type)
        private_key_path = cert_path.gsub(".cer", ".p12")

        self.files_to_commit << cert_path
        self.files_to_commit << private_key_path
      else
        cert_path = certs.last

        # Check validity of certificate
        if Utils.is_cert_valid?(cert_path)
          UI.verbose("Your certificate '#{File.basename(cert_path)}' is valid")
        else
          UI.user_error!("Your certificate '#{File.basename(cert_path)}' is not valid, please check end date and renew it if necessary")
        end

        if Helper.mac?
          UI.message("Installing certificate...")

          # Only looking for cert in "custom" (non login.keychain) keychain
          # Doing this for backwards compatibility
          keychain_name = params[:keychain_name] == "login.keychain" ? nil : params[:keychain_name]

          if FastlaneCore::CertChecker.installed?(cert_path, in_keychain: keychain_name)
            UI.verbose("Certificate '#{File.basename(cert_path)}' is already installed on this machine")
          else
            Utils.import(cert_path, params[:keychain_name], password: params[:keychain_password])
          end

          # Import the private key
          # there seems to be no good way to check if it's already installed - so just install it
          # Key will only be added to the partition list if it isn't already installed
          Utils.import(keys.last, params[:keychain_name], password: params[:keychain_password])
        else
          UI.message("Skipping installation of certificate as it would not work on this operating system.")
        end

        if params[:output_path]
          FileUtils.cp(cert_path, params[:output_path])
          FileUtils.cp(keys.last, params[:output_path])
        end

        # Get and print info of certificate
        info = Utils.get_cert_info(cert_path)
        TablePrinter.print_certificate_info(cert_info: info)
      end

      return File.basename(cert_path).gsub(".cer", "") # Certificate ID
    end

    # rubocop:disable Metrics/PerceivedComplexity
    # @return [String] The UUID of the provisioning profile so we can verify it with the Apple Developer Portal
    def fetch_provisioning_profile(params: nil, certificate_id: nil, app_identifier: nil, working_directory: nil)
      prov_type = Match.profile_type_sym(params[:type])

      names = [Match::Generator.profile_type_name(prov_type), app_identifier]
      if params[:platform].to_s == :tvos.to_s || params[:platform].to_s == :catalyst.to_s
        names.push(params[:platform])
      end

      profile_name = names.join("_").gsub("*", '\*') # this is important, as it shouldn't be a wildcard
      base_dir = File.join(prefixed_working_directory, "profiles", prov_type.to_s)

      extension = ".mobileprovision"
      if [:macos.to_s, :catalyst.to_s].include?(params[:platform].to_s)
        extension = ".provisionprofile"
      end

      profile_file = "#{profile_name}#{extension}"
      profiles = Dir[File.join(base_dir, profile_file)]
      if Helper.mac?
        keychain_path = FastlaneCore::Helper.keychain_path(params[:keychain_name]) unless params[:keychain_name].nil?
      end

      # Install the provisioning profiles
      profile = profiles.last
      force = params[:force]

      if params[:force_for_new_devices] && !params[:readonly]
        if prov_type != :appstore && !params[:force]
          force = device_count_different?(profile: profile, keychain_path: keychain_path, platform: params[:platform].to_sym)
        else
          # App Store provisioning profiles don't contain device identifiers and
          # thus shouldn't be renewed if the device count has changed.
          UI.important("Warning: `force_for_new_devices` is set but is ignored for App Store provisioning profiles.")
          UI.important("You can safely stop specifying `force_for_new_devices` when running Match for type 'appstore'.")
        end
      end

      if profile.nil? || force
        if params[:readonly]
          UI.error("No matching provisioning profiles found for '#{profile_file}'")
          UI.error("A new one cannot be created because you enabled `readonly`")
          if Dir.exist?(base_dir) # folder for `prov_type` does not exist on first match use for that type
            all_profiles = Dir.entries(base_dir).reject { |f| f.start_with?(".") }
            UI.error("Provisioning profiles in your repo for type `#{prov_type}`:")
            all_profiles.each { |p| UI.error("- '#{p}'") }
          end
          UI.error("If you are certain that a profile should exist, double-check the recent changes to your match repository")
          UI.user_error!("No matching provisioning profiles found and can not create a new one because you enabled `readonly`. Check the output above for more information.")
        end

        profile = Generator.generate_provisioning_profile(params: params,
                                                       prov_type: prov_type,
                                                  certificate_id: certificate_id,
                                                  app_identifier: app_identifier,
                                                           force: force,
                                               working_directory: prefixed_working_directory)
        self.files_to_commit << profile
      end

      if Helper.mac?
        installed_profile = FastlaneCore::ProvisioningProfile.install(profile, keychain_path)
      end
      parsed = FastlaneCore::ProvisioningProfile.parse(profile, keychain_path)
      uuid = parsed["UUID"]

      if params[:output_path]
        FileUtils.cp(profile, params[:output_path])
      end

      if spaceship && !spaceship.profile_exists(username: params[:username], uuid: uuid, platform: params[:platform])
        # This profile is invalid, let's remove the local file and generate a new one
        File.delete(profile)
        # This method will be called again, no need to modify `files_to_commit`
        return nil
      end

      Utils.fill_environment(Utils.environment_variable_name(app_identifier: app_identifier,
                                                                       type: prov_type,
                                                                   platform: params[:platform]),
                             uuid)

      # TeamIdentifier is returned as an array, but we're not sure why there could be more than one
      Utils.fill_environment(Utils.environment_variable_name_team_id(app_identifier: app_identifier,
                                                                               type: prov_type,
                                                                           platform: params[:platform]),
                             parsed["TeamIdentifier"].first)

      Utils.fill_environment(Utils.environment_variable_name_profile_name(app_identifier: app_identifier,
                                                                                    type: prov_type,
                                                                                platform: params[:platform]),
                             parsed["Name"])

      Utils.fill_environment(Utils.environment_variable_name_profile_path(app_identifier: app_identifier,
                                                                                    type: prov_type,
                                                                                platform: params[:platform]),
                             installed_profile)

      return uuid
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def device_count_different?(profile: nil, keychain_path: nil, platform: nil)
      return false unless profile

      parsed = FastlaneCore::ProvisioningProfile.parse(profile, keychain_path)
      uuid = parsed["UUID"]

      all_profiles = Spaceship::ConnectAPI::Profile.all(includes: "devices")
      portal_profile = all_profiles.detect { |i| i.uuid == uuid }

      if portal_profile
        profile_device_count = portal_profile.fetch_all_devices.count

        device_classes =
          case platform
          when :ios
            [
              Spaceship::ConnectAPI::Device::DeviceClass::IPAD,
              Spaceship::ConnectAPI::Device::DeviceClass::IPHONE,
              Spaceship::ConnectAPI::Device::DeviceClass::IPOD,
              Spaceship::ConnectAPI::Device::DeviceClass::APPLE_WATCH
            ]
          when :tvos
            [
              Spaceship::ConnectAPI::Device::DeviceClass::APPLE_TV
            ]
          when :mac, :catalyst
            [
              Spaceship::ConnectAPI::Device::DeviceClass::MAC
            ]
          else
            []
          end

        devices = Spaceship::ConnectAPI::Device.all
        unless device_classes.empty?
          devices = devices.select do |device|
            device_classes.include?(device.device_class) && device.enabled?
          end
        end

        portal_device_count = devices.size

        return portal_device_count != profile_device_count
      end
      return false
    end
  end
end
