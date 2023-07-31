require_relative '../model'
require_relative './app_screenshot'

module Spaceship
  class ConnectAPI
    class AppScreenshotSet
      include Spaceship::ConnectAPI::Model

      attr_accessor :screenshot_display_type

      attr_accessor :app_screenshots

      module DisplayType
        APP_IPHONE_35 = "APP_IPHONE_35"
        APP_IPHONE_40 = "APP_IPHONE_40"
        APP_IPHONE_47 = "APP_IPHONE_47"
        APP_IPHONE_55 = "APP_IPHONE_55"
        APP_IPHONE_58 = "APP_IPHONE_58"
        APP_IPHONE_61 = "APP_IPHONE_61"
        APP_IPHONE_65 = "APP_IPHONE_65"
        APP_IPHONE_67 = "APP_IPHONE_67"

        APP_IPAD_97 = "APP_IPAD_97"
        APP_IPAD_105 = "APP_IPAD_105"
        APP_IPAD_PRO_3GEN_11 = "APP_IPAD_PRO_3GEN_11"
        APP_IPAD_PRO_129 = "APP_IPAD_PRO_129"
        APP_IPAD_PRO_3GEN_129 = "APP_IPAD_PRO_3GEN_129"

        IMESSAGE_APP_IPHONE_40 = "IMESSAGE_APP_IPHONE_40"
        IMESSAGE_APP_IPHONE_47 = "IMESSAGE_APP_IPHONE_47"
        IMESSAGE_APP_IPHONE_55 = "IMESSAGE_APP_IPHONE_55"
        IMESSAGE_APP_IPHONE_58 = "IMESSAGE_APP_IPHONE_58"
        IMESSAGE_APP_IPHONE_61 = "IMESSAGE_APP_IPHONE_61"
        IMESSAGE_APP_IPHONE_65 = "IMESSAGE_APP_IPHONE_65"
        IMESSAGE_APP_IPHONE_67 = "IMESSAGE_APP_IPHONE_67"

        IMESSAGE_APP_IPAD_97 = "IMESSAGE_APP_IPAD_97"
        IMESSAGE_APP_IPAD_105 = "IMESSAGE_APP_IPAD_105"
        IMESSAGE_APP_IPAD_PRO_129 = "IMESSAGE_APP_IPAD_PRO_129"
        IMESSAGE_APP_IPAD_PRO_3GEN_11 = "IMESSAGE_APP_IPAD_PRO_3GEN_11"
        IMESSAGE_APP_IPAD_PRO_3GEN_129 = "IMESSAGE_APP_IPAD_PRO_3GEN_129"

        APP_WATCH_SERIES_3 = "APP_WATCH_SERIES_3"
        APP_WATCH_SERIES_4 = "APP_WATCH_SERIES_4"
        APP_WATCH_SERIES_7 = "APP_WATCH_SERIES_7"

        APP_APPLE_TV = "APP_APPLE_TV"

        APP_DESKTOP = "APP_DESKTOP"

        ALL_IMESSAGE = [
          IMESSAGE_APP_IPHONE_40,
          IMESSAGE_APP_IPHONE_47,
          IMESSAGE_APP_IPHONE_55,
          IMESSAGE_APP_IPHONE_58,
          IMESSAGE_APP_IPHONE_61,
          IMESSAGE_APP_IPHONE_65,
          IMESSAGE_APP_IPHONE_67,

          IMESSAGE_APP_IPAD_97,
          IMESSAGE_APP_IPAD_105,
          IMESSAGE_APP_IPAD_PRO_129,
          IMESSAGE_APP_IPAD_PRO_3GEN_11,
          IMESSAGE_APP_IPAD_PRO_3GEN_129
        ]

        ALL = [
          APP_IPHONE_35,
          APP_IPHONE_40,
          APP_IPHONE_47,
          APP_IPHONE_55,
          APP_IPHONE_58,
          APP_IPHONE_61,
          APP_IPHONE_65,
          APP_IPHONE_67,

          APP_IPAD_97,
          APP_IPAD_105,
          APP_IPAD_PRO_3GEN_11,
          APP_IPAD_PRO_129,
          APP_IPAD_PRO_3GEN_129,

          IMESSAGE_APP_IPHONE_40,
          IMESSAGE_APP_IPHONE_47,
          IMESSAGE_APP_IPHONE_55,
          IMESSAGE_APP_IPHONE_58,
          IMESSAGE_APP_IPHONE_61,
          IMESSAGE_APP_IPHONE_65,
          IMESSAGE_APP_IPHONE_67,

          IMESSAGE_APP_IPAD_97,
          IMESSAGE_APP_IPAD_105,
          IMESSAGE_APP_IPAD_PRO_129,
          IMESSAGE_APP_IPAD_PRO_3GEN_11,
          IMESSAGE_APP_IPAD_PRO_3GEN_129,

          APP_WATCH_SERIES_3,
          APP_WATCH_SERIES_4,
          APP_WATCH_SERIES_7,

          APP_DESKTOP
        ]
      end

      attr_mapping({
        "screenshotDisplayType" => "screenshot_display_type",

        "appScreenshots" => "app_screenshots"
      })

      def self.type
        return "appScreenshotSets"
      end

      def apple_tv?
        DisplayType::APP_APPLE_TV == screenshot_display_type
      end

      def imessage?
        DisplayType::ALL_IMESSAGE.include?(screenshot_display_type)
      end

      #
      # API
      #

      def self.all(client: nil, app_store_version_localization_id: nil, filter: {}, includes: nil, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.get_app_screenshot_sets(app_store_version_localization_id: app_store_version_localization_id, filter: filter, includes: includes, limit: limit, sort: sort)
        return resp.to_models
      end

      def self.get(client: nil, app_screenshot_set_id: nil, includes: "appScreenshots")
        client ||= Spaceship::ConnectAPI
        return client.get_app_screenshot_set(app_screenshot_set_id: app_screenshot_set_id, filter: nil, includes: includes, limit: nil, sort: nil).first
      end

      def delete!(client: nil, filter: {}, includes: nil, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        return client.delete_app_screenshot_set(app_screenshot_set_id: id)
      end

      def upload_screenshot(client: nil, path: nil, wait_for_processing: true, position: nil)
        client ||= Spaceship::ConnectAPI
        screenshot = Spaceship::ConnectAPI::AppScreenshot.create(client: client, app_screenshot_set_id: id, path: path, wait_for_processing: wait_for_processing)

        # Reposition (if specified)
        unless position.nil?
          # Get all app preview ids
          set = AppScreenshotSet.get(client: client, app_screenshot_set_id: id)
          app_screenshot_ids = set.app_screenshots.map(&:id)

          # Remove new uploaded screenshot
          app_screenshot_ids.delete(screenshot.id)

          # Insert screenshot at specified position
          app_screenshot_ids = app_screenshot_ids.insert(position, screenshot.id).compact

          # Reorder screenshots
          reorder_screenshots(client: client, app_screenshot_ids: app_screenshot_ids)
        end

        return screenshot
      end

      def reorder_screenshots(client: nil, app_screenshot_ids: nil)
        client ||= Spaceship::ConnectAPI
        client.patch_app_screenshot_set_screenshots(app_screenshot_set_id: id, app_screenshot_ids: app_screenshot_ids)

        return client.get_app_screenshot_set(app_screenshot_set_id: id, includes: "appScreenshots").first
      end
    end
  end
end
