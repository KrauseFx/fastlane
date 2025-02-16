require_relative 'module'
require_relative 'profile_includes'

module Match
  # Generate missing resources
  class Generator
    def self.generate_certificate(params, cert_type, working_directory, specific_cert_type: nil)
      require 'cert/runner'
      require 'cert/options'

      output_path = File.join(working_directory, "certs", cert_type.to_s)

      # Mapping match option to cert option for "Developer ID Application"
      if cert_type.to_sym == :developer_id_application
        specific_cert_type = cert_type.to_s
      end

      platform = params[:platform]
      if platform.to_s == :catalyst.to_s
        platform = :macos.to_s
      end

      arguments = FastlaneCore::Configuration.create(Cert::Options.available_options, {
        platform: platform,
        development: params[:type] == "development",
        type: specific_cert_type,
        generate_apple_certs: params[:generate_apple_certs],
        output_path: output_path,
        force: true, # we don't need a certificate without its private key, we only care about a new certificate
        api_key_path: params[:api_key_path],
        api_key: params[:api_key],
        username: params[:username],
        team_id: params[:team_id],
        team_name: params[:team_name],
        keychain_path: Helper.mac? ? FastlaneCore::Helper.keychain_path(params[:keychain_name]) : nil,
        keychain_password: Helper.mac? ? params[:keychain_password] : nil,
        skip_set_partition_list: params[:skip_set_partition_list]
      })

      Cert.config = arguments

      begin
        cert_path = Cert::Runner.new.launch
      rescue => ex
        if ex.to_s.include?("You already have a current")
          UI.user_error!("Could not create a new certificate as you reached the maximum number of certificates for this account. You can use the `fastlane match nuke` command to revoke your existing certificates. More information https://docs.fastlane.tools/actions/match/")
        else
          raise ex
        end
      end

      # We don't care about the signing request
      Dir[File.join(working_directory, "**", "*.certSigningRequest")].each { |path| File.delete(path) }

      # we need to return the path
      # Inside this directory, there is the `.p12` file and the `.cer` file with the same name, but different extension
      return cert_path
    end

    # @return (String) The UUID of the newly generated profile
    def self.generate_provisioning_profile(params: nil, prov_type: nil, certificate_id: nil, app_identifier: nil, force: true, cache: nil, working_directory: nil)
      require 'sigh/manager'
      require 'sigh/options'

      prov_type = Match.profile_type_sym(params[:type])

      names = ["match", profile_type_name(prov_type), app_identifier]

      if params[:platform].to_s != :ios.to_s # For ios we do not include the platform for backwards compatibility
        names << params[:platform]
      end

      if params[:profile_name].to_s.empty?
        profile_name = names.join(" ")
      else
        profile_name = params[:profile_name]
      end

      values = {
        app_identifier: app_identifier,
        output_path: File.join(working_directory, "profiles", prov_type.to_s),
        username: params[:username],
        force: force,
        cert_id: certificate_id,
        provisioning_name: profile_name,
        ignore_profiles_with_different_name: true,
        api_key_path: params[:api_key_path],
        api_key: params[:api_key],
        team_id: params[:team_id],
        team_name: params[:team_name],
        template_name: params[:template_name],
        fail_on_name_taken: params[:fail_on_name_taken],
        include_all_certificates: params[:include_all_certificates],
        include_mac_in_profiles: params[:include_mac_in_profiles],
        offline_profile: params[:offline_profile],
      }

      values[:platform] = params[:platform]

      # These options are all conflicting so can only set one
      if params[:type] == "developer_id"
        values[:developer_id] = true
      elsif prov_type == :adhoc
        values[:adhoc] = true
      elsif prov_type == :development
        values[:development] = true
      end

      if cache
        values[:cached_certificates] = cache.certificates
        values[:cached_devices] = cache.devices
        values[:cached_bundle_ids] = cache.bundle_ids
        values[:cached_profiles] = cache.profiles
      end

      arguments = FastlaneCore::Configuration.create(Sigh::Options.available_options, values)

      Sigh.config = arguments
      path = Sigh::Manager.start
      return path
    end

    # @return the name of the provisioning profile type
    def self.profile_type_name(type)
      return "Direct" if type == :developer_id
      return "Development" if type == :development
      return "AdHoc" if type == :adhoc
      return "AppStore" if type == :appstore
      return "InHouse" if type == :enterprise
      return "Unknown"
    end
  end
end
