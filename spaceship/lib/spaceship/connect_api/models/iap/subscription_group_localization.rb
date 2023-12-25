require_relative '../../model'
module Spaceship
  class ConnectAPI
    class SubscriptionGroupLocalization
      include Spaceship::ConnectAPI::Model

      attr_accessor :custom_app_name
      attr_accessor :local
      attr_accessor :name
      attr_accessor :state

      module State
        PREPARE_FOR_SUBMISSION = "PREPARE_FOR_SUBMISSION"
        WAITING_FOR_REVIEW = "WAITING_FOR_REVIEW"
        APPROVED = "APPROVED"
        REJECTED = "REJECTED"
      end

      attr_mapping({
        customAppName: 'custom_app_name',
        local: 'local',
        name: 'name',
        state: 'state'
      })

      def self.type
        return 'subscriptionGroupLocalizations'
      end

      def update(custom_app_name:, name:)
        client ||= Spaceship::ConnectAPI
        resps = client.update_subscription_group_localization(custom_app_name: custom_app_name, name: name, localization_id: id)
        return resps.to_models.first
      end
    end
  end
end
