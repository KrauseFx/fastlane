require_relative '../../model'
module Spaceship
  class ConnectAPI

    # This model serves to inflate the included subscription. It contains not data itself.
    class SubscriptionSubmission
      include Spaceship::ConnectAPI::Model

      attr_accessor :subscription

      attr_mapping({
        subscription: 'subscription'
      })

      def self.type
        return 'subscriptionSubmissions'
      end

    end
  end
end
