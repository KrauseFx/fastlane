require_relative '../test_flight/group'
require_relative '../test_flight/build'
require_relative 'app_analytics'
require_relative 'app_details'
require_relative 'app_ratings'
require_relative 'app_submission'
require_relative 'app_version'
require_relative 'app_version_generated_promocodes'
require_relative 'app_version_history'
require_relative 'build_train'
require_relative 'iap'
require_relative 'tunes_base'
require_relative 'version_set'

module Spaceship
  module Tunes
    class Application < TunesBase
      # @return (String) The App identifier of this app, provided by App Store Connect
      # @example
      #   "1013943394"
      attr_accessor :apple_id

      # @return (String) The name you provided for this app (in the default language)
      # @example
      #   "Spaceship App"
      attr_accessor :name

      # @return (String) The SKU (Stock keeping unit) you provided for this app for internal tracking
      # @example
      #   "1435592086"
      attr_accessor :vendor_id

      # @return (String) The bundle_id (app identifier) of your app
      # @example
      #   "com.krausefx.app"
      attr_accessor :bundle_id

      # @return (String) Last modified
      attr_accessor :last_modified

      # @return (Integer) The number of issues provided by App Store Connect
      attr_accessor :issues_count

      # @return (String) The URL to a low resolution app icon of this app (340x340px). Might be nil
      # @example
      #   "https://is1-ssl.mzstatic.com/image/thumb/Purple7/v4/cd/a3/e2/cda3e2ac-4034-c6af-ee0c-3e4d9a0bafaa/pr_source.png/340x340bb-80.png"
      # @example
      #   nil
      attr_accessor :app_icon_preview_url

      # @return (Array) An array of all versions sets
      attr_accessor :version_sets

      attr_mapping(
        'adamId' => :apple_id,
        'name' => :name,
        'vendorId' => :vendor_id,
        'bundleId' => :bundle_id,
        'lastModifiedDate' => :last_modified,
        'issuesCount' => :issues_count,
        'iconUrl' => :app_icon_preview_url
      )

      class << self
        # @return (Array) Returns all apps available for this account
        def all
          client.applications.map { |application| self.factory(application) }
        end

        # @return (Spaceship::Tunes::Application) Returns the application matching the parameter
        #   as either the App ID or the bundle identifier
        def find(identifier, mac: false)
          all.find do |app|
            ((app.apple_id && app.apple_id.casecmp(identifier.to_s) == 0) || (app.bundle_id && app.bundle_id.casecmp(identifier.to_s) == 0)) &&
              app.version_sets.any? { |v| (mac ? ["osx"] : ["ios", "appletvos"]).include?(v.platform) }
          end
        end

        # Creates a new application on App Store Connect
        # @param name (String): The name of your app as it will appear on the App Store.
        #   This can't be longer than 255 characters.
        # @param primary_language (String): If localized app information isn't available in an
        #   App Store territory, the information from your primary language will be used instead.
        # @param version *DEPRECATED: Use `ensure_version!` method instead*
        #   (String): The version number is shown on the App Store and should match the one you used in Xcode.
        # @param sku (String): A unique ID for your app that is not visible on the App Store.
        # @param bundle_id (String): The bundle ID must match the one you used in Xcode. It
        #   can't be changed after you submit your first build.
        # @param company_name (String): The company name or developer name to display on the App Store for your apps.
        # It cannot be changed after you create your first app.
        # @param platform (String): Platform one of (ios,osx)
        #  should it be an ios or an osx app

        def create!(name: nil, primary_language: nil, version: nil, sku: nil, bundle_id: nil, bundle_id_suffix: nil, company_name: nil, platform: nil, platforms: nil, itunes_connect_users: nil)
          puts("The `version` parameter is deprecated. Use `ensure_version!` method instead") if version
          client.create_application!(name: name,
                         primary_language: primary_language,
                                      sku: sku,
                                bundle_id: bundle_id,
                                bundle_id_suffix: bundle_id_suffix,
                                company_name: company_name,
                                    platform: platform,
                                    platforms: platforms,
                                    itunes_connect_users: itunes_connect_users)
        end

        def available_bundle_ids(platform: nil)
          client.get_available_bundle_ids(platform: platform)
        end
      end

      #####################################################
      # @!group Getting information
      #####################################################

      def version_set_for_platform(platform)
        version_sets.each do |version_set|
          return version_set if version_set.platform == platform
        end
        nil
      end

      # @return (Spaceship::Tunes::AppVersion) Receive the version that is currently live on the
      #  App Store. You can't modify all values there, so be careful.
      def live_version(platform: nil)
        Spaceship::Tunes::AppVersion.find(self, self.apple_id, true, platform: platform)
      end

      # @return (Spaceship::Tunes::AppVersion) Receive the version that can fully be edited
      def edit_version(platform: nil)
        Spaceship::Tunes::AppVersion.find(self, self.apple_id, false, platform: platform)
      end

      # @return (Spaceship::Tunes::AppVersion) This will return the `edit_version` if available
      #   and fallback to the `live_version`. Use this to just access the latest data
      def latest_version(platform: nil)
        edit_version(platform: platform) || live_version(platform: platform)
      end

      # @return (String) An URL to this specific resource. You can enter this URL into your browser
      def url
        "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/ng/app/#{self.apple_id}"
      end

      def analytics
        if self.live_version.nil?
          raise 'Analytics are only available for live apps.'
        end

        attrs = {}
        attrs[:apple_id] = self.apple_id
        Spaceship::Tunes::AppAnalytics.factory(attrs)
      end

      # @return (Hash) Contains the reason for rejection.
      #  if everything is alright, the result will be
      #  `{"sectionErrorKeys"=>[], "sectionInfoKeys"=>[], "sectionWarningKeys"=>[], "replyConstraints"=>{"minLength"=>1, "maxLength"=>4000}, "appNotes"=>{"threads"=>[]}, "betaNotes"=>{"threads"=>[]}, "appMessages"=>{"threads"=>[]}}`
      def resolution_center
        client.get_resolution_center(apple_id, platform)
      end

      def reply_resolution_center(app_id, platform, thread_id, version_id, version_number, from, message_body)
        client.post_resolution_center(app_id, platform, thread_id, version_id, version_number, from, message_body)
      end

      def ratings(version_id: '', storefront: '')
        attrs = client.get_ratings(apple_id, platform, version_id, storefront)
        attrs[:application] = self
        Tunes::AppRatings.new(attrs)
      end

      def platforms
        platforms = []
        version_sets.each do |version_set|
          platforms << version_set.platform
        end
        platforms
      end

      def type
        if self.version_sets.nil?
          raise 'The application has no version sets and Spaceship does not know what to do here.'
        end

        if self.version_sets.length == 1
          version_sets[0].platform
        end
        platform = Spaceship::Tunes::AppVersionCommon.find_platform(raw_data['versionSets'])
        platform['type']
      end

      # kept for backward compatibility
      # tries to guess the platform of the currently submitted apps
      # note that as ITC now supports multiple app types, this might break
      # if your app supports more than one
      def platform
        if self.version_sets.nil?
          raise 'The application has no version sets and Spaceship does not know what to do here.'
        end

        if self.version_sets.length == 1
          version_sets[0].platform
        elsif self.platforms == %w(ios appletvos)
          'ios'
        end
        Spaceship::Tunes::AppVersionCommon.find_platform(raw_data['versionSets'])['platformString']
      end

      def details
        attrs = client.app_details(apple_id)
        attrs[:application] = self
        Tunes::AppDetails.factory(attrs)
      end

      def versions_history
        ensure_not_a_bundle
        versions = client.versions_history(apple_id, platform)
        versions.map do |attrs|
          attrs[:application] = self
          Tunes::AppVersionHistory.factory(attrs)
        end
      end

      #####################################################
      # @!group Modifying
      #####################################################

      # Create a new version of your app
      # Since we have stored the outdated raw_data, we need to refresh this object
      # otherwise `edit_version` will return nil
      def create_version!(version_number, platform: nil)
        if edit_version(platform: platform)
          raise "Cannot create a new version for this app as there already is an `edit_version` available"
        end

        client.create_version!(apple_id, version_number, platform.nil? ? 'ios' : platform)

        # Future: implemented -reload method
      end

      # Will make sure the current edit_version matches the given version number
      # This will either create a new version or change the version number
      # from an existing version
      # @return (Bool) Was something changed?
      def ensure_version!(version_number, platform: nil)
        if (e = edit_version(platform: platform))
          if e.version.to_s != version_number.to_s
            # Update an existing version
            e.version = version_number
            e.save!
            return true
          end
          return false
        else
          create_version!(version_number, platform: platform)
          return true
        end
      end

      def reject_version_if_possible!
        can_reject = edit_version.can_reject_version
        if can_reject
          client.reject!(apple_id, edit_version.version_id)
        end

        return can_reject
      end

      # set the price tier. This method doesn't require `save` to be called
      def update_price_tier!(price_tier)
        client.update_price_tier!(self.apple_id, price_tier)
      end

      # The current price tier
      def price_tier
        client.price_tier(self.apple_id)
      end

      # set the availability. This method doesn't require `save` to be called
      def update_availability!(availability)
        client.update_availability!(self.apple_id, availability)
      end

      # The current availability.
      def availability
        client.availability(self.apple_id)
      end

      #####################################################
      # @!group in_app_purchases
      #####################################################
      # Get base In-App-Purchases object
      def in_app_purchases
        attrs = {}
        attrs[:application] = self
        Tunes::IAP.factory(attrs)
      end

      #####################################################
      # @!group Builds
      #####################################################

      # TestFlight: A reference to all the build trains
      # @return [Hash] a hash, the version number and platform being the key
      def build_trains(platform: nil)
        TestFlight::BuildTrains.all(app_id: self.apple_id, platform: platform || self.platform)
      end

      # The numbers of all build trains that were uploaded
      # @return [Array] An array of train version numbers
      def all_build_train_numbers(platform: nil)
        return self.build_trains(platform: platform || self.platform).versions
      end

      # Receive the build details for a specific build
      # useful if the app is not listed in the TestFlight build list
      # which might happen if you don't use TestFlight
      # This is used to receive dSYM files from Apple
      def all_builds_for_train(train: nil, platform: nil)
        return TestFlight::Build.builds_for_train(app_id: self.apple_id, platform: platform || self.platform, train_version: train)
      end

      # @return [Array] This will return an array of *all* processing builds
      #   this include pre-processing or standard processing
      def all_processing_builds(platform: nil)
        return TestFlight::Build.all_processing_builds(app_id: self.apple_id, platform: platform || self.platform)
      end

      def tunes_all_build_trains(app_id: nil, platform: nil)
        resp = client.all_build_trains(app_id: apple_id, platform: platform)
        trains = resp["trains"] or []
        trains.map do |attrs|
          attrs['application'] = self
          Tunes::BuildTrain.factory(attrs)
        end
      end

      def tunes_all_builds_for_train(train: nil, platform: nil)
        resp = client.all_builds_for_train(app_id: apple_id, train: train, platform: platform)
        items = resp["items"] or []
        items.map do |attrs|
          attrs['apple_id'] = apple_id
          Tunes::Build.factory(attrs)
        end
      end

      def tunes_build_details(train: nil, build_number: nil, platform: nil)
        resp = client.build_details(app_id: apple_id, train: train, build_number: build_number, platform: platform)
        resp['apple_id'] = apple_id
        Tunes::BuildDetails.factory(resp)
      end

      # Get all builds that are already processed for all build trains
      # You can either use the return value (array) or pass a block
      def builds(platform: nil, &block)
        all = TestFlight::Build.all(app_id: self.apple_id, platform: platform || self.platform)
        return all unless block
        all.each(&block)
      end

      #####################################################
      # @!group Submit for Review
      #####################################################

      def create_submission(platform: nil)
        version = self.latest_version(platform: platform)
        if version.nil?
          raise "Could not find a valid version to submit for review"
        end

        Spaceship::Tunes::AppSubmission.create(self, version, platform: platform)
      end

      # Cancels all ongoing TestFlight beta submission for this application
      def cancel_all_testflight_submissions!
        self.builds do |build|
          begin
            build.cancel_beta_review!
          rescue
            # We really don't care about any errors here
          end
        end
        true
      end

      #####################################################
      # @!group release
      #####################################################

      def release!
        version = self.edit_version
        if version.nil?
          raise "Could not find a valid version to release"
        end
        version.release!
      end

      #####################################################
      # @!group release to all users
      #####################################################

      def release_to_all_users!
        version = self.live_version
        if version.nil?
          raise "Could not find a valid version to release"
        end
        version.release_to_all_users!
      end

      #####################################################
      # @!group General
      #####################################################
      def setup
        super
        @version_sets = (self.raw_data['versionSets'] || []).map do |attrs|
          attrs[:application] = self
          Tunes::VersionSet.factory(attrs)
        end
      end

      #####################################################
      # @!group Testers
      #####################################################

      def default_external_group
        TestFlight::Group.default_external_group(app_id: self.apple_id)
      end

      #####################################################
      # @!group Promo codes
      #####################################################
      def promocodes
        data = client.app_promocodes(app_id: self.apple_id)
        data.map do |attrs|
          Tunes::AppVersionPromocodes.factory(attrs)
        end
      end

      def promocodes_history
        data = client.app_promocodes_history(app_id: self.apple_id)
        data.map do |attrs|
          Tunes::AppVersionGeneratedPromocodes.factory(attrs)
        end
      end

      # private to module
      def ensure_not_a_bundle
        # we only support applications
        raise "We do not support BUNDLE types right now" if self.type == 'BUNDLE'
      end
    end
  end
end
