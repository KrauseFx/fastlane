require_relative '../../model'
module Spaceship
  class ConnectAPI
    class SubscriptionPricePoint
      include Spaceship::ConnectAPI::Model

      attr_accessor :customer_price
      attr_accessor :proceeds
      attr_accessor :proceeds_year2

      attr_accessor :territory

      attr_mapping({
        customerPrice: 'customer_price',
        proceeds: 'proceeds',
        proceedsYear2: 'proceeds_year2',
      })

      def self.type
        return 'subscriptionPricePoints'
      end

      ESSENTIAL_INCLUDES = [
        "territory"
      ].join(",")

      #
      # Price Point Equalizations
      #

      def get_equalization_price_points(client: nil, filter: nil, includes: ESSENTIAL_INCLUDES, limit: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_subscription_price_point_equalizations(price_point_id: id, filter: filter, includes: includes, limit: limit).all_pages
        resps.flat_map(&:to_models)
      end

    end
  end
end
