require_relative '../model'
module Spaceship
  class ConnectAPI
    class BetaGroup
      include Spaceship::ConnectAPI::Model

      attr_accessor :name
      attr_accessor :created_date
      attr_accessor :is_internal_group
      attr_accessor :public_link_enabled
      attr_accessor :public_link_id
      attr_accessor :public_link_limit_enabled
      attr_accessor :public_link_limit
      attr_accessor :public_link

      attr_mapping({
        "name" => "name",
        "createdDate" => "created_date",
        "isInternalGroup" => "is_internal_group",
        "publicLinkEnabled" => "public_link_enabled",
        "publicLinkId" => "public_link_id",
        "publicLinkLimitEnabled" => "public_link_limit_enabled",
        "publicLinkLimit" => "public_link_limit",
        "publicLink" => "public_link"
      })

      def self.type
        return "betaGroups"
      end

      #
      # API
      #

      # beta_testers - [{email: "", firstName: "", lastName: ""}]
      def post_bulk_beta_tester_assignments(client: nil, beta_testers: nil)
        client ||= Spaceship::ConnectAPI
        return client.post_bulk_beta_tester_assignments(beta_group_id: id, beta_testers: beta_testers)
      end

      def add_beta_testers(beta_tester_ids:, client: nil)
        client ||= Spaceship::ConnectAPI
        return client.add_beta_tester_to_group(beta_group_id: id, beta_tester_ids: beta_tester_ids)
      end

      def update(client: nil, attributes: nil)
        return if attributes.empty?

        client ||= Spaceship::ConnectAPI

        attributes = reverse_attr_mapping(attributes)
        return client.patch_group(group_id: id, attributes: attributes).first
      end

      def delete!
        return Spaceship::ConnectAPI.delete_beta_group(group_id: id)
      end

      def fetch_builds
        resps = Spaceship::ConnectAPI.get_builds_for_beta_group(group_id: id).all_pages
        return resps.flat_map(&:to_models)
      end
    end
  end
end
