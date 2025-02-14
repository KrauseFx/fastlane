require "digest/md5"
require 'securerandom'

require_relative 'globals'
require_relative 'ui/ui'
require_relative 'module'

module FastlaneCore
  # Builds a package for the binary ready to be uploaded with the iTunes Transporter
  class IpaUploadPackageBuilder
    METADATA_FILE_NAME = "metadata.xml"

    attr_accessor :package_path

    def generate(app_id: nil, ipa_path: nil, package_path: nil, platform: nil, app_identifier: nil, short_version: nil, bundle_version: nil)
      self.package_path = File.join(package_path, "#{app_id}-#{SecureRandom.uuid}.itmsp")
      FileUtils.rm_rf(self.package_path) if File.directory?(self.package_path)
      FileUtils.mkdir_p(self.package_path)

      ipa_path = copy_ipa(ipa_path)
      @data = {
        apple_id: app_id,
        file_size: File.size(ipa_path),
        ipa_path: File.basename(ipa_path), # this is only the base name as the ipa is inside the package
        md5: Digest::MD5.file(ipa_path).hexdigest,
        archive_type: "bundle",
        platform: (platform || "ios"), # pass "appletvos" for Apple TV's IPA
        app_identifier: app_identifier,
        short_version: short_version,
        bundle_version: bundle_version
      }

      xml_path = File.join(FastlaneCore::ROOT, "lib/assets/XMLTemplate.xml.erb")
      xml = ERB.new(File.read(xml_path)).result(binding) # https://web.archive.org/web/20160430190141/www.rrn.dk/rubys-erb-templating-system

      File.write(File.join(self.package_path, METADATA_FILE_NAME), xml)
      UI.success("Wrote XML data to '#{self.package_path}'") if FastlaneCore::Globals.verbose?

      return self.package_path
    end

    def unique_ipa_path(ipa_path)
      "#{Digest::SHA256.file(ipa_path).hexdigest}.ipa"
    end

    private

    def copy_ipa(ipa_path)
      ipa_file_name = unique_ipa_path(ipa_path)
      resulting_path = File.join(self.package_path, ipa_file_name)
      FileUtils.cp(ipa_path, resulting_path)

      return resulting_path
    end
  end
end
