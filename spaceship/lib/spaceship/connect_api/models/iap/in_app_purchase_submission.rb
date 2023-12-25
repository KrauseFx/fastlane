require_relative '../../model'
module Spaceship
  class ConnectAPI

    # This model serves to inflate the included in-app purchase. It contains not data itself.
    class InAppPurchaseSubmission
      include Spaceship::ConnectAPI::Model

      attr_accessor :in_app_purchase

      attr_mapping({
        inAppPurchaseV2: 'in_app_purchase'
      })

      def self.type
        return 'inAppPurchaseSubmissions'
      end

    end
  end
end
