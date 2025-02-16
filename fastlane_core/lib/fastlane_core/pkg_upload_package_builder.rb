require 'digest/md5'
require 'securerandom'

require_relative 'globals'
require_relative 'ui/ui'
require_relative 'module'

module FastlaneCore
  # Builds a package for the pkg ready to be uploaded with the iTunes Transporter
  class PkgUploadPackageBuilder
    METADATA_FILE_NAME = 'metadata.xml'

    attr_accessor :package_path

    def generate(app_id: nil, pkg_path: nil, package_path: nil, platform: "osx")
      self.package_path = File.join(package_path, "#{app_id}-#{SecureRandom.uuid}.itmsp")
      FileUtils.rm_rf(self.package_path) if File.directory?(self.package_path)
      FileUtils.mkdir_p(self.package_path)

      pkg_path = copy_pkg(pkg_path)
      @data = {
        apple_id: app_id,
        file_size: File.size(pkg_path),
        ipa_path: File.basename(pkg_path), # this is only the base name as the ipa is inside the package
        md5: calculate_md5(pkg_path),
        archive_type: 'product-archive',
        platform: platform
      }

      xml_path = File.join(FastlaneCore::ROOT, 'lib/assets/XMLTemplate.xml.erb')
      xml = ERB.new(File.read(xml_path)).result(binding) # https://web.archive.org/web/20160430190141/www.rrn.dk/rubys-erb-templating-system

      File.write(File.join(self.package_path, METADATA_FILE_NAME), xml)
      UI.success("Wrote XML data to '#{self.package_path}'") if FastlaneCore::Globals.verbose?

      return self.package_path
    end

    private

    def copy_pkg(pkg_path)
      ipa_file_name = Digest::MD5.hexdigest(pkg_path)
      resulting_path = File.join(self.package_path, "#{ipa_file_name}.pkg")

      begin
        File.open(pkg_path, 'rb') do |src|
          File.open(resulting_path, 'wb') do |dst|
            while (buffer = src.read(1024 * 1024)) do
              dst.write(buffer)
            end
          end
        end
        return resulting_path
      rescue StandardError => e
        UI.user_error!("Error copying file '#{pkg_path}' to '#{resulting_path}': #{e.message}")
      end
    end

    def calculate_md5(file_path)
      begin
        md5 = Digest::MD5.new
        File.open(file_path, 'rb') do |file|
          while (buffer = file.read(1024 * 1024)) do
            md5.update(buffer)
          end
        end
        return md5.hexdigest
      rescue StandardError => e
        UI.user_error!("Error reading file '#{file_path}': #{e.message}")
      end
    end
  end
end
