require 'plist'
require 'fastlane_core/globals'

require_relative 'module'

module Sigh
  class LocalManage
    LIST = "list"
    CLEANUP = "cleanup"

    def self.start(options, args)
      command, clean_expired, clean_pattern, force = get_inputs(options, args)
      if command == LIST
        list_profiles
      elsif command == CLEANUP
        cleanup_profiles(clean_expired, clean_pattern, force)
      end
    end

    def self.install_profile(profile)
      UI.message("Installing provisioning profile...")
      profile_path = File.expand_path("~") + "/Library/MobileDevice/Provisioning Profiles/"
      uuid = ENV["SIGH_UUID"] || ENV["SIGH_UDID"]
      profile_filename = uuid + ".mobileprovision"
      destination = profile_path + profile_filename

      # If the directory doesn't exist, make it first
      unless File.directory?(profile_path)
        FileUtils.mkdir_p(profile_path)
      end

      # copy to Xcode provisioning profile directory
      FileUtils.copy(profile, destination)

      if File.exist?(destination)
        UI.success("Profile installed at \"#{destination}\"")
      else
        UI.user_error!("Failed installation of provisioning profile at location: #{destination}")
      end
    end

    def self.get_inputs(options, _args)
      clean_expired = options.clean_expired
      clean_pattern = /#{options.clean_pattern}/ if options.clean_pattern
      force = options.force
      command = (!clean_expired.nil? || !clean_pattern.nil?) ? CLEANUP : LIST
      return command, clean_expired, clean_pattern, force
    end

    def self.list_profiles
      profiles = load_profiles

      now = DateTime.now
      soon = (Date.today + 30).to_datetime

      profiles_valid = profiles.select { |profile| profile["ExpirationDate"] > now && profile["ExpirationDate"] > soon }
      if profiles_valid.count > 0
        UI.message("Provisioning profiles installed")
        UI.message("Valid:")
        profiles_valid.each do |profile|
          UI.message(profile_info(profile).green)
        end
      end

      profiles_soon = profiles.select { |profile| profile["ExpirationDate"] > now && profile["ExpirationDate"] < soon }
      if profiles_soon.count > 0
        UI.message("")
        UI.message("Expiring within 30 days:")
        profiles_soon.each do |profile|
          UI.message(profile_info(profile).yellow)
        end
      end

      profiles_expired = profiles.select { |profile| profile["ExpirationDate"] < now }
      if profiles_expired.count > 0
        UI.message("")
        UI.message("Expired:")
        profiles_expired.each do |profile|
          UI.message(profile_info(profile).red)
        end
      end

      UI.message("")
      UI.message("Summary")
      UI.message("#{profiles.count} installed profiles")
      UI.message("#{profiles_expired.count} are expired".red) if profiles_expired.count > 0
      UI.message("#{profiles_soon.count} are valid but will expire within 30 days".yellow)
      UI.message("#{profiles_valid.count} are valid".green)

      UI.message("You can remove all expired profiles using `fastlane sigh manage -e`") if profiles_expired.count > 0
    end

    def self.profile_info(profile)
      if FastlaneCore::Globals.verbose?
        "#{profile['Name']} - #{File.basename(profile['Path'])}"
      else
        profile['Name']
      end
    end

    def self.cleanup_profiles(expired = false, pattern = nil, force = nil)
      now = DateTime.now

      profiles = load_profiles.select { |profile| (expired && profile["ExpirationDate"] < now) || (!pattern.nil? && profile["Name"] =~ pattern) }
      if profiles.empty?
        UI.important("No provisioning profiles that are either expired or match your pattern found")
        return
      end

      UI.message("The following provisioning profiles are either expired or match your pattern:")
      profiles.each do |profile|
        UI.message(profile["Name"].red)
      end

      delete = force
      unless delete
        if Helper.ci?
          UI.user_error!("On a CI server, cleanup cannot be used without the --force option")
        else
          delete = UI.confirm("Delete these provisioning profiles #{profiles.length}?")
        end
      end

      if delete
        profiles.each do |profile|
          File.delete(profile["Path"])
        end
        UI.success("\n\nDeleted #{profiles.length} profiles")
      end
    end

    def self.load_profiles
      UI.message("Loading Provisioning profiles from ~/Library/MobileDevice/Provisioning Profiles/")
      profiles_path = File.expand_path("~") + "/Library/MobileDevice/Provisioning Profiles/*.mobileprovision"
      profile_paths = Dir[profiles_path]

      profiles = []
      profile_paths.each do |profile_path|
        profile = Plist.parse_xml(`security cms -D -i '#{profile_path}' 2> /dev/null`) # /dev/null: https://github.com/fastlane/fastlane/issues/6387
        profile['Path'] = profile_path
        profiles << profile
      end

      profiles = profiles.sort_by { |profile| profile["Name"].downcase }

      return profiles
    end
  end
end
