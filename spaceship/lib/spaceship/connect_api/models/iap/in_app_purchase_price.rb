require_relative '../../model'
module Spaceship
  class ConnectAPI
    class InAppPurchasePrice
      include Spaceship::ConnectAPI::Model

      attr_accessor :start_date

      attr_accessor :price_point,
                    :territory

      attr_mapping({
        startDate: 'start_date',
        inAppPurchasePricePoint: 'price_point',
        territory: 'territory'
      })

      def self.type
        return 'inAppPurchasePrices'
      end

      ESSENTIAL_INCLUDES = [
        "inAppPurchasePricePoint",
        "territory"
      ].join(",")

    end
  end
end
