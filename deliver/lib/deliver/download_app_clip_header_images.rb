require_relative 'module'
require 'spaceship'

module Deliver
  class DownloadAppClipHeaderImages
    def self.run(options, path)
      UI.message("Downloading all existing app clip header images...")
      download(options, path)
      UI.success("Successfully downloaded all existing app clip header images")
    rescue => ex
      UI.error(ex)
      UI.error("Couldn't download already existing app clip header images from App Store Connect.")
    end

    def self.download(options, folder_path)
      app = Deliver.cache[:app]

      platform = Spaceship::ConnectAPI::Platform.map(options[:platform])
      if options[:use_live_version]
        version = app.get_live_app_store_version(platform: platform, includes: 'appClipDefaultExperience')
        UI.user_error!("Could not find a live version on App Store Connect. Try using '--use_live_version false'") if version.nil?
      else
        version = app.get_edit_app_store_version(platform: platform, includes: 'appClipDefaultExperience')
        UI.user_error!("Could not find an edit version on App Store Connect. Try using '--use_live_version true'") if version.nil?
      end

      default_experience = version.app_clip_default_experience
      UI.user_error!("Cannot download app clip header images if no default experience exists for version '#{version.version_string}'") unless default_experience

      localizations = Spaceship::ConnectAPI::AppClipDefaultExperienceLocalizations.find_all(app_clip_default_experience_id: default_experience.id, includes: 'appClipHeaderImage')

      threads = []
      localizations.each do |localization|
        threads << Thread.new do
          download_app_clip_header_image(folder_path, localization)
        end
      end
      threads.each(&:join)
    end

    def self.download_app_clip_header_image(folder_path, localization)
      language = localization.locale
      app_clip_header_image = localization.app_clip_header_image

      file_name = app_clip_header_image.file_name
      original_file_extension = File.extname(file_name).strip.downcase[1..-1]

      url = app_clip_header_image.image_asset_url(type: original_file_extension)
      return if url.nil?

      UI.message("Downloading existing app clip header image '#{file_name}' for language '#{language}'")

      containing_folder = File.join(folder_path, language)
      begin
        FileUtils.mkdir_p(containing_folder)
      rescue
        # if it's already there
      end

      path = File.join(containing_folder, file_name)
      File.binwrite(path, FastlaneCore::Helper.open_uri(url).read)
    end
  end
end
