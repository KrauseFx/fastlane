module Deliver
  # This is a convinient class that enumerates app store connect's screenshots in various degrees.
  class AppScreenshotIterator
    NUMBER_OF_THREADS = Helper.test? ? 1 : [ENV.fetch("DELIVER_NUMBER_OF_THREADS", 10).to_i, 10].min

    # @param localizations [Array<Spaceship::ConnectAPI::AppStoreVersionLocalization>]
    def initialize(localizations)
      @localizations = localizations
    end

    # Iterate app_screenshot_set over localizations
    #
    # @yield [localization, app_screenshot_set]
    # @yieldparam [optional, Spaceship::ConnectAPI::AppStoreVersionLocalization] localization
    # @yieldparam [optional, Spaceship::ConnectAPI::AppStoreScreenshotSet] app_screenshot_set
    def each_app_screenshot_set(localizations = @localizations, &block)
      return enum_for(__method__, localizations) unless block

      # Collect app_screenshot_sets from localizations in parallel but
      # limit the number of threads working at a time with using `lazy` and `force` controls
      # to not attack App Store Connect
      results = localizations.each_slice(NUMBER_OF_THREADS).lazy.map do |localizations_grouped|
        localizations_grouped.map do |localization|
          Thread.new do
            [localization, localization.get_app_screenshot_sets]
          end
        end
      end.flat_map do |threads|
        threads.map { |t| t.join.value }
      end.force

      results.each do |localization, app_screenshot_sets|
        app_screenshot_sets.each do |app_screenshot_set|
          yield(localization, app_screenshot_set)
        end
      end
    end

    # Iterate app_screenshot over localizations and app_screenshot_sets
    #
    # @yield [localization, app_screenshot_set, app_screenshot]
    # @yieldparam [optional, Spaceship::ConnectAPI::AppStoreVersionLocalization] localization
    # @yieldparam [optional, Spaceship::ConnectAPI::AppStoreScreenshotSet] app_screenshot_set
    # @yieldparam [optional, Spaceship::ConnectAPI::AppStoreScreenshot] app_screenshot
    def each_app_screenshot(&block)
      return enum_for(__method__) unless block

      each_app_screenshot_set do |localization, app_screenshot_set|
        app_screenshot_set.app_screenshots.each do |app_screenshot|
          yield(localization, app_screenshot_set, app_screenshot)
        end
      end
    end

    # Iterate given local app_screenshot over localizations and app_screenshot_sets
    #
    # @param screenshots_per_language [Hash<String, Array<Deliver::AppScreenshot>]
    # @yield [localization, app_screenshot_set, app_screenshot]
    # @yieldparam [optional, Spaceship::ConnectAPI::AppStoreVersionLocalization] localization
    # @yieldparam [optional, Spaceship::ConnectAPI::AppStoreScreenshotSet] app_screenshot_set
    # @yieldparam [optional, Deliver::AppScreenshot] screenshot
    # @yieldparam [optional, Integer] index a number reperesents which position the screenshot will be
    def each_local_screenshot(screenshots_per_language, &block)
      return enum_for(__method__, screenshots_per_language) unless block

      # filter unnecessary localizations
      supported_localizations = @localizations.reject { |l| screenshots_per_language[l.locale].nil? }

      # build a hash that can access app_screenshot_set corresponding to given locale and display_type
      # via parallelized each_app_screenshot_set to gain performance
      app_screenshot_set_per_locale_and_display_type = each_app_screenshot_set(supported_localizations)
                                                       .each_with_object({}) do |(localization, app_screenshot_set), hash|
        hash[localization.locale] ||= {}
        hash[localization.locale][app_screenshot_set.screenshot_display_type] = app_screenshot_set
      end

      # iterate over screenshots per localization
      screenshots_per_language.each do |language, screenshots_for_language|
        localization = supported_localizations.find { |l| l.locale == language }
        screenshots_per_display_type = screenshots_for_language.reject { |screenshot| screenshot.device_type.nil? }.group_by(&:device_type)

        screenshots_per_display_type.each do |display_type, screenshots|
          # create AppScreenshotSet for given display_type if it doesn't exsit
          app_screenshot_set = (app_screenshot_set_per_locale_and_display_type[language] || {})[display_type]
          app_screenshot_set ||= localization.create_app_screenshot_set(attributes: { screenshotDisplayType: display_type })

          # iterate over screenshots per display size with index
          screenshots.each do |screenshot|
            yield(localization, app_screenshot_set, screenshot)
          end
        end
      end
    end
  end
end
