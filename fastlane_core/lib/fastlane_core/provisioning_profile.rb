require_relative 'ui/ui'

module FastlaneCore
  class ProvisioningProfile
    class << self
      # @return (Hash) The hash with the data of the provisioning profile
      # @example
      #  {"AppIDName"=>"My App Name",
      #   "ApplicationIdentifierPrefix"=>["5A997XSAAA"],
      #   "CreationDate"=>#<DateTime: 2015-05-24T20:38:03+00:00 ((2457167j,74283s,0n),+0s,2299161j)>,
      #   "DeveloperCertificates"=>[#<StringIO:0x007f944b9666f8>],
      #   "Entitlements"=>
      #    {"keychain-access-groups"=>["5A997XSAAA.*"],
      #     "get-task-allow"=>false,
      #     "application-identifier"=>"5A997XAAA.net.sunapps.192",
      #     "com.apple.developer.team-identifier"=>"5A997XAAAA",
      #     "aps-environment"=>"production",
      #     "beta-reports-active"=>true},
      #   "ExpirationDate"=>#<DateTime: 2015-11-25T22:45:50+00:00 ((2457352j,81950s,0n),+0s,2299161j)>,
      #   "Name"=>"net.sunapps.192 AppStore",
      #   "TeamIdentifier"=>["5A997XSAAA"],
      #   "TeamName"=>"SunApps GmbH",
      #   "TimeToLive"=>185,
      #   "UUID"=>"1752e382-53bd-4910-a393-aaa7de0005ad",
      #   "Version"=>1}
      def parse(path, keychain_path = nil)
        require 'plist'

        plist = Plist.parse_xml(decode(path, keychain_path))
        if (plist || []).count > 5
          plist
        else
          UI.crash!("Error parsing provisioning profile at path '#{path}'")
        end
      end

      # @return [String] The UUID of the given provisioning profile
      def uuid(path, keychain_path = nil)
        parse(path, keychain_path).fetch("UUID")
      end

      # @return [String] The Name of the given provisioning profile
      def name(path, keychain_path = nil)
        parse(path, keychain_path).fetch("Name")
      end

      def bundle_id(path, keychain_path = nil)
        profile = parse(path, keychain_path)
        app_id_prefix = profile["ApplicationIdentifierPrefix"].first
        entitlements = profile["Entitlements"]
        app_identifier = entitlements["application-identifier"] || entitlements["com.apple.application-identifier"]
        app_identifier.gsub("#{app_id_prefix}.", "")
      rescue
        UI.error("Unable to extract the Bundle Id from the provided provisioning profile '#{path}'.")
      end

      def mac?(path, keychain_path = nil)
        parse(path, keychain_path).fetch("Platform", []).include?('OSX')
      end

      def profile_filename(path, keychain_path = nil)
        basename = uuid(path, keychain_path)
        basename + profile_extension(path, keychain_path)
      end

      def profile_extension(path, keychain_path = nil)
        if mac?(path, keychain_path)
          ".provisionprofile"
        else
          ".mobileprovision"
        end
      end

      def profiles_path
        path = File.expand_path("~") + "/Library/MobileDevice/Provisioning Profiles/"
        # If the directory doesn't exist, create it first
        unless File.directory?(path)
          FileUtils.mkdir_p(path)
        end

        return path
      end

      # Installs a provisioning profile for Xcode to use
      def install(path, keychain_path = nil)
        UI.message("Installing provisioning profile...")
        destination = File.join(profiles_path, profile_filename(path, keychain_path))

        if path != destination
          # copy to Xcode provisioning profile directory
          FileUtils.copy(path, destination)
          unless File.exist?(destination)
            UI.user_error!("Failed installation of provisioning profile at location: '#{destination}'")
          end
        end

        destination
      end

      private

      def decode(path, keychain_path = nil)
        require 'tmpdir'
        Dir.mktmpdir('fastlane') do |dir|
          err = "#{dir}/cms.err"
          # we want to prevent the error output to mix up with the standard output because of
          # /dev/null: https://github.com/fastlane/fastlane/issues/6387
          if Helper.mac?
            if keychain_path.nil?
              decoded = `security cms -D -i "#{path}" 2> #{err}`
            else
              decoded = `security cms -D -i "#{path}" -k "#{keychain_path.shellescape}" 2> #{err}`
            end
          else
            # `security` only works on Mac, fallback to `openssl`
            # via https://stackoverflow.com/a/14379814/252627
            decoded = `openssl smime -inform der -verify -noverify -in #{path.shellescape} 2> #{err}`
          end
          UI.error("Failure to decode #{path}. Exit: #{$?.exitstatus}: #{File.read(err)}") if $?.exitstatus != 0
          decoded
        end
      end
    end
  end
end
