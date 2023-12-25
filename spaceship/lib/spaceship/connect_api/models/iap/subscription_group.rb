require_relative '../../model'
module Spaceship
  class ConnectAPI
    class SubscriptionGroup
      include Spaceship::ConnectAPI::Model

      attr_accessor :reference_name

      attr_accessor :subscriptions,
                    :subscription_group_localizations

      attr_mapping({
        referenceName: 'reference_name',

        subscriptions: 'subscriptions'
      })

      ESSENTIAL_INCLUDES = [
        "subscriptions"
      ].join(",")

      def self.type
        return 'subscriptionGroups'
      end

      #
      # Delete
      #

      def delete(client: nil)
        client ||= Spaceship::ConnectAPI
        client.delete_subscription_group(family_id: id)
      end

      #
      # Subscription Group Localizations
      #

      def get_subscription_group_localization(client: nil, localization_id:, includes: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_subscription_group_localization(localization_id: localization_id, includes: includes)
        return resps.to_models.first
      end

      def get_subscription_group_localizations(client: nil, includes: nil, limit: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_subscription_group_localizations(family_id: id, includes: includes, limit: limit).all_pages
        return resps.flat_map(&:to_models)
      end

      def create_subscription_group_localization(client: nil, custom_app_name:, locale:, name:)
        client ||= Spaceship::ConnectAPI
        resps = client.create_subscription_group_localization(custom_app_name: custom_app_name, locale: locale, name: name, family_id: id)
        return resps.to_models.first
      end

      #
      # Subscriptions
      #

      def get_subscription(client: nil, purchase_id:, includes: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_subscription(purchase_id: purchase_id, includes: includes)
        return resps.to_models.first
      end

      def get_subscriptions(client: nil, filter: nil, includes: nil, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_subscriptions(family_id: id, filter: filter, includes: includes, limit: limit, sort: sort)
        return resps.flat_map(&:to_models)
      end

      def create_subscription(client: nil, name:, product_id:, available_in_all_territories: nil, family_sharable: nil, review_note: nil, subscription_period: nil, group_level: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.create_subscription(family_id: id, name: name, product_id: product_id, available_in_all_territories: available_in_all_territories, family_sharable: family_sharable, review_note: review_note, subscription_period: subscription_period, group_level: group_level)
        return resps.to_models.first
      end

    end
  end
end
