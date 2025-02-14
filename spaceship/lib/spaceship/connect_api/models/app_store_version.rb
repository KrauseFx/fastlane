require_relative '../model'
require_relative './app_store_review_detail'
require_relative './app_store_version_localization'

module Spaceship
  class ConnectAPI
    class AppStoreVersion
      include Spaceship::ConnectAPI::Model

      attr_accessor :platform
      attr_accessor :version_string
      attr_accessor :app_store_state
      attr_accessor :app_version_state
      attr_accessor :store_icon
      attr_accessor :watch_store_icon
      attr_accessor :copyright
      attr_accessor :release_type
      attr_accessor :earliest_release_date # 2020-06-17T12:00:00-07:00
      attr_accessor :is_watch_only
      attr_accessor :downloadable
      attr_accessor :created_date
      attr_accessor :review_type

      attr_accessor :app_store_version_submission
      attr_accessor :app_store_version_phased_release
      attr_accessor :app_store_review_detail
      attr_accessor :app_store_version_localizations

      attr_accessor :app_clip_default_experience

      module AppStoreState
        ACCEPTED = "ACCEPTED"
        DEVELOPER_REJECTED = "DEVELOPER_REJECTED"
        DEVELOPER_REMOVED_FROM_SALE = "DEVELOPER_REMOVED_FROM_SALE"
        IN_REVIEW = "IN_REVIEW"
        INVALID_BINARY = "INVALID_BINARY"
        METADATA_REJECTED = "METADATA_REJECTED"
        PENDING_APPLE_RELEASE = "PENDING_APPLE_RELEASE"
        PENDING_CONTRACT = "PENDING_CONTRACT"
        PENDING_DEVELOPER_RELEASE = "PENDING_DEVELOPER_RELEASE"
        PREORDER_READY_FOR_SALE = "PREORDER_READY_FOR_SALE"
        PREPARE_FOR_SUBMISSION = "PREPARE_FOR_SUBMISSION"
        PROCESSING_FOR_APP_STORE = "PROCESSING_FOR_APP_STORE"
        READY_FOR_REVIEW = "READY_FOR_REVIEW"
        READY_FOR_SALE = "READY_FOR_SALE"
        REJECTED = "REJECTED"
        REMOVED_FROM_SALE = "REMOVED_FROM_SALE"
        REPLACED_WITH_NEW_VERSION = "REPLACED_WITH_NEW_VERSION"
        WAITING_FOR_EXPORT_COMPLIANCE = "WAITING_FOR_EXPORT_COMPLIANCE"
        WAITING_FOR_REVIEW = "WAITING_FOR_REVIEW"
        NOT_APPLICABLE = "NOT_APPLICABLE"
      end

      module AppVersionState
        ACCEPTED = "ACCEPTED"
        DEVELOPER_REJECTED = "DEVELOPER_REJECTED"
        IN_REVIEW = "IN_REVIEW"
        INVALID_BINARY = "INVALID_BINARY"
        METADATA_REJECTED = "METADATA_REJECTED"
        PENDING_APPLE_RELEASE = "PENDING_APPLE_RELEASE"
        PENDING_DEVELOPER_RELEASE = "PENDING_DEVELOPER_RELEASE"
        PREPARE_FOR_SUBMISSION = "PREPARE_FOR_SUBMISSION"
        PROCESSING_FOR_DISTRIBUTION = "PROCESSING_FOR_DISTRIBUTION"
        READY_FOR_DISTRIBUTION = "READY_FOR_DISTRIBUTION"
        READY_FOR_REVIEW = "READY_FOR_REVIEW"
        REJECTED = "REJECTED"
        REPLACED_WITH_NEW_VERSION = "REPLACED_WITH_NEW_VERSION"
        WAITING_FOR_EXPORT_COMPLIANCE = "WAITING_FOR_EXPORT_COMPLIANCE"
        WAITING_FOR_REVIEW = "WAITING_FOR_REVIEW"
      end

      module ReleaseType
        AFTER_APPROVAL = "AFTER_APPROVAL"
        MANUAL = "MANUAL"
        SCHEDULED = "SCHEDULED"
      end

      module ReviewType
        APP_STORE = "APP_STORE"
        NOTARIZATION = "NOTARIZATION"
      end

      attr_mapping({
        "platform" =>  "platform",
        "versionString" =>  "version_string",
        "appStoreState" =>  "app_store_state",
        "appVersionState" => "app_version_state",
        "storeIcon" =>  "store_icon",
        "watchStoreIcon" =>  "watch_store_icon",
        "copyright" =>  "copyright",
        "releaseType" =>  "release_type",
        "earliestReleaseDate" =>  "earliest_release_date",
        "isWatchOnly" =>  "is_watch_only",
        "downloadable" =>  "downloadable",
        "createdDate" =>  "created_date",
        "reviewType" => "review_type",

        "appStoreVersionSubmission" => "app_store_version_submission",
        "build" => "build",
        "appStoreVersionPhasedRelease" => "app_store_version_phased_release",
        "appStoreReviewDetail" => "app_store_review_detail",
        "appStoreVersionLocalizations" => "app_store_version_localizations",

        "appClipDefaultExperience" => "app_clip_default_experience"
      })

      ESSENTIAL_INCLUDES = [
        "appStoreVersionSubmission",
        "build"
      ].join(",")

      def self.type
        return "appStoreVersions"
      end

      def can_reject?
        raise "No app_store_version_submission included" unless app_store_version_submission
        return app_store_version_submission.can_reject
      end

      def reject!
        return false unless can_reject?
        app_store_version_submission.delete!
        return true
      end

      #
      # API
      #

      # app,routingAppCoverage,resetRatingsRequest,appStoreVersionSubmission,appStoreVersionPhasedRelease,ageRatingDeclaration,appStoreReviewDetail,gameCenterConfiguration
      def self.get(client: nil, app_store_version_id: nil, includes: nil, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        return client.get_app_store_version(
          app_store_version_id: app_store_version_id,
          includes: includes
        ).first
      end

      def update(client: nil, attributes: nil)
        client ||= Spaceship::ConnectAPI
        attributes = reverse_attr_mapping(attributes)
        return client.patch_app_store_version(app_store_version_id: id, attributes: attributes).first
      end

      #
      # Age Rating Declaration
      #

      # @deprecated
      def fetch_age_rating_declaration(client: nil)
        raise 'AppStoreVersion no longer has AgeRatingDeclaration as of App Store Connect API 1.3 - Use AppInfo instead'
      end

      #
      # App Store Version Localizations
      #

      def create_app_store_version_localization(client: nil, attributes: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.post_app_store_version_localization(app_store_version_id: id, attributes: attributes)
        return resp.to_models.first
      end

      def get_app_store_version_localizations(client: nil, filter: {}, includes: nil, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        return Spaceship::ConnectAPI::AppStoreVersionLocalization.all(client: client, app_store_version_id: id, filter: filter, includes: includes, limit: limit, sort: sort)
      end

      #
      # App Store Review Detail
      #

      def create_app_store_review_detail(client: nil, attributes: nil)
        client ||= Spaceship::ConnectAPI
        attributes = Spaceship::ConnectAPI::AppStoreReviewDetail.reverse_attr_mapping(attributes)
        resp = client.post_app_store_review_detail(app_store_version_id: id, attributes: attributes)
        return resp.to_models.first
      end

      def fetch_app_store_review_detail(client: nil, includes: "appStoreReviewAttachments")
        client ||= Spaceship::ConnectAPI
        resp = client.get_app_store_review_detail(app_store_version_id: id, includes: includes)
        return resp.to_models.first
      end

      #
      # App Store Version Phased Releases
      #

      def fetch_app_store_version_phased_release(client: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.get_app_store_version_phased_release(app_store_version_id: id)
        return resp.to_models.first
      end

      def create_app_store_version_phased_release(client: nil, attributes: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.post_app_store_version_phased_release(app_store_version_id: id, attributes: attributes)
        return resp.to_models.first
      end

      #
      # App Store Version Submissions
      #

      def fetch_app_store_version_submission(client: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.get_app_store_version_submission(app_store_version_id: id)
        return resp.to_models.first
      end

      def create_app_store_version_submission(client: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.post_app_store_version_submission(app_store_version_id: id)
        return resp.to_models.first
      end

      #
      # App Store Version Release Requests
      #

      def create_app_store_version_release_request(client: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.post_app_store_version_release_request(app_store_version_id: id)
        return resp.to_models.first
      end

      #
      # Build
      #

      def get_build(client: nil, build_id: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.get_build(app_store_version_id: id, build_id: build_id)
        return resp.to_models.first
      end

      def select_build(client: nil, build_id: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.patch_app_store_version_with_build(app_store_version_id: id, build_id: build_id)
        return resp.to_models.first
      end

      #
      # Reset Ratings Requests
      #

      def fetch_reset_ratings_request(client: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.get_reset_ratings_request(app_store_version_id: id)
        return resp.to_models.first
      end

      def create_reset_ratings_request(client: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.post_reset_ratings_request(app_store_version_id: id)
        return resp.to_models.first
      end
    end
  end
end
