require 'shellwords'
require 'fastlane_core/globals'

require_relative 'module'

module Sigh
  # Resigns an existing ipa file
  class Resign
    def run(options, args)
      # get the command line inputs and parse those into the vars we need...
      ipa, signing_identity, provisioning_profiles, entitlements, version, display_name, short_version, bundle_version, new_bundle_id, new_appclip_bundle_id, use_app_entitlements, keychain_path = get_inputs(options, args)
      # ... then invoke our programmatic interface with these vars
      unless resign(ipa, signing_identity, provisioning_profiles, entitlements, version, display_name, short_version, bundle_version, new_bundle_id, new_appclip_bundle_id, use_app_entitlements, keychain_path)
        UI.user_error!("Failed to re-sign .ipa")
      end
    end

    def self.resign(ipa, signing_identity, provisioning_profiles, entitlements, version, display_name, short_version, bundle_version, new_bundle_id, new_appclip_bundle_id, use_app_entitlements, keychain_path)
      self.new.resign(ipa, signing_identity, provisioning_profiles, entitlements, version, display_name, short_version, bundle_version, new_bundle_id, new_appclip_bundle_id, use_app_entitlements, keychain_path)
    end

    def resign(ipa, signing_identity, provisioning_profiles, entitlements, version, display_name, short_version, bundle_version, new_bundle_id, new_appclip_bundle_id, use_app_entitlements, keychain_path)
      resign_path = find_resign_path

      if keychain_path
        keychain_path_absolute = File.expand_path(keychain_path)

        current_keychains = `security list-keychains`
        current_keychains.delete!("\n")

        unless current_keychains.include?(keychain_path_absolute)
          previous_keychains = current_keychains
          `security list-keychains -s #{current_keychains} '#{keychain_path_absolute}'`
        end
      end

      signing_identity = find_signing_identity(signing_identity)

      unless provisioning_profiles.kind_of?(Enumerable)
        provisioning_profiles = [provisioning_profiles]
      end

      # validate that we have valid values for all these params, we don't need to check signing_identity because `find_signing_identity` will only ever return a valid value
      validate_params(resign_path, ipa, provisioning_profiles)
      entitlements = "-e #{entitlements.shellescape}" if entitlements

      provisioning_options = create_provisioning_options(provisioning_profiles)
      version = "-n #{version}" if version
      display_name = "-d #{display_name.shellescape}" if display_name
      short_version = "--short-version #{short_version}" if short_version
      bundle_version = "--bundle-version #{bundle_version}" if bundle_version
      verbose = "-v" if FastlaneCore::Globals.verbose?
      bundle_id = "-b '#{new_bundle_id}'" if new_bundle_id
      appclip_bundle_id = "--app-clip-bundle-id '#{new_appclip_bundle_id}'" if new_appclip_bundle_id
      use_app_entitlements_flag = "--use-app-entitlements" if use_app_entitlements
      specific_keychain = "--keychain-path #{keychain_path.shellescape}" if keychain_path

      command = [
        resign_path.shellescape,
        ipa.shellescape,
        signing_identity.shellescape,
        provisioning_options, # we are already shellescaping this above, when we create the provisioning_options from the provisioning_profiles
        entitlements,
        version,
        display_name,
        short_version,
        bundle_version,
        use_app_entitlements_flag,
        verbose,
        bundle_id,
        appclip_bundle_id,
        specific_keychain,
        ipa.shellescape # Output path must always be last argument
      ].join(' ')

      puts(command.magenta)
      puts(`#{command}`)

      if $?.to_i == 0
        UI.success("Successfully signed #{ipa}!")
        true
      else
        UI.error("Something went wrong while code signing #{ipa}")
        false
      end
    ensure
      `security list-keychains -s #{previous_keychains}` if previous_keychains
    end

    def get_inputs(options, args)
      ipa = args.first || find_ipa || UI.input('Path to ipa file: ')
      signing_identity = options.signing_identity || ask_for_signing_identity
      provisioning_profiles = options.provisioning_profile || find_provisioning_profile || UI.input('Path to provisioning file: ')
      entitlements = options.entitlements || nil
      version = options.version_number || nil
      display_name = options.display_name || nil
      short_version = options.short_version || nil
      bundle_version = options.bundle_version || nil
      new_bundle_id = options.new_bundle_id || nil
      new_appclip_bundle_id = options.new_appclip_bundle_id || nil
      use_app_entitlements = options.use_app_entitlements || nil
      keychain_path = options.keychain_path || nil

      if options.provisioning_name
        UI.important("The provisioning_name (-n) option is not applicable to resign. You should use provisioning_profile (-p) instead")
      end

      return ipa, signing_identity, provisioning_profiles, entitlements, version, display_name, short_version, bundle_version, new_bundle_id, new_appclip_bundle_id, use_app_entitlements, keychain_path
    end

    def find_resign_path
      File.join(Sigh::ROOT, 'lib', 'assets', 'resign.sh')
    end

    def find_ipa
      Dir[File.join(Dir.pwd, '*.ipa')].sort { |a, b| File.mtime(a) <=> File.mtime(b) }.first
    end

    def find_provisioning_profile
      Dir[File.join(Dir.pwd, '*.mobileprovision')].sort { |a, b| File.mtime(a) <=> File.mtime(b) }.first
    end

    def find_signing_identity(signing_identity)
      signing_identity_input = signing_identity
      until (signing_identity = sha1_for_signing_identity(signing_identity_input))
        UI.error("Couldn't find signing identity '#{signing_identity_input}'.")
        signing_identity_input = ask_for_signing_identity
      end

      signing_identity
    end

    def sha1_for_signing_identity(signing_identity)
      identities = installed_identities
      return signing_identity if identities.keys.include?(signing_identity)
      identities.key(signing_identity)
    end

    def create_provisioning_options(provisioning_profiles)
      # provisioning_profiles is passed either a hash (to be able to resign extensions/nested apps):
      # (in that case the underlying resign.sh expects values given as "-p at.fastlane=/folder/mobile.mobileprovision -p at.fastlane.today=/folder/mobile.mobileprovision")
      #   {
      #     "at.fastlane" => "/folder/mobile.mobileprovision",
      #     "at.fastlane.today" => "/folder/mobile.mobileprovision"
      #   }
      # or an array
      # (resign.sh also takes "-p /folder/mobile.mobileprovision" as a param)
      #   [
      #        "/folder/mobile.mobileprovision"
      #   ]
      provisioning_profiles.map do |app_id, app_id_prov|
        if app_id_prov
          app_id_prov = File.expand_path(app_id_prov)
        else
          app_id = File.expand_path(app_id)
        end
        "-p #{[app_id, app_id_prov].compact.map(&:shellescape).join('=')}"
      end.join(' ')
    end

    def validate_params(resign_path, ipa, provisioning_profiles)
      validate_resign_path(resign_path)
      validate_ipa_file(ipa)
      provisioning_profiles.each { |fst, snd| validate_provisioning_file(snd || fst) }
    end

    def validate_resign_path(resign_path)
      UI.user_error!('Could not find resign.sh file. Please try re-installing the gem') unless File.exist?(resign_path)
    end

    def validate_ipa_file(ipa)
      UI.user_error!("ipa file could not be found or is not an ipa file (#{ipa})") unless File.exist?(ipa) && ipa.end_with?('.ipa')
    end

    def validate_provisioning_file(provisioning_profile)
      unless File.exist?(provisioning_profile) && provisioning_profile.end_with?('.mobileprovision')
        UI.user_error!("Provisioning profile file could not be found or is not a .mobileprovision file (#{provisioning_profile})")
      end
    end

    def print_available_identities
      UI.message("Available identities: \n\t#{installed_identity_descriptions.join("\n\t")}\n")
    end

    def ask_for_signing_identity
      print_available_identities
      UI.input('Signing Identity: ')
    end

    # Hash of available signing identities
    def installed_identities
      available = request_valid_identities
      ids = {}
      available.split("\n").each do |current|
        begin
          sha1 = current.match(/[a-zA-Z0-9]{40}/).to_s
          name = current.match(/.*\"(.*)\"/)[1]
          ids[sha1] = name
        rescue
          nil
        end # the last line does not match
      end

      ids
    end

    def request_valid_identities
      `security find-identity -v -p codesigning`
    end

    def installed_identity_descriptions
      descriptions = []
      installed_identities.group_by { |sha1, name| name }.each do |name, identities|
        descriptions << name
        # Show SHA-1 for homonymous identities
        descriptions += identities.map do |sha1, _|
          "\t#{sha1}"
        end
      end
      descriptions
    end
  end
end
