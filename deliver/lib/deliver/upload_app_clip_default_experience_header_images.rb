require 'fastlane_core'
require 'spaceship/tunes/tunes'
require 'digest/md5'

require_relative 'module'
require_relative 'loader'

module Deliver
  class UploadAppClipDefaultExperienceHeaderImages
    UploadAppClipHeaderImageJob = Struct.new(:path, :localization)

    def find_and_upload(options)
      return if options[:edit_live] || options[:app_clip_header_images_path].nil?

      app_clip_header_images = collect_app_clip_header_images(options)

      app = Deliver.cache[:app]

      platform = Spaceship::ConnectAPI::Platform.map(options[:platform])
      version = app.get_edit_app_store_version(platform: platform, includes: 'appClipDefaultExperience')
      UI.user_error!("Could not find a version to edit for app '#{app.name}' for '#{platform}'") unless version

      app_clip_default_experience = version.app_clip_default_experience
      UI.user_error!("Could not find a default app clip experience for version '#{version}'. Use the :app_clip_default_experience_subtitle and :app_clip_default_experience_action options to create and add metadata to the app clip default experience for this version.") unless app_clip_default_experience

      UI.important("Will begin uploading app clip default experience header images for '#{version.version_string}' on App Store Connect")
      UI.message("Starting with the upload of app clip header images...")

      localizations = version.get_app_store_version_localizations

      upload(app_clip_default_experience, localizations, app_clip_header_images)

      UI.success("Successfully uploaded app clip default experience header images to App Store Connect")
    end

    def upload(app_clip_default_experience, localizations, app_clip_header_images)
      # get the existing localizations and their header images
      app_clip_default_experience_localizations = Spaceship::ConnectAPI::AppClipDefaultExperienceLocalizations.find_all(app_clip_default_experience_id: app_clip_default_experience.id, includes: 'appClipHeaderImage')

      # Upload app clip header images
      worker = FastlaneCore::QueueWorker.new do |job|
        begin
          localization = job.localization

          # if there's an existing header image, it must be deleted before uploading the new one
          unless localization.app_clip_header_image.nil?
            localization.app_clip_header_image.delete
            UI.verbose("[#{localization.locale}] Removed existing header image")
          end

          UI.verbose("[#{localization.locale}] Uploading '#{job.path}'...")
          start_time = Time.now
          Spaceship::ConnectAPI::AppClipHeaderImage.create(app_clip_default_experience_localization_id: localization.id, path: job.path, wait_for_processing: false)
          UI.message("Uploaded '#{job.path}'... (#{Time.now - start_time} secs)")
        rescue => error
          UI.error(error)
        end
      end

      app_clip_header_images.each do |header_image|
        localization = app_clip_default_experience_localizations.find { |l| l.locale.eql?(header_image.language) }
        UI.error("Could not find existing localization for #{header_image.langauge}") unless localization

        # check to see if it's already uploaded
        checksum = UploadAppClipDefaultExperienceHeaderImages.calculate_checksum(header_image.path)
        if !localization.app_clip_header_image.nil? && checksum.eql?(localization.app_clip_header_image.source_file_checksum)
          UI.message("Skipping '#{header_image.path}' as it is already uploaded")
          next
        end

        # upload
        UI.verbose("Queued upload app clip header image job for #{localization.locale} '#{header_image.path}'")
        worker.enqueue(UploadAppClipHeaderImageJob.new(header_image.path, localization))
      end

      worker.start

      UI.verbose('Uploading jobs are completed')

      Helper.show_loading_indicator("Waiting for all the app clip header images to finish being processed...")
      wait_for_complete(app_clip_default_experience.id)
      Helper.hide_loading_indicator

      UI.message("Successfully uploaded all app clip header images")
    end

    # Verify all screenshots have been processed
    # Functionality copied and modified from upload_screenshots.rb
    def wait_for_complete(app_clip_default_experience_id)
      loop do
        # fetch
        app_clip_default_experience_localizations = Spaceship::ConnectAPI::AppClipDefaultExperienceLocalizations.find_all(app_clip_default_experience_id: app_clip_default_experience_id, includes: 'appClipHeaderImage')
        header_images = app_clip_default_experience_localizations.map(&:app_clip_header_image)

        # group states
        states = header_images.each_with_object({}) do |header_image, hash|
          next unless header_image

          state = header_image.asset_delivery_state['state']
          hash[state] ||= 0
          hash[state] += 1
        end

        is_processing = states.fetch('UPLOAD_COMPLETE', 0) > 0
        return states unless is_processing

        UI.verbose("There are still incomplete app clip header images - #{states}")
        sleep(5)
      end
    end

    def collect_app_clip_header_images(options)
      return Loader.load_app_clip_header_images(options[:app_clip_header_images_path], options[:ignore_language_directory_validation])
    end

    # helper method to mock this step in tests
    def self.calculate_checksum(path)
      bytes = File.binread(path)
      Digest::MD5.hexdigest(bytes)
    end
  end
end
