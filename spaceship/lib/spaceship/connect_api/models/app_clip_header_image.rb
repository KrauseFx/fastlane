require_relative '../model'
require_relative '../file_uploader'
require 'spaceship/globals'

require 'digest/md5'

module Spaceship
  class ConnectAPI
    class AppClipHeaderImage
      include Spaceship::ConnectAPI::Model

      # Much of the functionality below is modified from `spaceship/connect_api/models/app_screenshot.rb`

      attr_accessor :file_size
      attr_accessor :file_name
      attr_accessor :source_file_checksum
      attr_accessor :image_asset
      attr_accessor :asset_token
      attr_accessor :asset_type
      attr_accessor :upload_operations
      attr_accessor :asset_delivery_state
      attr_accessor :uploaded

      attr_mapping({
        "fileSize" => "file_size",
        "fileName" => "file_name",
        "sourceFileChecksum" => "source_file_checksum",
        "imageAsset" => "image_asset",
        "assetToken" => "asset_token",
        "assetType" => "asset_type",
        "uploadOperations" => "upload_operations",
        "assetDeliveryState" => "asset_delivery_state",
        "uploaded" => "uploaded"
      })

      def self.type
        'appClipHeaderImages'
      end

      def awaiting_upload?
        (asset_delivery_state || {})["state"] == "AWAITING_UPLOAD"
      end

      def complete?
        (asset_delivery_state || {})["state"] == "COMPLETE"
      end

      def error?
        (asset_delivery_state || {})["state"] == "FAILED"
      end

      def error_messages
        errors = (asset_delivery_state || {})["errors"]
        (errors || []).map do |error|
          [error["code"], error["description"]].compact.join(" - ")
        end
      end

      # This does not download the source image (exact image that was uploaded)
      # This downloads a modified version.
      # This image won't have the same checksums as source_file_checksum.
      #
      # There is an open radar for allowing downloading of source file.
      # https://openradar.appspot.com/radar?id=4980344105205760
      def image_asset_url(width: nil, height: nil, type: "png")
        return nil if image_asset.nil?

        template_url = image_asset["templateUrl"]
        width ||= image_asset["width"]
        height ||= image_asset["height"]

        return template_url
               .gsub("{w}", width.to_s)
               .gsub("{h}", height.to_s)
               .gsub("{f}", type)
      end

      #
      # API
      #

      def self.create(client: nil, app_clip_default_experience_localization_id: nil, path: nil, wait_for_processing: true)
        client ||= Spaceship::ConnectAPI
        require 'faraday'

        filename = File.basename(path)
        filesize = File.size(path)
        bytes = File.binread(path)

        post_attributes = {
          fileSize: filesize,
          fileName: filename
        }

        # Create placeholder to upload the app clip header image
        begin
          app_clip_header_image = client.post_app_clip_header_image(
            app_clip_default_experience_localization_id: app_clip_default_experience_localization_id,
            attributes: post_attributes
          ).first
        rescue => error
          puts("ERROR: Unable to create app clip header image reservation, error: #{error}")
        end

        # Upload the file
        upload_operations = app_clip_header_image.upload_operations
        Spaceship::ConnectAPI::FileUploader.upload(upload_operations, bytes)

        # Update file uploading complete
        patch_attributes = {
          uploaded: true,
          sourceFileChecksum: Digest::MD5.hexdigest(bytes)
        }

        # Patch app clip header image that file upload is complete
        # Catch error if patch retries due to 504. Origal patch
        # may go through by return response as 504.
        begin
          app_clip_header_image = Spaceship::ConnectAPI.patch_app_clip_header_image(
            app_clip_header_image_id: app_clip_header_image.id,
            attributes: patch_attributes
          ).first
        rescue => error
          puts("Failed to patch app clip header image. Update may have gone through so verifying") if Spaceship::Globals.verbose?

          app_clip_header_image = client.get_app_clip_header_image(app_clip_header_image_id: app_clip_header_image.id).first
          raise error unless app_clip_header_image.complete?
        end

        # Wait for processing
        if wait_for_processing
          loop do
            if app_clip_header_image.complete?
              puts("App clip header image processing complete!") if Spaceship::Globals.verbose?
              break
            elsif app_clip_header_image.error?
              messages = ["Error processing app clip header image '#{app_clip_header_image.file_name}'"] + app_clip_header_image.error_messages
              raise messages.join(". ")
            end

            # Poll every 2 seconds
            sleep_time = 2
            puts("Waiting #{sleep_time} seconds before checking status of processing...") if Spaceship::Globals.verbose?
            sleep(sleep_time)

            app_clip_header_image = client.get_app_clip_header_image(app_clip_header_image_id: app_clip_header_image.id).first
          end
        end

        return app_clip_header_image
      end

      def delete!(client: nil, filter: {}, includes: nil, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        client.delete_app_clip_header_image(app_clip_header_image_id: id)
      end
    end
  end
end
