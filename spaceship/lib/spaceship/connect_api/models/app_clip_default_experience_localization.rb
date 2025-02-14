require_relative '../model'
module Spaceship
  class ConnectAPI
    class AppClipDefaultExperienceLocalizations
      include Spaceship::ConnectAPI::Model

      attr_accessor :locale
      attr_accessor :subtitle
      attr_accessor :app_clip_header_image

      attr_mapping(
        'locale' => 'locale',
        'subtitle' => 'subtitle',
        'appClipHeaderImage' => 'app_clip_header_image'
      )

      def self.type
        'appClipDefaultExperienceLocalizations'
      end

      #
      # API
      #

      def self.create(client: nil, default_experience_id:, attributes:)
        client ||= Spaceship::ConnectAPI
        return client.post_app_clip_default_experience_localization(default_experience_id: default_experience_id, attributes: attributes)
      end

      def self.find_all(client: nil, app_clip_default_experience_id:, filter: {}, includes: nil, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_app_clip_default_experience_localizations(app_clip_default_experience_id: app_clip_default_experience_id, filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        return resps.flat_map(&:to_models)
      end

      def get_header_image(client: nil, filter: {}, includes: nil, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_app_clip_default_experience_header_image(app_clip_default_experience_localization_id: id, filter: filter, includes: includes, limit: limit, sort: sort)
        return resps.flat_map(&:to_models)
      end

      def update(client: nil, attributes: nil)
        client ||= Spaceship::ConnectAPI
        attributes = reverse_attr_mapping(attributes)
        return client.patch_app_clip_default_experience_localization(app_clip_default_experience_localization_id: id, attributes: attributes)
      end
    end
  end
end
