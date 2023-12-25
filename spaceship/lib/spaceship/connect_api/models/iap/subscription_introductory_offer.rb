require_relative '../../model'
module Spaceship
  class ConnectAPI
    class SubscriptionIntroductoryOffer
      include Spaceship::ConnectAPI::Model

      attr_accessor :duration
      attr_accessor :end_date
      attr_accessor :number_of_periods
      attr_accessor :offer_mode
      attr_accessor :start_date

      attr_accessor :subscription_price_point
      attr_accessor :territory

      module Duration
        ONE_DAY = "ONE_DAY"
        THREE_DAYS = "THREE_DAYS"
        ONE_WEEK = "ONE_WEEK"
        TWO_WEEKS = "TWO_WEEKS"
        ONE_MONTH = "ONE_MONTH"
        TWO_MONTHS = "TWO_MONTHS"
        THREE_MONTHS = "THREE_MONTHS"
        SIX_MONTHS = "SIX_MONTHS"
        ONE_YEAR = "ONE_YEAR"
      end

      module OfferMode
        PAY_AS_YOU_GO = "PAY_AS_YOU_GO"
        PAY_UP_FRONT = "PAY_UP_FRONT"
        FREE_TRIAL = "FREE_TRIAL"
      end

      attr_mapping({
        duration: 'duration',
        endDate: 'end_date',
        numberOfPeriods: 'number_of_periods',
        offerMode: 'offer_mode',
        startDate: 'start_date',

        subscriptionPricePoint: 'subscription_price_point',
        territory: 'territory'
      })

      ESSENTIAL_INCLUDES = [
        "subscriptionPricePoint",
        "territory"
      ].join(",")

      def self.type
        return 'subscriptionIntroductoryOffers'
      end

      def self.duration_from_days(days)
        case days
        when 1
          Duration::ONE_DAY
        when 3
          Duration::THREE_DAYS
        when 7
          Duration::ONE_WEEK
        when 14
          Duration::TWO_WEEKS
        when 30
          Duration::ONE_MONTH
        when 60
          Duration::TWO_MONTHS
        when 90
          Duration::THREE_MONTHS
        when 180
          Duration::SIX_MONTHS
        when 365
          Duration::ONE_YEAR
        end
      end

      def duration_in_days
        case duration
        when Duration::ONE_DAY
          1
        when Duration::THREE_DAYS
          3
        when Duration::ONE_WEEK
          7
        when Duration::TWO_WEEKS
          14
        when Duration::ONE_MONTH
          30
        when Duration::TWO_MONTHS
          60
        when Duration::THREE_MONTHS
          90
        when Duration::SIX_MONTHS
          180
        when Duration::ONE_YEAR
          365
        end
      end

      def start_date_as_date
        Date.strptime(start_date, "%Y-%m-%d") if start_date
      end

      def end_date_as_date
        Date.strptime(end_date, "%Y-%m-%d") if end_date
      end

      #
      # Update
      #

      def update(client: nil, end_date: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.update_subscription_introductory_offer(introductory_offer_id: id, end_date: end_date)
        resp.to_models.first # self
      end

      #
      # Delete
      #

      def delete(client: nil)
        client ||= Spaceship::ConnectAPI
        client.delete_subscription_introductory_offer(introductory_offer_id: id)
      end

    end
  end
end
