require_relative 'territory'
require_relative 'b2b_user'
module Spaceship
  module Tunes
    class Availability < TunesBase
      # @return (Bool) Are future territories included?
      attr_accessor :include_future_territories

      # @return (Array of Spaceship::Tunes::Territory objects) A list of the territories
      attr_accessor :territories

      # @return (Bool) Cleared for preorder
      attr_accessor :cleared_for_preorder

      # @return (String) App available date in format of "YYYY-MM-DD"
      attr_accessor :app_available_date

      # @return (Bool) app enabled for b2b users
      attr_accessor :b2b_app_enabled

      # @return (Bool) app enabled for educational discount
      attr_accessor :educational_discount

      # @return (Bool) b2b available for distribution
      attr_accessor :b2b_unavailable

      # @return (Array of Spaceship::Tunes::B2bUser objects) A list of users set by user - if not
      # then the b2b user list that is currently set
      attr_accessor :b2b_users

      attr_mapping(
        'theWorld' => :include_future_territories,
        'preOrder.clearedForPreOrder.value' => :cleared_for_preorder,
        'preOrder.appAvailableDate.value' => :app_available_date,
        'b2BAppFlagDisabled' => :b2b_unavailable
      )

      # Create a new object based on a set of territories.
      # @param territories (Array of String or Spaceship::Tunes::Territory objects): A list of the territories
      # @param params (Hash): Optional parameters (include_future_territories (Bool, default: true) Are future territories included?)
      # This method has serious implications on vpp + educational discount but i don't want to break
      # existing support. please be very careful when using this and provide appropriate params.
      # In future, we should create availability from territories as an instance method not as a class method.
      def self.from_territories(territories = [], params = {})
        # Initializes the DataHash with our preOrder structure so values
        # that are being modified will be saved
        #
        # Note: A better solution for this in the future might be to improve how
        # Base::DataHash sets values for paths that don't exist
        obj = self.new(
          'preOrder' => {
            'clearedForPreOrder' => {
              'value' => false
            },
            'appAvailableDate' => {
              'value' => nil
            }
          }
        )

        # Detect if the territories attribute is an array of Strings and convert to Territories
        obj.territories =
          if territories[0].kind_of?(String)
            territories.map { |territory| Spaceship::Tunes::Territory.from_code(territory) }
          else
            territories
          end
        obj.include_future_territories = params.fetch(:include_future_territories, true)
        obj.cleared_for_preorder = params.fetch(:cleared_for_preorder, false)
        obj.app_available_date = params.fetch(:app_available_date, nil)
        obj.b2b_unavailable =  params.fetch(:b2b_unavailable, false)
        obj.b2b_app_enabled =  params.fetch(:b2b_app_enabled, false)
        obj.educational_discount = params.fetch(:educational_discount, true)
        return obj
      end

      def territories
        @territories ||= raw_data['countries'].map { |info| Territory.new(info) }
      end

      def b2b_users
        @b2b_users ||= raw_data['b2bUsers'].map { |user| B2bUser.new(user) }
      end

      def b2b_app_enabled
        @b2b_app_enabled.nil? ? raw_data['b2bAppEnabled'] : @b2b_app_enabled
      end

      def educational_discount
        @educational_discount.nil? ? raw_data['educationalDiscount'] : @educational_discount
      end

      def cleared_for_preorder
        super || false
      end

      # Sets the b2b flag. If you call Save on app_details without adding any b2b users
      # it will result in an error.
      def enable_b2b_app!
        raise "Not possible to enable b2b on this app" if b2b_unavailable
        @b2b_app_enabled = true
        # need to set the educational discount to false
        @educational_discount = false
        self
      end

      # just adds users to the availability, You will still have to call update_availabilty
      def add_b2b_users(user_list = [])
        raise "Cannot add b2b users if b2b is not enabled" unless b2b_app_enabled
        @b2b_users = user_list.map do |user|
          B2bUser.from_username(user)
        end
        self
      end
    end
  end
end
