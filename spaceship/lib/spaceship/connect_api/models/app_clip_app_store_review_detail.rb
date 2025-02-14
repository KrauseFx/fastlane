require_relative '../model'
module Spaceship
  class ConnectAPI
    class AppClipAppStoreReviewDetail
      include Spaceship::ConnectAPI::Model

      attr_accessor :invocation_urls

      attr_mapping(
        'invocationUrls' => 'invocation_urls'
      )

      def self.type
        'appClipAppStoreReviewDetails'
      end

      #
      # API
      #

      def self.create(client: nil, app_clip_default_experience_id:, attributes:)
        client ||= Spaceship::ConnectAPI
        attributes = reverse_attr_mapping(attributes)
        return client.post_app_clip_app_store_review_detail(app_clip_default_experience_id: app_clip_default_experience_id, attributes: attributes)
      end

      def update(client: nil, attributes: nil)
        client ||= Spaceship::ConnectAPI
        attributes = reverse_attr_mapping(attributes)
        return client.patch_app_clip_app_store_review_detail(app_clip_app_store_review_detail_id: id, attributes: attributes)
      end
    end
  end
end
