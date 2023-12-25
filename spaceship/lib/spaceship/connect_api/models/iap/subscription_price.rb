require_relative '../../model'
module Spaceship
  class ConnectAPI
    class SubscriptionPrice
      include Spaceship::ConnectAPI::Model

      attr_accessor :preserved
      attr_accessor :start_date

      attr_accessor :subscription_price_point
      attr_accessor :territory

      attr_mapping({
        preserved: 'preserved',
        startDate: 'start_date',

        subscriptionPricePoint: 'subscription_price_point',
        territory: 'territory'
      })

      ESSENTIAL_INCLUDES = [
        "subscriptionPricePoint",
        "territory"
      ].join(",")

      def self.type
        return 'subscriptionPrices'
      end

      def start_date_as_date
        Date.strptime(start_date, "%Y-%m-%d") if start_date
      end

      #
      # Delete
      #

      def delete(client: nil)
        client ||= Spaceship::ConnectAPI
        client.delete_subscription_price(subscription_price_id: id)
      end
    end
  end
end
