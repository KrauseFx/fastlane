require 'spaceship/tunes/tunes'

require_relative 'module'
require_relative 'download_screenshots'
require_relative 'upload_metadata'

module Deliver
  class Setup
    attr_accessor :is_swift

    def run(options, is_swift: false)
      containing = Helper.fastlane_enabled_folder_path
      self.is_swift = is_swift

      if is_swift
        file_path = File.join(containing, 'Deliverfile.swift')
      else
        file_path = File.join(containing, 'Deliverfile')
      end
      data = generate_deliver_file(containing, options)
      setup_deliver(file_path, data, containing, options)
    end

    def setup_deliver(file_path, data, deliver_path, options)
      File.write(file_path, data)

      screenshots_path = options[:screenshots_path] || File.join(deliver_path, 'screenshots')
      unless options[:skip_screenshots]
        download_screenshots(screenshots_path, options)

        # Add a README to the screenshots folder
        FileUtils.mkdir_p(screenshots_path) # just in case the fetching didn't work
        File.write(File.join(screenshots_path, 'README.txt'), File.read("#{Deliver::ROOT}/lib/assets/ScreenshotsHelp"))
      end

      UI.success("Successfully created new Deliverfile at path '#{file_path}'")
    end

    # This method takes care of creating a new 'deliver' folder, containing the app metadata
    # and screenshots folders
    def generate_deliver_file(deliver_path, options)
      app = options[:app]

      platform = Spaceship::ConnectAPI::Platform.map(options[:platform])
      v = app.get_latest_app_store_version(platform: platform)

      metadata_path = options[:metadata_path] || File.join(deliver_path, 'metadata')
      generate_metadata_files(app, v, metadata_path, options)

      # Generate the final Deliverfile here
      return File.read(deliverfile_path)
    end

    def deliverfile_path
      if self.is_swift
        return "#{Deliver::ROOT}/lib/assets/DeliverfileDefault.swift"
      else
        return "#{Deliver::ROOT}/lib/assets/DeliverfileDefault"
      end
    end

    def generate_metadata_files(app, version, path, options)
      # App info localizations
      if options[:use_live_version]
        app_info = app.fetch_live_app_info
        UI.user_error!("The option `use_live_version` was set to `true`, however no live app was found on App Store Connect.") unless app_info
      else
        app_info = app.fetch_edit_app_info || app.fetch_live_app_info
      end
      app_info_localizations = app_info.get_app_info_localizations
      app_info_localizations.each do |localization|
        language = localization.locale

        UploadMetadata::LOCALISED_APP_VALUES.each do |file_key, attribute_name|
          content = localization.send(attribute_name.to_slug) || ""
          content += "\n"

          resulting_path = File.join(path, language, "#{file_key}.txt")
          FileUtils.mkdir_p(File.expand_path('..', resulting_path))
          File.write(resulting_path, content)

          UI.message("Writing to '#{resulting_path}'")
        end
      end

      # Version localizations
      version_localizations = version.get_app_store_version_localizations
      version_localizations.each do |localization|
        language = localization.locale

        UploadMetadata::LOCALISED_VERSION_VALUES.each do |file_key, attribute_name|
          content = localization.send(attribute_name) || ""
          content += "\n"

          resulting_path = File.join(path, language, "#{file_key}.txt")
          FileUtils.mkdir_p(File.expand_path('..', resulting_path))
          File.write(resulting_path, content)

          UI.message("Writing to '#{resulting_path}'")
        end
      end

      # App info (categories)
      UploadMetadata::NON_LOCALISED_APP_VALUES.each do |file_key, attribute_name|
        category = app_info.send(attribute_name)

        content = category ? category.id.to_s : ""
        content += "\n"

        resulting_path = File.join(path, "#{file_key}.txt")
        FileUtils.mkdir_p(File.expand_path('..', resulting_path))
        File.write(resulting_path, content)

        UI.message("Writing to '#{resulting_path}'")
      end

      # Version
      UploadMetadata::NON_LOCALISED_VERSION_VALUES.each do |file_key, attribute_name|
        content = version.send(attribute_name) || ""
        content += "\n"

        resulting_path = File.join(path, "#{file_key}.txt")
        FileUtils.mkdir_p(File.expand_path('..', resulting_path))
        File.write(resulting_path, content)

        UI.message("Writing to '#{resulting_path}'")
      end

      # Review information
      app_store_review_detail = begin
                                  version.fetch_app_store_review_detail
                                rescue
                                  nil
                                end
      UploadMetadata::REVIEW_INFORMATION_VALUES.each do |file_key, attribute_name|
        if app_store_review_detail
          content = app_store_review_detail.send(attribute_name) || ""
        else
          content = ""
        end
        content += "\n"

        base_dir = File.join(path, UploadMetadata::REVIEW_INFORMATION_DIR)
        resulting_path = File.join(base_dir, "#{file_key}.txt")
        FileUtils.mkdir_p(File.expand_path('..', resulting_path))
        File.write(resulting_path, content)

        UI.message("Writing to '#{resulting_path}'")
      end
    end

    def generate_metadata_files_old(v, path)
      app_details = v.application.details

      # All the localised metadata
      (UploadMetadata::LOCALISED_VERSION_VALUES.keys + UploadMetadata::LOCALISED_APP_VALUES.keys).each do |key|
        v.description.languages.each do |language|
          if UploadMetadata::LOCALISED_VERSION_VALUES.keys.include?(key)
            content = v.send(key)[language].to_s
          else
            content = app_details.send(key)[language].to_s
          end
          content += "\n"
          resulting_path = File.join(path, language, "#{key}.txt")
          FileUtils.mkdir_p(File.expand_path('..', resulting_path))
          File.write(resulting_path, content)
          UI.message("Writing to '#{resulting_path}'")
        end
      end

      # All non-localised metadata
      (UploadMetadata::NON_LOCALISED_VERSION_VALUES.keys + UploadMetadata::NON_LOCALISED_APP_VALUES).each do |key|
        if UploadMetadata::NON_LOCALISED_VERSION_VALUES.keys.include?(key)
          content = v.send(key).to_s
        else
          content = app_details.send(key).to_s
        end
        content += "\n"
        resulting_path = File.join(path, "#{key}.txt")
        File.write(resulting_path, content)
        UI.message("Writing to '#{resulting_path}'")
      end

      # Review information
      UploadMetadata::REVIEW_INFORMATION_VALUES_LEGACY.each do |key, option_name|
        content = v.send(key).to_s
        content += "\n"
        base_dir = File.join(path, UploadMetadata::REVIEW_INFORMATION_DIR)
        FileUtils.mkdir_p(base_dir)
        resulting_path = File.join(base_dir, "#{option_name}.txt")
        File.write(resulting_path, content)
        UI.message("Writing to '#{resulting_path}'")
      end

      UI.success("Successfully created new configuration files.")
    end

    def download_screenshots(path, options)
      FileUtils.mkdir_p(path)
      Deliver::DownloadScreenshots.run(options, path)
    end
  end
end
