require 'spaceship/connect_api/model'
require 'spaceship/connect_api/response'
require 'spaceship/connect_api/token'
require 'spaceship/connect_api/file_uploader'

require 'spaceship/connect_api/provisioning/provisioning'
require 'spaceship/connect_api/testflight/testflight'
require 'spaceship/connect_api/users/users'
require 'spaceship/connect_api/tunes/tunes'

require 'spaceship/connect_api/models/bundle_id_capability'
require 'spaceship/connect_api/models/bundle_id'
require 'spaceship/connect_api/models/capabilities'
require 'spaceship/connect_api/models/certificate'
require 'spaceship/connect_api/models/device'
require 'spaceship/connect_api/models/profile'

require 'spaceship/connect_api/models/user'
require 'spaceship/connect_api/models/user_invitation'

require 'spaceship/connect_api/models/app'
require 'spaceship/connect_api/models/beta_app_localization'
require 'spaceship/connect_api/models/beta_build_localization'
require 'spaceship/connect_api/models/beta_build_metric'
require 'spaceship/connect_api/models/beta_app_review_detail'
require 'spaceship/connect_api/models/beta_app_review_submission'
require 'spaceship/connect_api/models/beta_feedback'
require 'spaceship/connect_api/models/beta_group'
require 'spaceship/connect_api/models/beta_screenshot'
require 'spaceship/connect_api/models/beta_tester'
require 'spaceship/connect_api/models/beta_tester_metric'
require 'spaceship/connect_api/models/build'
require 'spaceship/connect_api/models/build_delivery'
require 'spaceship/connect_api/models/build_beta_detail'
require 'spaceship/connect_api/models/build_bundle'
require 'spaceship/connect_api/models/build_bundle_file_sizes'
require 'spaceship/connect_api/models/custom_app_organization'
require 'spaceship/connect_api/models/custom_app_user'
require 'spaceship/connect_api/models/pre_release_version'

require 'spaceship/connect_api/models/app_data_usage'
require 'spaceship/connect_api/models/app_data_usage_category'
require 'spaceship/connect_api/models/app_data_usage_data_protection'
require 'spaceship/connect_api/models/app_data_usage_grouping'
require 'spaceship/connect_api/models/app_data_usage_purposes'
require 'spaceship/connect_api/models/app_data_usages_publish_state'
require 'spaceship/connect_api/models/age_rating_declaration'
require 'spaceship/connect_api/models/app_category'
require 'spaceship/connect_api/models/app_info'
require 'spaceship/connect_api/models/app_info_localization'
require 'spaceship/connect_api/models/app_preview_set'
require 'spaceship/connect_api/models/app_preview'
require 'spaceship/connect_api/models/app_price'
require 'spaceship/connect_api/models/app_price_point'
require 'spaceship/connect_api/models/app_price_tier'
require 'spaceship/connect_api/models/app_store_review_attachment'
require 'spaceship/connect_api/models/app_store_review_detail'
require 'spaceship/connect_api/models/app_store_version_release_request'
require 'spaceship/connect_api/models/app_store_version_submission'
require 'spaceship/connect_api/models/app_screenshot_set'
require 'spaceship/connect_api/models/app_screenshot'
require 'spaceship/connect_api/models/app_store_version_localization'
require 'spaceship/connect_api/models/app_store_version_phased_release'
require 'spaceship/connect_api/models/app_store_version'
require 'spaceship/connect_api/models/idfa_declaration'
require 'spaceship/connect_api/models/review_submission'
require 'spaceship/connect_api/models/review_submission_item'
require 'spaceship/connect_api/models/reset_ratings_request'
require 'spaceship/connect_api/models/sandbox_tester'
require 'spaceship/connect_api/models/territory'

require 'spaceship/connect_api/models/resolution_center_message'
require 'spaceship/connect_api/models/resolution_center_thread'
require 'spaceship/connect_api/models/review_rejection'
require 'spaceship/connect_api/models/actor'

require 'spaceship/connect_api/models/iap/in_app_purchase'
require 'spaceship/connect_api/models/iap/in_app_purchase_submission'
require 'spaceship/connect_api/models/iap/in_app_purchase_localization'
require 'spaceship/connect_api/models/iap/in_app_purchase_price_point'
require 'spaceship/connect_api/models/iap/in_app_purchase_price'
require 'spaceship/connect_api/models/iap/in_app_purchase_price_schedule'
require 'spaceship/connect_api/models/iap/in_app_purchase_app_store_review_screenshot'
require 'spaceship/connect_api/models/iap/subscription_app_store_review_screenshot'
require 'spaceship/connect_api/models/iap/subscription_availability'
require 'spaceship/connect_api/models/iap/subscription_group'
require 'spaceship/connect_api/models/iap/subscription_group_localization'
require 'spaceship/connect_api/models/iap/subscription_introductory_offer'
require 'spaceship/connect_api/models/iap/subscription_price_point'
require 'spaceship/connect_api/models/iap/subscription_price'
require 'spaceship/connect_api/models/iap/subscription_localization'
require 'spaceship/connect_api/models/iap/subscription'
require 'spaceship/connect_api/models/iap/subscription_submission'

module Spaceship
  class ConnectAPI
    MAX_OBJECTS_PER_PAGE_LIMIT = 200

    # Defined in the App Store Connect API docs:
    # https://developer.apple.com/documentation/appstoreconnectapi/platform
    #
    # Used for query param filters
    module Platform
      IOS = "IOS"
      MAC_OS = "MAC_OS"
      TV_OS = "TV_OS"
      WATCH_OS = "WATCH_OS"

      ALL = [IOS, MAC_OS, TV_OS, WATCH_OS]

      def self.map(platform)
        return platform if ALL.include?(platform)

        # Map from fastlane input and Spaceship::TestFlight platform values
        case platform.to_sym
        when :appletvos, :tvos
          return Spaceship::ConnectAPI::Platform::TV_OS
        when :osx, :macos, :mac
          return Spaceship::ConnectAPI::Platform::MAC_OS
        when :ios
          return Spaceship::ConnectAPI::Platform::IOS
        else
          raise "Cannot find a matching platform for '#{platform}' - valid values are #{ALL.join(', ')}"
        end
      end
    end

    # Defined in the App Store Connect API docs:
    #
    # Used for creating BundleId and Device
    module BundleIdPlatform
      IOS = "IOS"
      MAC_OS = "MAC_OS"

      ALL = [IOS, MAC_OS]

      def self.map(platform)
        return platform if ALL.include?(platform)

        # Map from fastlane input and Spaceship::TestFlight platform values
        case platform.to_sym
        when :osx, :macos, :mac
          return Spaceship::ConnectAPI::Platform::MAC_OS
        when :ios
          return Spaceship::ConnectAPI::Platform::IOS
        else
          raise "Cannot find a matching platform for '#{platform}' - valid values are #{ALL.join(', ')}"
        end
      end
    end
  end
end
