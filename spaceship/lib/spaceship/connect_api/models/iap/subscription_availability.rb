require_relative '../../model'
module Spaceship
  class ConnectAPI
    class SubscriptionAvailability
      include Spaceship::ConnectAPI::Model

      attr_accessor :available_in_new_territories

      attr_accessor :available_territories
      attr_accessor :subscription

      attr_mapping({
        available_in_new_territories: 'availableInNewTerritories',

        available_territories: 'availableTerritories',
        subscription: 'subscription'
      })

      ESSENTIAL_INCLUDES = [
        "availableTerritories",
      ].join(",")

      def self.type
        return 'subscriptionAvailabilities'
      end
    end
  end
end
