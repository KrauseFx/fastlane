require_relative '../model'
module Spaceship
  class ConnectAPI
    class BetaAppClipInvocation
      include Spaceship::ConnectAPI::Model

      attr_accessor :url
      attr_accessor :beta_app_clip_invocation_localizations

      attr_mapping(
        'url' => 'url',
        'betaAppClipInvocationLocalizations' => 'beta_app_clip_invocation_localizations'
      )

      ESSENTIAL_INCLUDES = [
        "betaAppClipInvocationLocalizations"
      ].join(",")

      def self.type
        'betaAppClipInvocations'
      end

      #
      # API
      #

      def self.create(client: nil, build_bundle_id:, attributes:, localized_titles:)
        client ||= Spaceship::ConnectAPI
        return client.post_beta_app_clip_invocations(build_bundle_id: build_bundle_id, attributes: attributes, localized_titles: localized_titles)
      end

      def self.find_all(client: nil, build_bundle_id:, filter: {}, includes: ESSENTIAL_INCLUDES, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_build_bundles_beta_app_clip_invocations(build_bundle_id: build_bundle_id, filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        return resps.flat_map(&:to_models)
      end

      def delete(client: nil)
        client ||= Spaceship::ConnectAPI
        client.delete_beta_app_clip_invocation(beta_app_clip_invocation_id: id)
      end
    end
  end
end
