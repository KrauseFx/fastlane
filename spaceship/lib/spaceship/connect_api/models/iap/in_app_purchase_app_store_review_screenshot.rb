require_relative '../../model'
module Spaceship
  class ConnectAPI
    class InAppPurchaseAppStoreReviewScreenshot
      include Spaceship::ConnectAPI::Model

      attr_accessor :asset_delivery_state,
                    :asset_token,
                    :asset_type,
                    :file_name,
                    :file_size,
                    :image_asset,
                    :source_file_checksum,
                    :upload_operations

      module State
        AWAITING_UPLOAD = "AWAITING_UPLOAD"
        UPLOAD_COMPLETE = "UPLOAD_COMPLETE"
        COMPLETE = "COMPLETE"
        FAILED = "FAILED"
      end

      attr_mapping({
        fileSize: 'file_size',
        fileName: 'file_name',
        sourceFileChecksum: 'source_file_checksum',
        imageAsset: 'image_asset',
        assetToken: 'asset_token',
        assetType: 'asset_type',
        uploadOperations: 'upload_operations',
        assetDeliveryState: 'asset_delivery_state'
      })

      def self.type
        return 'inAppPurchaseAppStoreReviewScreenshots'
      end

      def awaiting_upload?
        !!asset_delivery_state && (asset_delivery_state['state'] == State::AWAITING_UPLOAD)
      end

      def upload_complete?
        !!asset_delivery_state && (asset_delivery_state['state'] == State::UPLOAD_COMPLETE)
      end

      def complete?
        !!asset_delivery_state && (asset_delivery_state['state'] == State::COMPLETE)
      end

      def failed?
        !!asset_delivery_state && (asset_delivery_state['state'] == State::FAILED)
      end

      #
      # Upload Image
      #

      def upload_image(client: nil, path: nil, bytes: nil)
        client ||= Spaceship::ConnectAPI
        raise 'path or bytes required' if path.nil? && bytes.nil?
        bytes ||= File.binread(path)
        Spaceship::ConnectAPI::FileUploader.upload(upload_operations, bytes)
      end

      def update(client: nil, source_file_checksum:, uploaded:)
        client ||= Spaceship::ConnectAPI
        resp = client.update_in_app_purchase_app_store_review_screenshot(screenshot_id: id, source_file_checksum: source_file_checksum, uploaded: uploaded)
        resp.to_models.first # self
      end

      def delete(client: nil)
        client ||= Spaceship::ConnectAPI
        client.delete_in_app_purchase_app_store_review_screenshot(screenshot_id: id)
      end
    end
  end
end
