
module Spaceship
  module Tunes
    class IAPList < TunesBase
      # @return (Spaceship::Tunes::Application) A reference to the application
      attr_accessor :application

      # @return (String) the IAP Referencename
      attr_accessor :reference_name

      # @return (String) the IAP Product-Id
      attr_accessor :product_id

      # @return (String) Family Reference Name
      attr_accessor :family_reference_name

      attr_accessor :duration_days
      attr_accessor :versions
      attr_accessor :purple_apple_id
      attr_accessor :last_modfied_date
      attr_accessor :is_news_subscription
      attr_accessor :number_of_codes
      attr_accessor :maximum_number_of_codes
      attr_accessor :app_maximum_number_of_codes
      attr_accessor :is_editable
      attr_accessor :is_required
      attr_accessor :can_delete_addon

      attr_accessor :status_raw
      attr_accessor :status

      attr_accessor :type
      attr_accessor :type_raw

      attr_mapping({
        'adamId' => :purchase_id,
        'referenceName' => :reference_name,
        'familyReferenceName' => :family_reference_name,
        'vendorId' => :product_id,
        'addOnType' => :type_raw,
        'durationDays' => :duration_days,
        'versions' => :versions,
        'purpleSoftwareAdamIds' => :purple_apple_id,
        'lastModifiedDate' => :last_modfied_date,
        'isNewsSubscription' => :is_news_subscription,
        'numberOfCodes' => :number_of_codes,
        'maximumNumberOfCodes' => :maximum_number_of_codes,
        'appMaximumNumberOfCodes' => :app_maximum_number_of_codes,
        'isEditable' => :is_editable,
        'isRequired' => :is_required,
        'canDeleteAddOn' => :can_delete_addon,
        'iTunesConnectStatus' => :status_raw
      })

      class << self
        def factory(attrs)
          return self.new(attrs)
        end
      end

      # Private methods
      def setup
        # Parse the status
        @status = Tunes::IAPStatus.get_from_string(status_raw)

        # Parse the type
        @type = Tunes::IAPType.get_from_string(type_raw)
      end

      def edit
        attrs = client.load_iap(app_id: application.apple_id, purchase_id: self.purchase_id)
        attrs[:application] = application
        Tunes::IAPDetail.factory(attrs)
      end

      def delete!
        client.delete_iap!(app_id: application.apple_id, purchase_id: self.purchase_id)
      end
    end
  end
end
