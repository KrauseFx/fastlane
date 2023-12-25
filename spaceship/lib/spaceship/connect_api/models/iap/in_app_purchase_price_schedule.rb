require_relative '../../model'
module Spaceship
  class ConnectAPI
    class InAppPurchasePriceSchedule
      include Spaceship::ConnectAPI::Model

      # Realtionships
      attr_accessor :prices

      attr_mapping({
        manualPrices: 'prices'
      })

      def self.type
        return 'inAppPurchasePriceSchedules'
      end

      ESSENTIAL_INCLUDES = [
        "manualPrices"
      ].join(",")

    end
  end
end
