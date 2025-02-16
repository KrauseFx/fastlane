require 'fastlane_core/provisioning_profile'

require_relative 'runner'

module Sigh
  class Manager
    def self.start
      path = Sigh::Runner.new.run

      return nil unless path

      if Sigh.config[:filename]
        file_name = Sigh.config[:filename]
      else
        file_name = File.basename(path)
      end

      FileUtils.mkdir_p(Sigh.config[:output_path])
      output = File.join(File.expand_path(Sigh.config[:output_path]), file_name)
      begin
        FileUtils.mv(path, output)
      rescue
        # in case it already exists
      end

      install_profile(output) unless Sigh.config[:skip_install]

      puts(output.green)

      return File.expand_path(output)
    end

    def self.download_all(download_xcode_profiles: false)
      require 'sigh/download_all'
      DownloadAll.new.download_all(download_xcode_profiles: download_xcode_profiles)
    end

    def self.install_profile(profile, keychain_path = nil)
      uuid = FastlaneCore::ProvisioningProfile.uuid(profile, keychain_path)
      name = FastlaneCore::ProvisioningProfile.name(profile, keychain_path)
      ENV["SIGH_UDID"] = ENV["SIGH_UUID"] = uuid if uuid
      ENV["SIGH_NAME"] = name if name

      FastlaneCore::ProvisioningProfile.install(profile, keychain_path)
    end
  end
end
