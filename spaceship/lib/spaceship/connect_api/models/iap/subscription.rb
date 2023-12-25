require_relative '../../model'
module Spaceship
  class ConnectAPI
    class Subscription
      include Spaceship::ConnectAPI::Model

      # Fields
      attr_accessor :available_in_all_territories,
                    :family_sharable,
                    :name,
                    :product_id,
                    :review_note,
                    :state,
                    :subscription_period,
                    :group_level

      # Relations
      attr_accessor :prices,
                    :subscription_localizations,
                    :app_store_review_screenshot,
                    :introductory_offers,
                    :subscription_availabilities

      module Period
        ONE_WEEK = "ONE_WEEK"
        ONE_MONTH = "ONE_MONTH"
        TWO_MONTHS = "TWO_MONTHS"
        THREE_MONTHS = "THREE_MONTHS"
        SIX_MONTHS = "SIX_MONTHS"
        ONE_YEAR = "ONE_YEAR"
      end

      module State
        APPROVED = "APPROVED"
        DEVELOPER_ACTION_NEEDED = "DEVELOPER_ACTION_NEEDED"
        DEVELOPER_REMOVED_FROM_SALE = "DEVELOPER_REMOVED_FROM_SALE"
        IN_REVIEW = "IN_REVIEW"
        MISSING_METADATA = "MISSING_METADATA"
        PENDING_BINARY_APPROVAL = "PENDING_BINARY_APPROVAL"
        READY_TO_SUBMIT = "READY_TO_SUBMIT"
        REJECTED = "REJECTED"
        REMOVED_FROM_SALE = "REMOVED_FROM_SALE"
        WAITING_FOR_REVIEW = "WAITING_FOR_REVIEW"
      end

      attr_mapping({
        availableInAllTerritories: 'available_in_all_territories',
        familySharable: 'family_sharable',
        name: 'name',
        productId: 'product_id',
        reviewNote: 'review_note',
        state: 'state',
        subscriptionPeriod: 'subscription_period',
        groupLevel: 'group_level',
        subscriptionLocalizations: 'subscription_localizations',
        appStoreReviewScreenshot: 'app_store_review_screenshot',
        introductoryOffers: 'introductory_offers'
      })

      def self.type
        return 'subscriptions'
      end

      #
      # Update
      #

      def update(
            client: nil,
            name: nil,
            available_in_all_territories: nil,
            family_sharable: nil,
            review_note: nil,
            subscription_period: nil,
            group_level: nil
          )
        client ||= Spaceship::ConnectAPI
        resps = client.update_subscription(
          purchase_id: id,
          name: name,
          available_in_all_territories: available_in_all_territories,
          family_sharable: family_sharable,
          review_note: review_note,
          subscription_period: subscription_period,
          group_level: group_level
        )
        return resps.to_models.first
      end

      #
      # Submit
      #

      def submit(client: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.submit_subscription(purchase_id: id)
        resp.to_models.first
      end

      #
      # Delete
      #

      def delete(client: nil)
        client ||= Spaceship::ConnectAPI
        client.delete_subscription(purchase_id: id)
      end

      #
      # Subscription Availability
      #

      def get_subscription_availabilities(client: nil, includes: Spaceship::ConnectAPI::SubscriptionAvailability::ESSENTIAL_INCLUDES, limit: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_subscription_availabilities(purchase_id: id, includes: includes, limit: limit).all_pages
        models = resps.flat_map(&:to_models)
        (self.subscription_availabilities ||= []).concat(models).uniq! { |availability| availability.id }
        models
      end

      def create_subscription_availability(client: nil, available_in_new_territories: nil, available_territory_ids: [])
        client ||= Spaceship::ConnectAPI
        resps = client.create_subscription_availability(purchase_id: id, available_in_new_territories: available_in_new_territories, available_territory_ids: available_territory_ids)
        model = resps.to_models.first
        ((self.subscription_availabilities ||= []) << model).uniq! { |availability| availability.id }
        model
      end

      #
      # Introductory Offers
      #

      def get_introductory_offers(client: nil, filter: {}, includes: Spaceship::ConnectAPI::SubscriptionIntroductoryOffer::ESSENTIAL_INCLUDES, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_subscription_introductory_offers(app_id: id, filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        models = resps.flat_map(&:to_models)
        (self.introductory_offers ||= []).concat(models).uniq! { |offer| offer.id }
        models
      end

      def create_introductory_offer(client: nil, duration:, number_of_periods:, offer_mode:, start_date: nil, end_date: nil, territory_id: nil, subscription_price_point_id: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.create_subscription_introductory_offer(purchase_id: id, duration: duration, number_of_periods: number_of_periods, offer_mode: offer_mode, start_date: start_date, end_date: end_date, territory_id: territory_id, subscription_price_point_id: subscription_price_point_id)
        model = resps.to_models.first
        ((self.introductory_offers ||= []) << model).uniq! { |offer| offer.id }
        model
      end

      #
      # Prices
      #

      def get_prices(client: nil, filter: {}, includes: Spaceship::ConnectAPI::SubscriptionPrice::ESSENTIAL_INCLUDES, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_subscription_prices(app_id: id, filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        models = resps.flat_map(&:to_models)
        (self.prices ||= []).concat(models).uniq! { |price| price.id }
        models
      end

      def create_price(client: nil, price_point_id:, territory_id: nil, preserve_current_price: nil, start_date: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.create_subscription_price(purchase_id: id, price_point_id: price_point_id, territory_id: territory_id, preserve_current_price: preserve_current_price, start_date: start_date)
        model = resps.to_models.first
        ((self.prices ||= []) << model).uniq! { |price| price.id }
        model
      end

      #
      # PricePoints
      #

      def get_price_points(client: nil, filter: {}, includes: Spaceship::ConnectAPI::SubscriptionPricePoint::ESSENTIAL_INCLUDES, limit: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_subscription_price_points(purchase_id: id, filter: filter, includes: includes, limit: limit).all_pages
        resps.flat_map(&:to_models)
      end

      #
      # Subscription Localizations
      #

      def get_subscription_localizations(client: nil, limit: nil, includes: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_subscription_localizations(purchase_id: id, includes: includes, limit: limit).all_pages
        models = resps.flat_map(&:to_models)
        (self.subscription_localizations ||= []).concat(models).uniq! { |sub_loc| sub_loc.id }
        models
      end

      def get_subscription_localization(client: nil, localization_id:, includes: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_subscription_localization(localization_id: localization_id, includes: includes)
        model = resps.to_models.first
        ((self.subscription_localizations ||= []) << model).uniq! { |sub_loc| sub_loc.id }
        model
      end

      def create_subscription_localization(client: nil, locale:, name:, description: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.create_subscription_localization(purchase_id: id, locale: locale, name: name, description: description)
        model = resps.to_models.first
        ((self.subscription_localizations ||= []) << model).uniq! { |sub_loc| sub_loc.id }
        model
      end

      #
      # Subscription App Store Review Screenshot
      #

      def upload_app_store_review_screenshot(client: nil, path:)
        client ||= Spaceship::ConnectAPI
        file_name = File.basename(path)
        file_size = File.size(path)
        bytes = File.binread(path)

        # Create Placeholder
        screenshot = create_app_store_review_screenshot(client: client, file_name: file_name, file_size: file_size)
        self.app_store_review_screenshot = screenshot

        # Upload Image
        screenshot.upload_image(client: client, bytes: bytes)

        # Commit Image
        screenshot = screenshot.update(client: client, source_file_checksum: Digest::MD5.hexdigest(bytes), uploaded: true)
        self.app_store_review_screenshot = screenshot
      end

      def create_app_store_review_screenshot(client: nil, file_name:, file_size:)
        client ||= Spaceship::ConnectAPI
        resps = client.create_subscription_app_store_review_screenshot(purchase_id: id, file_name: file_name, file_size: file_size)
        resps.to_models.first
      end

    end
  end
end
