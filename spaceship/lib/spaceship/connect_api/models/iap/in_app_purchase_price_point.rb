require_relative '../../model'
module Spaceship
  class ConnectAPI
    class InAppPurchasePricePoint
      include Spaceship::ConnectAPI::Model

      attr_accessor :customer_price,
                    :proceeds,
                    :price_tier

      attr_accessor :territory

      attr_mapping({
        customerPrice: 'customer_price',
        proceeds: 'proceeds',
        priceTier: 'price_tier',
      })

      def self.type
        return 'inAppPurchasePricePoints'
      end

      ESSENTIAL_INCLUDES = [
        "territory"
      ].join(",")

    end
  end
end
