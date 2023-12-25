require_relative '../../model'
module Spaceship
  class ConnectAPI
    class SubscriptionLocalization
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
        return 'subscriptionLocalizations'
      end

      #
      # Delete
      #

      def delete(client: nil)
        client ||= Spaceship::ConnectAPI
        client.delete_subscription_localization(localization_id: id)
      end

    end
  end
end
