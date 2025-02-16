require_relative '../model'
require_relative '../../connect_api'

module Spaceship
  class ConnectAPI
    class User
      include Spaceship::ConnectAPI::Model

      attr_accessor :username
      attr_accessor :first_name
      attr_accessor :last_name
      attr_accessor :email
      attr_accessor :preferred_currency_territory
      attr_accessor :agreed_to_terms
      attr_accessor :roles
      attr_accessor :all_apps_visible
      attr_accessor :provisioning_allowed
      attr_accessor :email_vetting_required
      attr_accessor :notifications

      attr_accessor :visible_apps

      attr_mapping({
        "username" => "username",
        "firstName" => "first_name",
        "lastName" => "last_name",
        "email" => "email",
        "preferredCurrencyTerritory" => "preferred_currency_territory",
        "agreedToTerms" => "agreed_to_terms",
        "roles" => "roles",
        "allAppsVisible" => "all_apps_visible",
        "provisioningAllowed" => "provisioning_allowed",
        "emailVettingRequired" => "email_vetting_required",
        "notifications" => "notifications",

        "visibleApps" => "visible_apps"
      })

      ESSENTIAL_INCLUDES = [
        "visibleApps"
      ].join(",")

      def self.type
        return "users"
      end

      module UserRole
        ADMIN = "ADMIN"
        FINANCE = "FINANCE"
        TECHNICAL = "TECHNICAL"
        SALES = "SALES"
        MARKETING = "MARKETING"
        DEVELOPER = "DEVELOPER"
        ACCOUNT_HOLDER = "ACCOUNT_HOLDER"
        READ_ONLY = "READ_ONLY"
        APP_MANAGER = "APP_MANAGER"
        ACCESS_TO_REPORTS = "ACCESS_TO_REPORTS"
        CUSTOMER_SUPPORT = "CUSTOMER_SUPPORT"
      end

      #
      # API
      #

      def self.all(client: nil, filter: {}, includes: ESSENTIAL_INCLUDES, limit: Spaceship::ConnectAPI::MAX_OBJECTS_PER_PAGE_LIMIT, sort: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_users(filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        return resps.flat_map(&:to_models)
      end

      def self.find(client: nil, username: nil, includes: ESSENTIAL_INCLUDES)
        client ||= Spaceship::ConnectAPI
        return all(client: client, filter: { username: username }, includes: includes)
      end

      # @param client [ConnectAPI] ConnectAPI client.
      # @param all_apps_visible [Boolean] If all apps must be visible to a user. true - if a user must see all apps, you must not provide visible_app_ids, `false` - a user must see only a limited list of apps, and you must provide visible_app_ids. nil if no change is needed.
      # @param provisioning_allowed [Bool] If a user with a Developer or App Manager role must have access to Certificates, Identifiers & Profiles. true - if a user must be able to create new certificates and provisioning profiles, `false` - otherwise. nil if no change is needed.
      # @param roles [Array] Array of strings describing user roles. You can use defined constants in the UserRole, or refer to the Apple Documentation https://developer.apple.com/documentation/appstoreconnectapi/userrole . Pass nil if no change is needed.
      # @param visible_app_ids [Array] Array of strings with application identifiers the user needs access to. nil if no apps change is needed or user must have access to all apps.
      # @return (User) Modified user.
      def update(client: nil, all_apps_visible: nil, provisioning_allowed: nil, roles: nil, visible_app_ids: nil)
        client ||= Spaceship::ConnectAPI

        all_apps_visible = all_apps_visible.nil? ? self.all_apps_visible : all_apps_visible
        provisioning_allowed = provisioning_allowed.nil? ? self.provisioning_allowed : provisioning_allowed
        roles ||= self.roles
        visible_app_ids ||= self.visible_apps.map(&:id)

        resp = client.patch_user(
          user_id: self.id,
          all_apps_visible: all_apps_visible,
          provisioning_allowed: provisioning_allowed,
          roles: roles,
          visible_app_ids: visible_app_ids
        )
        return resp.to_models.first
      end

      def delete!(client: nil)
        client ||= Spaceship::ConnectAPI
        client.delete_user(user_id: id)
      end

      def get_visible_apps(client: nil, limit: nil)
        client ||= Spaceship::ConnectAPI
        resp = client.get_user_visible_apps(user_id: id, limit: limit)
        return resp.to_models
      end
    end
  end
end
