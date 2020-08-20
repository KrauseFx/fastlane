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
require 'spaceship/connect_api/models/certificate'
require 'spaceship/connect_api/models/device'
require 'spaceship/connect_api/models/profile'

require 'spaceship/connect_api/models/user'

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
require 'spaceship/connect_api/models/pre_release_version'

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
require 'spaceship/connect_api/models/reset_ratings_request'
require 'spaceship/connect_api/models/sandbox_tester'
require 'spaceship/connect_api/models/territory'

module Spaceship
  class ConnectAPI
    extend Spaceship::ConnectAPI::Provisioning
    extend Spaceship::ConnectAPI::TestFlight
    extend Spaceship::ConnectAPI::Users
    extend Spaceship::ConnectAPI::Tunes

    @token = nil

    class << self
      attr_writer(:token)
    end

    class << self
      attr_reader :token
    end

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
  end
end
