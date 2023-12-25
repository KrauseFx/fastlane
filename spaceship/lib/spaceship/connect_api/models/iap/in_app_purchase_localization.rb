require_relative '../../model'
module Spaceship
  class ConnectAPI
    class InAppPurchaseLocalization
      include Spaceship::ConnectAPI::Model

      # Attributes
      attr_accessor :local,
                    :name,
                    :description,
                    :state

      module State
        PREPARE_FOR_SUBMISSION = "PREPARE_FOR_SUBMISSION"
        WAITING_FOR_REVIEW = "WAITING_FOR_REVIEW"
        APPROVED = "APPROVED"
        REJECTED = "REJECTED"
      end

      attr_mapping({
        description: 'description',
        local: 'local',
        name: 'name',
        state: 'state'
      })

      def self.type
        return 'inAppPurchaseLocalizations'
      end

      #
      # Delete
      #

      def delete(client: nil)
        client ||= Spaceship::ConnectAPI
        client.delete_in_app_purchase_localization(localization_id: id)
      end

    end
  end
end
