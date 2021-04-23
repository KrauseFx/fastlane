require 'fastlane_core'
require 'spaceship'

require_relative 'module'

module Deliver
  # upload description, rating, etc.
  # rubocop:disable Metrics/ClassLength
  class UploadMetadata
    # All the localised values attached to the version
    LOCALISED_VERSION_VALUES = {
      description: "description",
      keywords: "keywords",
      release_notes: "whats_new",
      support_url: "support_url",
      marketing_url: "marketing_url",
      promotional_text: "promotional_text"
    }

    # Everything attached to the version but not being localised
    NON_LOCALISED_VERSION_VALUES = {
      copyright: "copyright"
    }

    # Localised app details values
    LOCALISED_APP_VALUES = {
      name: "name",
      subtitle: "subtitle",
      privacy_url: "privacy_policy_url",
      apple_tv_privacy_policy: "privacy_policy_text"
    }

    # Non localized app details values
    NON_LOCALISED_APP_VALUES = {
      primary_category: :primary_category,
      secondary_category: :secondary_category,
      primary_first_sub_category: :primary_subcategory_one,
      primary_second_sub_category: :primary_subcategory_two,
      secondary_first_sub_category: :secondary_subcategory_one,
      secondary_second_sub_category: :secondary_subcategory_two
    }

    # Review information values
    REVIEW_INFORMATION_VALUES_LEGACY = {
      review_first_name: :first_name,
      review_last_name: :last_name,
      review_phone_number: :phone_number,
      review_email: :email_address,
      review_demo_user: :demo_user,
      review_demo_password: :demo_password,
      review_notes: :notes
    }
    REVIEW_INFORMATION_VALUES = {
      first_name: "contact_first_name",
      last_name: "contact_last_name",
      phone_number: "contact_phone",
      email_address: "contact_email",
      demo_user: "demo_account_name",
      demo_password: "demo_account_password",
      notes: "notes"
    }

    # Localized app details values, that are editable in live state
    LOCALISED_LIVE_VALUES = [:description, :release_notes, :support_url, :marketing_url, :promotional_text, :privacy_url]

    # Non localized app details values, that are editable in live state
    NON_LOCALISED_LIVE_VALUES = [:copyright]

    # Directory name it contains trade representative contact information
    TRADE_REPRESENTATIVE_CONTACT_INFORMATION_DIR = "trade_representative_contact_information"

    # Directory name it contains review information
    REVIEW_INFORMATION_DIR = "review_information"

    ALL_META_SUB_DIRS = [TRADE_REPRESENTATIVE_CONTACT_INFORMATION_DIR, REVIEW_INFORMATION_DIR]

    # rubocop:disable Metrics/PerceivedComplexity

    require_relative 'loader'

    # Make sure to call `load_from_filesystem` before calling upload
    def upload(options)
      return if options[:skip_metadata]

      app = options[:app]

      platform = Spaceship::ConnectAPI::Platform.map(options[:platform])

      enabled_languages = detect_languages(options)

      app_store_version_localizations = verify_available_version_languages!(options, app, enabled_languages) unless options[:edit_live]
      app_info_localizations = verify_available_info_languages!(options, app, enabled_languages) unless options[:edit_live]

      if options[:edit_live]
        # not all values are editable when using live_version
        version = app.get_live_app_store_version(platform: platform)
        localised_options = LOCALISED_LIVE_VALUES
        non_localised_options = NON_LOCALISED_LIVE_VALUES

        if v.nil?
          UI.message("Couldn't find live version, editing the current version on App Store Connect instead")
          version = fetch_edit_app_store_version(app, platform)
          # we don't want to update the localised_options and non_localised_options
          # as we also check for `options[:edit_live]` at other areas in the code
          # by not touching those 2 variables, deliver is more consistent with what the option says
          # in the documentation
        else
          UI.message("Found live version")
        end
      else
        version = fetch_edit_app_store_version(app, platform)
        localised_options = (LOCALISED_VERSION_VALUES.keys + LOCALISED_APP_VALUES.keys)
        non_localised_options = NON_LOCALISED_VERSION_VALUES.keys
      end

      # Needed for to filter out release notes from being sent up
      number_of_versions = Spaceship::ConnectAPI.get_app_store_versions(
        app_id: app.id,
        filter: { platform: platform },
        limit: 2
      ).count
      is_first_version = number_of_versions == 1
      UI.verbose("Version '#{version.version_string}' is the first version on App Store Connect") if is_first_version

      UI.important("Will begin uploading metadata for '#{version.version_string}' on App Store Connect")

      localized_version_attributes_by_locale = {}
      localized_info_attributes_by_locale = {}

      localised_options.each do |key|
        current = options[key]
        next unless current

        unless current.kind_of?(Hash)
          UI.error("Error with provided '#{key}'. Must be a hash, the key being the language.")
          next
        end

        if key == :release_notes && is_first_version
          UI.error("Skipping 'release_notes'... this is the first version of the app")
          next
        end

        current.each do |language, value|
          next unless value.to_s.length > 0
          strip_value = value.to_s.strip

          if LOCALISED_VERSION_VALUES.include?(key) && !strip_value.empty?
            attribute_name = LOCALISED_VERSION_VALUES[key]

            localized_version_attributes_by_locale[language] ||= {}
            localized_version_attributes_by_locale[language][attribute_name] = strip_value
          end

          next unless LOCALISED_APP_VALUES.include?(key) && !strip_value.empty?
          attribute_name = LOCALISED_APP_VALUES[key]

          localized_info_attributes_by_locale[language] ||= {}
          localized_info_attributes_by_locale[language][attribute_name] = strip_value
        end
      end

      non_localized_version_attributes = {}
      non_localised_options.each do |key|
        strip_value = options[key].to_s.strip
        next unless strip_value.to_s.length > 0

        if NON_LOCALISED_VERSION_VALUES.include?(key) && !strip_value.empty?
          attribute_name = NON_LOCALISED_VERSION_VALUES[key]
          non_localized_version_attributes[attribute_name] = strip_value
        end
      end

      release_type = if options[:auto_release_date]
                       # Convert time format to 2020-06-17T12:00:00-07:00
                       time_in_ms = options[:auto_release_date]
                       date = convert_ms_to_iso8601(time_in_ms)

                       non_localized_version_attributes['earliestReleaseDate'] = date
                       Spaceship::ConnectAPI::AppStoreVersion::ReleaseType::SCHEDULED
                     elsif options[:automatic_release] == true
                       Spaceship::ConnectAPI::AppStoreVersion::ReleaseType::AFTER_APPROVAL
                     elsif options[:automatic_release] == false
                       Spaceship::ConnectAPI::AppStoreVersion::ReleaseType::MANUAL
                     end
      if release_type.nil?
        UI.important("Release type will not be set because neither `automatic_release` nor `auto_release_date` were provided. Please explicitly set one of these options if you need a release type set")
      else
        non_localized_version_attributes['releaseType'] = release_type
      end

      # Update app store version
      # This needs to happen before updating localizations (https://openradar.appspot.com/radar?id=4925914991296512)
      #
      # Adding some sleeps because the API will sometimes be in a state where releaseType can't be modified
      #   https://github.com/fastlane/fastlane/issues/16911
      UI.message("Uploading metadata to App Store Connect for version")
      sleep(2)
      version.update(attributes: non_localized_version_attributes)
      sleep(1)

      # Update app store version localizations
      store_version_worker = FastlaneCore::QueueWorker.new do |app_store_version_localization|
        attributes = localized_version_attributes_by_locale[app_store_version_localization.locale]
        if attributes
          UI.message("Uploading metadata to App Store Connect for localized version '#{app_store_version_localization.locale}'")
          app_store_version_localization.update(attributes: attributes)
        end
      end
      store_version_worker.batch_enqueue(app_store_version_localizations)
      store_version_worker.start

      # Update app info localizations
      app_info_worker = FastlaneCore::QueueWorker.new do |app_info_localization|
        attributes = localized_info_attributes_by_locale[app_info_localization.locale]
        if attributes
          UI.message("Uploading metadata to App Store Connect for localized info '#{app_info_localization.locale}'")
          app_info_localization.update(attributes: attributes)
        end
      end
      app_info_worker.batch_enqueue(app_info_localizations)
      app_info_worker.start

      # Update categories
      app_info = fetch_edit_app_info(app)
      if app_info
        category_id_map = {}

        primary_category = options[:primary_category].to_s.strip
        secondary_category = options[:secondary_category].to_s.strip
        primary_first_sub_category = options[:primary_first_sub_category].to_s.strip
        primary_second_sub_category = options[:primary_second_sub_category].to_s.strip
        secondary_first_sub_category = options[:secondary_first_sub_category].to_s.strip
        secondary_second_sub_category = options[:secondary_second_sub_category].to_s.strip

        mapped_values = {}

        # Only update primary and secondar category if explicitly set
        unless primary_category.empty?
          mapped = Spaceship::ConnectAPI::AppCategory.map_category_from_itc(
            primary_category
          )

          mapped_values[primary_category] = mapped
          category_id_map[:primary_category_id] = mapped
        end
        unless secondary_category.empty?
          mapped = Spaceship::ConnectAPI::AppCategory.map_category_from_itc(
            secondary_category
          )

          mapped_values[secondary_category] = mapped
          category_id_map[:secondary_category_id] = mapped
        end

        # Only set if primary category is going to be set
        unless primary_category.empty?
          mapped = Spaceship::ConnectAPI::AppCategory.map_subcategory_from_itc(
            primary_first_sub_category
          )

          mapped_values[primary_first_sub_category] = mapped
          category_id_map[:primary_subcategory_one_id] = mapped
        end
        unless primary_category.empty?
          mapped = Spaceship::ConnectAPI::AppCategory.map_subcategory_from_itc(
            primary_second_sub_category
          )

          mapped_values[primary_second_sub_category] = mapped
          category_id_map[:primary_subcategory_two_id] = mapped
        end

        # Only set if secondary category is going to be set
        unless secondary_category.empty?
          mapped = Spaceship::ConnectAPI::AppCategory.map_subcategory_from_itc(
            secondary_first_sub_category
          )

          mapped_values[secondary_first_sub_category] = mapped
          category_id_map[:secondary_subcategory_one_id] = mapped
        end
        unless secondary_category.empty?
          mapped = Spaceship::ConnectAPI::AppCategory.map_subcategory_from_itc(
            secondary_second_sub_category
          )

          mapped_values[secondary_second_sub_category] = mapped
          category_id_map[:secondary_subcategory_two_id] = mapped
        end

        # Print deprecation warnings if category was mapped
        has_mapped_values = false
        mapped_values.each do |k, v|
          next if k.nil? || v.nil?
          next if k == v
          has_mapped_values = true
          UI.deprecated("Category '#{k}' from iTunesConnect has been deprecated. Please replace with '#{v}'")
        end
        UI.deprecated("You can find more info at https://docs.fastlane.tools/actions/deliver/#reference") if has_mapped_values

        app_info.update_categories(category_id_map: category_id_map)
      end

      # Update phased release
      unless options[:phased_release].nil?
        phased_release = begin
                           version.fetch_app_store_version_phased_release
                         rescue
                           nil
                         end
        if !!options[:phased_release]
          unless phased_release
            UI.message("Creating phased release on App Store Connect")
            version.create_app_store_version_phased_release(attributes: {
              phasedReleaseState: Spaceship::ConnectAPI::AppStoreVersionPhasedRelease::PhasedReleaseState::INACTIVE
            })
          end
        elsif phased_release
          UI.message("Removing phased release on App Store Connect")
          phased_release.delete!
        end
      end

      # Update rating reset
      unless options[:reset_ratings].nil?
        reset_rating_request = begin
                                 version.fetch_reset_ratings_request
                               rescue
                                 nil
                               end
        if !!options[:reset_ratings]
          unless reset_rating_request
            UI.message("Creating reset ratings request on App Store Connect")
            version.create_reset_ratings_request
          end
        elsif reset_rating_request
          UI.message("Removing reset ratings request on App Store Connect")
          reset_rating_request.delete!
        end
      end

      set_review_information(version, options)
      set_review_attachment_file(version, options)
      set_app_rating(version, options)
    end

    # rubocop:enable Metrics/PerceivedComplexity

    def convert_ms_to_iso8601(time_in_ms)
      time_in_s = time_in_ms / 1000

      # Remove minutes and seconds (whole hour)
      seconds_in_hour = 60 * 60
      time_in_s_to_hour = (time_in_s / seconds_in_hour).to_i * seconds_in_hour

      return Time.at(time_in_s_to_hour).utc.strftime("%Y-%m-%dT%H:%M:%S%:z")
    end

    # If the user is using the 'default' language, then assign values where they are needed
    def assign_defaults(options)
      # Normalizes languages keys from symbols to strings
      normalize_language_keys(options)

      # Build a complete list of the required languages
      enabled_languages = detect_languages(options)

      # Get all languages used in existing settings
      (LOCALISED_VERSION_VALUES.keys + LOCALISED_APP_VALUES.keys).each do |key|
        current = options[key]
        next unless current && current.kind_of?(Hash)
        current.each do |language, value|
          enabled_languages << language unless enabled_languages.include?(language)
        end
      end

      # Check folder list (an empty folder signifies a language is required)
      ignore_validation = options[:ignore_language_directory_validation]
      Loader.language_folders(options[:metadata_path], ignore_validation).each do |lang_folder|
        enabled_languages << lang_folder.basename unless enabled_languages.include?(lang_folder.basename)
      end

      return unless enabled_languages.include?("default")
      UI.message("Detected languages: " + enabled_languages.to_s)

      (LOCALISED_VERSION_VALUES.keys + LOCALISED_APP_VALUES.keys).each do |key|
        current = options[key]
        next unless current && current.kind_of?(Hash)

        default = current["default"]
        next if default.nil?

        enabled_languages.each do |language|
          value = current[language]
          next unless value.nil?

          current[language] = default
        end
        current.delete("default")
      end
    end

    def detect_languages(options)
      # Build a complete list of the required languages
      enabled_languages = options[:languages] || []

      # Get all languages used in existing settings
      (LOCALISED_VERSION_VALUES.keys + LOCALISED_APP_VALUES.keys).each do |key|
        current = options[key]
        next unless current && current.kind_of?(Hash)
        current.each do |language, value|
          enabled_languages << language unless enabled_languages.include?(language)
        end
      end

      # Check folder list (an empty folder signifies a language is required)
      ignore_validation = options[:ignore_language_directory_validation]
      Loader.language_folders(options[:metadata_path], ignore_validation).each do |lang_folder|
        enabled_languages << lang_folder.basename unless enabled_languages.include?(lang_folder.basename)
      end

      # Mapping to strings because :default symbol can be passed in
      enabled_languages
        .map(&:to_s)
        .uniq
    end

    def fetch_edit_app_store_version(app, platform, wait_time: 10)
      retry_if_nil("Cannot find edit app store version", wait_time: wait_time) do
        app.get_edit_app_store_version(platform: platform)
      end
    end

    def fetch_edit_app_info(app, wait_time: 10)
      retry_if_nil("Cannot find edit app info", wait_time: wait_time) do
        app.fetch_edit_app_info
      end
    end

    def retry_if_nil(message, tries: 5, wait_time: 10)
      loop do
        tries -= 1

        value = yield
        return value if value

        UI.message("#{message}... Retrying after #{wait_time} seconds (remaining: #{tries})")
        sleep(wait_time)

        return nil if tries.zero?
      end
    end

    # Finding languages to enable
    def verify_available_info_languages!(options, app, languages)
      app_info = fetch_edit_app_info(app)

      unless app_info
        UI.user_error!("Cannot update languages - could not find an editable info")
        return
      end

      localizations = app_info.get_app_info_localizations

      languages = (languages || []).reject { |lang| lang == "default" }
      locales_to_enable = languages - localizations.map(&:locale)

      if locales_to_enable.count > 0
        lng_text = "language"
        lng_text += "s" if locales_to_enable.count != 1
        Helper.show_loading_indicator("Activating info #{lng_text} #{locales_to_enable.join(', ')}...")

        locales_to_enable.each do |locale|
          app_info.create_app_info_localization(attributes: {
            locale: locale
          })
        end

        Helper.hide_loading_indicator

        # Refresh version localizations
        localizations = app_info.get_app_info_localizations
      end

      return localizations
    end

    # Finding languages to enable
    def verify_available_version_languages!(options, app, languages)
      platform = Spaceship::ConnectAPI::Platform.map(options[:platform])
      version = fetch_edit_app_store_version(app, platform)

      unless version
        UI.user_error!("Cannot update languages - could not find an editable version for '#{platform}'")
        return
      end

      localizations = version.get_app_store_version_localizations

      languages = (languages || []).reject { |lang| lang == "default" }
      locales_to_enable = languages - localizations.map(&:locale)

      if locales_to_enable.count > 0
        lng_text = "language"
        lng_text += "s" if locales_to_enable.count != 1
        Helper.show_loading_indicator("Activating version #{lng_text} #{locales_to_enable.join(', ')}...")

        locales_to_enable.each do |locale|
          version.create_app_store_version_localization(attributes: {
            locale: locale
          })
        end

        Helper.hide_loading_indicator

        # Refresh version localizations
        localizations = version.get_app_store_version_localizations
      end

      return localizations
    end

    # Loads the metadata files and stores them into the options object
    def load_from_filesystem(options)
      return if options[:skip_metadata]

      # Load localised data
      ignore_validation = options[:ignore_language_directory_validation]
      Loader.language_folders(options[:metadata_path], ignore_validation).each do |lang_folder|
        (LOCALISED_VERSION_VALUES.keys + LOCALISED_APP_VALUES.keys).each do |key|
          path = File.join(lang_folder.path, "#{key}.txt")
          next unless File.exist?(path)

          UI.message("Loading '#{path}'...")
          options[key] ||= {}
          options[key][lang_folder.basename] ||= File.read(path)
        end
      end

      # Load non localised data
      (NON_LOCALISED_VERSION_VALUES.keys + NON_LOCALISED_APP_VALUES.keys).each do |key|
        path = File.join(options[:metadata_path], "#{key}.txt")
        next unless File.exist?(path)

        UI.message("Loading '#{path}'...")
        options[key] ||= File.read(path)
      end

      # Load review information
      # This is used to find the file path for both new and legacy review information filenames
      resolve_review_info_path = lambda do |option_name|
        path = File.join(options[:metadata_path], REVIEW_INFORMATION_DIR, "#{option_name}.txt")
        return nil unless File.exist?(path)
        return nil if options[:app_review_information][option_name].to_s.length > 0

        UI.message("Loading '#{path}'...")
        return path
      end

      # First try and load review information from legacy filenames
      options[:app_review_information] ||= {}
      REVIEW_INFORMATION_VALUES_LEGACY.each do |legacy_option_name, option_name|
        path = resolve_review_info_path.call(legacy_option_name)
        next if path.nil?
        options[:app_review_information][option_name] ||= File.read(path)

        UI.deprecated("Review rating option '#{legacy_option_name}' from iTunesConnect has been deprecated. Please replace with '#{option_name}'")
      end

      # Then load review information from new App Store Connect filenames
      REVIEW_INFORMATION_VALUES.keys.each do |option_name|
        path = resolve_review_info_path.call(option_name)
        next if path.nil?
        options[:app_review_information][option_name] ||= File.read(path)
      end
    end

    private

    # Normalizes languages keys from symbols to strings
    def normalize_language_keys(options)
      (LOCALISED_VERSION_VALUES.keys + LOCALISED_APP_VALUES.keys).each do |key|
        current = options[key]
        next unless current && current.kind_of?(Hash)

        current.keys.each do |language|
          current[language.to_s] = current.delete(language)
        end
      end

      options
    end

    def set_review_information(version, options)
      info = options[:app_review_information]
      return if info.nil? || info.empty?

      info = info.collect { |k, v| [k.to_sym, v] }.to_h
      UI.user_error!("`app_review_information` must be a hash", show_github_issues: true) unless info.kind_of?(Hash)

      attributes = {}
      REVIEW_INFORMATION_VALUES.each do |key, attribute_name|
        strip_value = info[key].to_s.strip
        attributes[attribute_name] = strip_value unless strip_value.empty?
      end

      if !attributes["demo_account_name"].to_s.empty? && !attributes["demo_account_password"].to_s.empty?
        attributes["demo_account_required"] = true
      else
        attributes["demo_account_required"] = false
      end

      UI.message("Uploading app review information to App Store Connect")
      app_store_review_detail = begin
                                  version.fetch_app_store_review_detail
                                rescue => error
                                  UI.error("Error fetching app store review detail - #{error.message}")
                                  nil
                                end
      if app_store_review_detail
        app_store_review_detail.update(attributes: attributes)
      else
        version.create_app_store_review_detail(attributes: attributes)
      end
    end

    def set_review_attachment_file(version, options)
      app_store_review_detail = version.fetch_app_store_review_detail
      app_store_review_attachments = app_store_review_detail.app_store_review_attachments || []

      if options[:app_review_attachment_file]
        app_store_review_attachments.each do |app_store_review_attachment|
          UI.message("Removing previous review attachment file from App Store Connect")
          app_store_review_attachment.delete!
        end

        UI.message("Uploading review attachment file to App Store Connect")
        app_store_review_detail.upload_attachment(path: options[:app_review_attachment_file])
      else
        app_store_review_attachments.each(&:delete!)
        UI.message("Removing review attachment file to App Store Connect") unless app_store_review_attachments.empty?
      end
    end

    def set_app_rating(version, options)
      return unless options[:app_rating_config_path]

      require 'json'
      begin
        json = JSON.parse(File.read(options[:app_rating_config_path]))
      rescue => ex
        UI.error(ex.to_s)
        UI.user_error!("Error parsing JSON file at path '#{options[:app_rating_config_path]}'")
      end
      UI.message("Setting the app's age rating...")

      # Maping from legacy ITC values to App Store Connect Values
      mapped_values = {}
      attributes = {}
      json.each do |k, v|
        new_key = Spaceship::ConnectAPI::AgeRatingDeclaration.map_key_from_itc(k)
        new_value = Spaceship::ConnectAPI::AgeRatingDeclaration.map_value_from_itc(new_key, v)

        mapped_values[k] = new_key
        mapped_values[v] = new_value

        attributes[new_key] = new_value
      end

      # Print deprecation warnings if category was mapped
      has_mapped_values = false
      mapped_values.each do |k, v|
        next if k.nil? || v.nil?
        next if k == v
        has_mapped_values = true
        UI.deprecated("Age rating '#{k}' from iTunesConnect has been deprecated. Please replace with '#{v}'")
      end
      UI.deprecated("You can find more info at https://docs.fastlane.tools/actions/deliver/#reference") if has_mapped_values

      age_rating_declaration = version.fetch_age_rating_declaration
      age_rating_declaration.update(attributes: attributes)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
