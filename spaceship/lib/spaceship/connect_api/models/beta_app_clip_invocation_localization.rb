require_relative '../model'
module Spaceship
  class ConnectAPI
    class BetaAppClipInvocationLocalization
      include Spaceship::ConnectAPI::Model

      attr_accessor :locale
      attr_accessor :title

      attr_mapping(
        'locale' => 'locale',
        'title' => 'title'
      )

      def self.type
        'betaAppClipInvocationLocalizations'
      end

      #
      # API
      #

      def self.create(client: nil, beta_app_clip_invocation_id:, attributes:)
        client ||= Spaceship::ConnectAPI
        return client.post_beta_app_clip_invocation_localization(beta_app_clip_invocation_id: beta_app_clip_invocation_id, attributes: attributes)
      end

      def update(client: nil, attributes:)
        client ||= Spaceship::ConnectAPI
        resps = client.patch_beta_app_clip_invocation_localization(beta_app_clip_invocation_localization_id: id, attributes: attributes).all_pages
        return resps.flat_map(&:to_models)
      end
    end
  end
end
