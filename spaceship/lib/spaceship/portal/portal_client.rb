require_relative '../client'

require_relative 'app'
require_relative 'app_group'
require_relative 'cloud_container'
require_relative 'device'
require_relative 'merchant'
require_relative 'passbook'
require_relative 'provisioning_profile'
require_relative 'certificate'
require_relative 'website_push'
require_relative 'persons'

module Spaceship
  # rubocop:disable Metrics/ClassLength
  class PortalClient < Spaceship::Client
    #####################################################
    # @!group Init and Login
    #####################################################

    PROTOCOL_VERSION = Spaceship::Client::PROTOCOL_VERSION

    def self.hostname
      "https://developer.apple.com/services-account/#{PROTOCOL_VERSION}/"
    end

    def send_login_request(user, password)
      response = send_shared_login_request(user, password)
      return response if self.cookie.include?("myacinfo")

      # When the user has 2 step enabled, we might have to call this method again
      # This only occurs when the user doesn't have a team on App Store Connect
      # For 2 step verification we use the App Store Connect back-end
      # which is enough to get the DES... cookie, however we don't get a valid
      # myacinfo cookie at that point. That means, after getting the DES... cookie
      # we have to send the login request again. This will then get us a valid myacinfo
      # cookie, additionally to the DES... cookie
      return send_shared_login_request(user, password)
    end

    # @return (Array) A list of all available teams
    def teams
      return @teams if @teams
      req = request(:post, "account/listTeams.action")
      @teams = parse_response(req, 'teams').sort_by do |team|
        [
          team['name'],
          team['teamId']
        ]
      end
    end

    # @return (String) The currently selected Team ID
    def team_id
      return @current_team_id if @current_team_id

      if teams.count > 1
        puts("The current user is in #{teams.count} teams. Pass a team ID or call `select_team` to choose a team. Using the first one for now.")
      end

      if teams.count == 0
        raise "User '#{user}' does not have access to any teams with an active membership"
      end
      @current_team_id ||= teams[0]['teamId']
    end

    # Shows a team selection for the user in the terminal. This should not be
    # called on CI systems
    #
    # @param team_id (String) (optional): The ID of a Developer Portal team
    # @param team_name (String) (optional): The name of a Developer Portal team
    def select_team(team_id: nil, team_name: nil)
      @current_team_id = self.UI.select_team(team_id: team_id, team_name: team_name)
    end

    # Set a new team ID which will be used from now on
    def team_id=(team_id)
      @current_team_id = team_id
    end

    # @return (Hash) Fetches all information of the currently used team
    def team_information
      teams.find do |t|
        t['teamId'] == team_id
      end
    end

    # Is the current session from an Enterprise In House account?
    def in_house?
      return @in_house unless @in_house.nil?
      @in_house = (team_information['type'] == 'In-House')
    end

    def platform_slug(mac)
      if mac
        'mac'
      else
        'ios'
      end
    end
    private :platform_slug

    def list_pending_agreements(language: "en")
      r = request(:post) do |req|
        req.url("account/listPendingAgreements")
        req.body = {
          teamId: team_id,
          languageIsoCode: language
        }.to_json
        req.headers['Content-Type'] = 'application/json'
      end

      return parse_response(r)
    end

    #####################################################
    # @!group Apps
    #####################################################

    def apps(mac: false)
      paging do |page_number|
        r = request(:post, "account/#{platform_slug(mac)}/identifiers/listAppIds.action", {
          teamId: team_id,
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'name=asc'
        })
        parse_response(r, 'appIds')
      end
    end

    def details_for_app(app)
      r = request(:post, "account/#{platform_slug(app.mac?)}/identifiers/getAppIdDetail.action", {
        teamId: team_id,
        appIdId: app.app_id
      })
      parse_response(r, 'appId')
    end

    def update_service_for_app(app, service)
      ensure_csrf(Spaceship::Portal::App)

      request(:post, service.service_uri, {
        teamId: team_id,
        displayId: app.app_id,
        featureType: service.service_id,
        featureValue: service.value
      })

      details_for_app(app)
    end

    def associate_groups_with_app(app, groups)
      ensure_csrf(Spaceship::Portal::AppGroup)

      request(:post, 'account/ios/identifiers/assignApplicationGroupToAppId.action', {
        teamId: team_id,
        appIdId: app.app_id,
        displayId: app.app_id,
        applicationGroups: groups.map(&:app_group_id)
      })

      details_for_app(app)
    end

    def associate_cloud_containers_with_app(app, containers)
      ensure_csrf(Spaceship::Portal::CloudContainer)

      request(:post, 'account/ios/identifiers/assignCloudContainerToAppId.action', {
          teamId: team_id,
          appIdId: app.app_id,
          cloudContainers: containers.map(&:cloud_container)
      })

      details_for_app(app)
    end

    def associate_merchants_with_app(app, merchants, mac)
      ensure_csrf(Spaceship::Portal::Merchant)

      request(:post, "account/#{platform_slug(mac)}/identifiers/assignOMCToAppId.action", {
        teamId: team_id,
        appIdId: app.app_id,
        omcIds: merchants.map(&:merchant_id)
      })

      details_for_app(app)
    end

    def valid_name_for(input)
      latinized = input.to_slug.transliterate
      latinized = latinized.gsub(/[^0-9A-Za-z\d\s]/, '') # remove non-valid characters
      # Check if the input string was modified, since it might be empty now
      # (if it only contained non-latin symbols) or the duplicate of another app
      if latinized != input
        latinized << " "
        latinized << Digest::MD5.hexdigest(input)
      end
      latinized
    end

    def create_app!(type, name, bundle_id, mac: false, enable_services: {})
      # We moved the ensure_csrf to the top of this method
      # as we got some users with issues around creating new apps
      # https://github.com/fastlane/fastlane/issues/5813
      ensure_csrf(Spaceship::Portal::App)

      ident_params = case type.to_sym
                     when :explicit
                       {
                         type: 'explicit',
                         identifier: bundle_id,
                         inAppPurchase: 'on',
                         gameCenter: 'on'
                       }
                     when :wildcard
                       {
                         type: 'wildcard',
                         identifier: bundle_id
                       }
                     end

      params = {
        name: valid_name_for(name),
        teamId: team_id
      }
      params.merge!(ident_params)
      enable_services.each do |k, v|
        params[v.service_id.to_sym] = v.value
      end
      r = request(:post, "account/#{platform_slug(mac)}/identifiers/addAppId.action", params)
      parse_response(r, 'appId')
    end

    def delete_app!(app_id, mac: false)
      ensure_csrf(Spaceship::Portal::App)

      r = request(:post, "account/#{platform_slug(mac)}/identifiers/deleteAppId.action", {
        teamId: team_id,
        appIdId: app_id
      })
      parse_response(r)
    end

    def update_app_name!(app_id, name, mac: false)
      ensure_csrf(Spaceship::Portal::App)

      r = request(:post, "account/#{platform_slug(mac)}/identifiers/updateAppIdName.action", {
        teamId: team_id,
        appIdId: app_id,
        name: valid_name_for(name)
      })
      parse_response(r, 'appId')
    end

    #####################################################
    # @!group Passbook
    #####################################################

    def passbooks
      paging do |page_number|
        r = request(:post, "account/ios/identifiers/listPassTypeIds.action", {
          teamId: team_id,
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'name=asc'
        })
        parse_response(r, 'passTypeIdList')
      end
    end

    def create_passbook!(name, bundle_id)
      ensure_csrf(Spaceship::Portal::Passbook)

      r = request(:post, "account/ios/identifiers/addPassTypeId.action", {
          name: name,
          identifier: bundle_id,
          teamId: team_id
      })
      parse_response(r, 'passTypeId')
    end

    def delete_passbook!(passbook_id)
      ensure_csrf(Spaceship::Portal::Passbook)

      r = request(:post, "account/ios/identifiers/deletePassTypeId.action", {
          teamId: team_id,
          passTypeId: passbook_id
      })
      parse_response(r)
    end

    #####################################################
    # @!group Website Push
    #####################################################

    def website_push(mac: false)
      paging do |page_number|
        r = request(:post, "account/#{platform_slug(mac)}/identifiers/listWebsitePushIds.action", {
            teamId: team_id,
            pageNumber: page_number,
            pageSize: page_size,
            sort: 'name=asc'
        })
        parse_response(r, 'websitePushIdList')
      end
    end

    def create_website_push!(name, bundle_id, mac: false)
      ensure_csrf(Spaceship::Portal::WebsitePush)

      r = request(:post, "account/#{platform_slug(mac)}/identifiers/addWebsitePushId.action", {
          name: name,
          identifier: bundle_id,
          teamId: team_id
      })
      parse_response(r, 'websitePushId')
    end

    def delete_website_push!(website_id, mac: false)
      ensure_csrf(Spaceship::Portal::WebsitePush)

      r = request(:post, "account/#{platform_slug(mac)}/identifiers/deleteWebsitePushId.action", {
          teamId: team_id,
          websitePushId: website_id
      })
      parse_response(r)
    end

    #####################################################
    # @!group Merchant
    #####################################################

    def merchants(mac: false)
      paging do |page_number|
        r = request(:post, "account/#{platform_slug(mac)}/identifiers/listOMCs.action", {
            teamId: team_id,
            pageNumber: page_number,
            pageSize: page_size,
            sort: 'name=asc'
        })
        parse_response(r, 'identifierList')
      end
    end

    def create_merchant!(name, bundle_id, mac: false)
      ensure_csrf(Spaceship::Portal::Merchant)

      r = request(:post, "account/#{platform_slug(mac)}/identifiers/addOMC.action", {
          name: name,
          identifier: bundle_id,
          teamId: team_id
      })
      parse_response(r, 'omcId')
    end

    def delete_merchant!(merchant_id, mac: false)
      ensure_csrf(Spaceship::Portal::Merchant)

      r = request(:post, "account/#{platform_slug(mac)}/identifiers/deleteOMC.action", {
          teamId: team_id,
          omcId: merchant_id
      })
      parse_response(r)
    end

    #####################################################
    # @!group App Groups
    #####################################################

    def app_groups
      paging do |page_number|
        r = request(:post, 'account/ios/identifiers/listApplicationGroups.action', {
          teamId: team_id,
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'name=asc'
        })
        parse_response(r, 'applicationGroupList')
      end
    end

    def create_app_group!(name, group_id)
      ensure_csrf(Spaceship::Portal::AppGroup)

      r = request(:post, 'account/ios/identifiers/addApplicationGroup.action', {
        name: valid_name_for(name),
        identifier: group_id,
        teamId: team_id
      })
      parse_response(r, 'applicationGroup')
    end

    def delete_app_group!(app_group_id)
      ensure_csrf(Spaceship::Portal::AppGroup)

      r = request(:post, 'account/ios/identifiers/deleteApplicationGroup.action', {
        teamId: team_id,
        applicationGroup: app_group_id
      })
      parse_response(r)
    end

    #####################################################
    # @!group Cloud Containers
    #####################################################

    def cloud_containers
      paging do |page_number|
        r = request(:post, 'account/cloudContainer/listCloudContainers.action', {
            teamId: team_id,
            pageNumber: page_number,
            pageSize: page_size,
            sort: 'name=asc'
        })
        result = parse_response(r, 'cloudContainerList')

        csrf_cache[Spaceship::Portal::CloudContainer] = self.csrf_tokens

        result
      end
    end

    def create_cloud_container!(name, identifier)
      ensure_csrf(Spaceship::Portal::CloudContainer)

      r = request(:post, 'account/cloudContainer/addCloudContainer.action', {
          name: valid_name_for(name),
          identifier: identifier,
          teamId: team_id
      })
      parse_response(r, 'cloudContainer')
    end

    #####################################################
    # @!group Team
    #####################################################
    def team_members
      response = request(:post) do |req|
        req.url("/services-account/#{PROTOCOL_VERSION}/account/getTeamMembers")
        req.body = {
          teamId: team_id
        }.to_json
        req.headers['Content-Type'] = 'application/json'
      end
      parse_response(response)
    end

    def team_invited
      response = request(:post) do |req|
        req.url("/services-account/#{PROTOCOL_VERSION}/account/getInvites")
        req.body = {
          teamId: team_id
        }.to_json
        req.headers['Content-Type'] = 'application/json'
      end
      parse_response(response)
    end

    def team_set_role(team_member_id, role)
      ensure_csrf(Spaceship::Portal::Persons)
      response = request(:post) do |req|
        req.url("/services-account/#{PROTOCOL_VERSION}/account/setTeamMemberRoles")
        req.body = {
          teamId: team_id,
          role: role,
          teamMemberIds: [team_member_id]
        }.to_json
        req.headers['Content-Type'] = 'application/json'
      end
      parse_response(response)
    end

    def team_remove_member!(team_member_id)
      ensure_csrf(Spaceship::Portal::Persons)
      response = request(:post) do |req|
        req.url("/services-account/#{PROTOCOL_VERSION}/account/removeTeamMembers")
        req.body = {
          teamId: team_id,
          teamMemberIds: [team_member_id]
        }.to_json
        req.headers['Content-Type'] = 'application/json'
      end
      parse_response(response)
    end

    def team_invite(email, role)
      ensure_csrf(Spaceship::Portal::Persons)
      response = request(:post) do |req|
        req.url("/services-account/#{PROTOCOL_VERSION}/account/sendInvites")
        req.body = {
          invites: [
            { recipientEmail: email, recipientRole: role }
          ],
          teamId: team_id
        }.to_json
        req.headers['Content-Type'] = 'application/json'
      end
      parse_response(response)
    end

    #####################################################
    # @!group Devices
    #####################################################

    def devices(mac: false, include_disabled: false)
      paging do |page_number|
        r = request(:post, "account/#{platform_slug(mac)}/device/listDevices.action", {
          teamId: team_id,
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'name=asc',
          includeRemovedDevices: include_disabled
        })
        result = parse_response(r, 'devices')

        csrf_cache[Spaceship::Portal::Device] = self.csrf_tokens

        result
      end
    end

    def devices_by_class(device_class, include_disabled: false)
      paging do |page_number|
        r = request(:post, 'account/ios/device/listDevices.action', {
          teamId: team_id,
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'name=asc',
          deviceClasses: device_class,
          includeRemovedDevices: include_disabled
        })
        parse_response(r, 'devices')
      end
    end

    def create_device!(device_name, device_id, mac: false)
      ensure_csrf(Spaceship::Portal::Device)

      req = request(:post, "account/#{platform_slug(mac)}/device/addDevices.action", {
        teamId: team_id,
        deviceClasses: mac ? 'mac' : 'iphone',
        deviceNumbers: device_id,
        deviceNames: device_name,
        register: 'single'
      })

      devices = parse_response(req, 'devices')
      return devices.first unless devices.empty?

      validation_messages = parse_response(req, 'validationMessages').map { |message| message["validationUserMessage"] }.compact.uniq

      raise UnexpectedResponse.new, validation_messages.join('\n') unless validation_messages.empty?
      raise UnexpectedResponse.new, "Couldn't register new device, got this: #{parse_response(req)}"
    end

    def disable_device!(device_id, device_udid, mac: false)
      request(:post, "https://developer.apple.com/services-account/#{PROTOCOL_VERSION}/account/#{platform_slug(mac)}/device/deleteDevice.action", {
        teamId: team_id,
        deviceId: device_id
      })
    end

    def enable_device!(device_id, device_udid, mac: false)
      req = request(:post, "https://developer.apple.com/services-account/#{PROTOCOL_VERSION}/account/#{platform_slug(mac)}/device/enableDevice.action", {
          teamId: team_id,
          displayId: device_id,
          deviceNumber: device_udid
      })
      parse_response(req, 'device')
    end

    #####################################################
    # @!group Certificates
    #####################################################

    def certificates(types, mac: false)
      paging do |page_number|
        r = request(:post, "account/#{platform_slug(mac)}/certificate/listCertRequests.action", {
          teamId: team_id,
          types: types.join(','),
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'certRequestStatusCode=asc'
        })
        parse_response(r, 'certRequests')
      end
    end

    def create_certificate!(type, csr, app_id = nil, mac = false)
      ensure_csrf(Spaceship::Portal::Certificate)

      r = request(:post, "account/#{platform_slug(mac)}/certificate/submitCertificateRequest.action", {
        teamId: team_id,
        type: type,
        csrContent: csr,
        appIdId: app_id, # optional
        specialIdentifierDisplayId: app_id # For requesting Web Push certificates
      })
      parse_response(r, 'certRequest')
    end

    def download_certificate(certificate_id, type, mac: false)
      { type: type, certificate_id: certificate_id }.each { |k, v| raise "#{k} must not be nil" if v.nil? }

      r = request(:get, "account/#{platform_slug(mac)}/certificate/downloadCertificateContent.action", {
        teamId: team_id,
        certificateId: certificate_id,
        type: type
      })
      a = parse_response(r)
      if r.success? && a.include?("Apple Inc")
        return a
      else
        raise UnexpectedResponse.new, "Couldn't download certificate, got this instead: #{a}"
      end
    end

    def revoke_certificate!(certificate_id, type, mac: false)
      ensure_csrf(Spaceship::Portal::Certificate)

      r = request(:post, "account/#{platform_slug(mac)}/certificate/revokeCertificate.action", {
        teamId: team_id,
        certificateId: certificate_id,
        type: type
      })
      parse_response(r, 'certRequests')
    end

    #####################################################
    # @!group Provisioning Profiles
    #####################################################

    def provisioning_profiles(mac: false)
      paging do |page_number|
        req = request(:post, "account/#{platform_slug(mac)}/profile/listProvisioningProfiles.action", {
          teamId: team_id,
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'name=asc',
          includeInactiveProfiles: true,
          onlyCountLists: true
        })

        result = parse_response(req, 'provisioningProfiles')

        csrf_cache[Spaceship::Portal::ProvisioningProfile] = self.csrf_tokens

        result
      end
    end

    ##
    # this endpoint is used by Xcode to fetch provisioning profiles.
    # The response is an xml plist but has the added benefit of containing the appId of each provisioning profile.
    #
    # Use this method over `provisioning_profiles` if possible because no secondary API calls are necessary to populate the ProvisioningProfile data model.
    def provisioning_profiles_via_xcode_api(mac: false)
      req = request(:post) do |r|
        r.url("https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/listProvisioningProfiles.action")
        r.params = {
          teamId: team_id,
          includeInactiveProfiles: true,
          includeExpiredProfiles: true,
          onlyCountLists: true
        }
      end

      result = parse_response(req, 'provisioningProfiles')

      csrf_cache[Spaceship::Portal::ProvisioningProfile] = self.csrf_tokens

      result
    end

    def provisioning_profile_details(provisioning_profile_id: nil, mac: false)
      r = request(:post, "account/#{platform_slug(mac)}/profile/getProvisioningProfile.action", {
        teamId: team_id,
        provisioningProfileId: provisioning_profile_id
      })
      parse_response(r, 'provisioningProfile')
    end

    def create_provisioning_profile!(name, distribution_method, app_id, certificate_ids, device_ids, mac: false, sub_platform: nil, template_name: nil)
      ensure_csrf(Spaceship::Portal::ProvisioningProfile) do
        fetch_csrf_token_for_provisioning
      end

      params = {
        teamId: team_id,
        provisioningProfileName: name,
        appIdId: app_id,
        distributionType: distribution_method,
        certificateIds: certificate_ids,
        deviceIds: device_ids
      }
      params[:subPlatform] = sub_platform if sub_platform

      # if `template_name` is nil, Default entitlements will be used
      params[:template] = template_name if template_name

      r = request(:post, "account/#{platform_slug(mac)}/profile/createProvisioningProfile.action", params)
      parse_response(r, 'provisioningProfile')
    end

    def download_provisioning_profile(profile_id, mac: false)
      ensure_csrf(Spaceship::Portal::ProvisioningProfile) do
        fetch_csrf_token_for_provisioning
      end

      r = request(:get, "account/#{platform_slug(mac)}/profile/downloadProfileContent", {
        teamId: team_id,
        provisioningProfileId: profile_id
      })
      a = parse_response(r)
      if r.success? && a.include?("DOCTYPE plist PUBLIC")
        return a
      else
        raise UnexpectedResponse.new, "Couldn't download provisioning profile, got this instead: #{a}"
      end
    end

    def delete_provisioning_profile!(profile_id, mac: false)
      fetch_csrf_token_for_provisioning
      r = request(:post, "account/#{platform_slug(mac)}/profile/deleteProvisioningProfile.action", {
        teamId: team_id,
        provisioningProfileId: profile_id
      })
      parse_response(r)
    end

    def repair_provisioning_profile!(profile_id, name, distribution_method, app_id, certificate_ids, device_ids, mac: false, sub_platform: nil, template_name: nil)
      fetch_csrf_token_for_provisioning

      params = {
          teamId: team_id,
          provisioningProfileId: profile_id,
          provisioningProfileName: name,
          appIdId: app_id,
          distributionType: distribution_method,
          certificateIds: certificate_ids.join(','),
          deviceIds: device_ids
      }
      params[:subPlatform] = sub_platform if sub_platform
      # if `template_name` is nil, Default entitlements will be used
      params[:template] = template_name if template_name

      r = request(:post, "account/#{platform_slug(mac)}/profile/regenProvisioningProfile.action", params)

      parse_response(r, 'provisioningProfile')
    end

    #####################################################
    # @!group Keys
    #####################################################

    def list_keys
      paging do |page_number|
        response = request(:post, 'account/auth/key/list', {
          teamId: team_id,
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'name=asc'
        })
        parse_response(response, 'keys')
      end
    end

    def get_key(id: nil)
      response = request(:post, 'account/auth/key/get', { teamId: team_id, keyId: id })
      # response contains a list of keys with 1 item
      parse_response(response, 'keys').first
    end

    def download_key(id: nil)
      response = request(:get, 'account/auth/key/download', { teamId: team_id, keyId: id })
      parse_response(response)
    end

    def create_key!(name: nil, service_configs: nil)
      fetch_csrf_token_for_keys

      params = {
        name: name,
        serviceConfigurations: service_configs,
        teamId: team_id
      }

      response = request(:post, 'account/auth/key/create') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = params.to_json
      end

      # response contains a list of keys with 1 item
      parse_response(response, 'keys').first
    end

    def revoke_key!(id: nil)
      fetch_csrf_token_for_keys
      response = request(:post, 'account/auth/key/revoke', { teamId: team_id, keyId: id })
      parse_response(response)
    end

    private

    # This is a cache of entity type (App, AppGroup, Certificate, Device) to csrf_tokens
    def csrf_cache
      @csrf_cache ||= {}
    end

    # Ensures that there are csrf tokens for the appropriate entity type
    # Relies on store_csrf_tokens to set csrf_tokens to the appropriate value
    # then stores that in the correct place in cache
    # This method also takes a block, if you want to send a custom request, instead of
    # calling `.all` on the given klass. This is used for provisioning profiles.
    def ensure_csrf(klass)
      if csrf_cache[klass]
        self.csrf_tokens = csrf_cache[klass]
        return
      end

      self.csrf_tokens = nil

      # If we directly create a new resource (e.g. app) without querying anything before
      # we don't have a valid csrf token, that's why we have to do at least one request
      block_given? ? yield : klass.all

      csrf_cache[klass] = self.csrf_tokens
    end

    # We need a custom way to fetch the csrf token for the provisioning profile requests, since
    # we use a separate API endpoint (host of Xcode API) to fetch the provisioning profiles
    # All we do is fetch one profile (if exists) to get a valid csrf token with its time stamp
    # This method is being called from all requests that modify, create or downloading provisioning
    # profiles.
    # Source https://github.com/fastlane/fastlane/issues/5903
    def fetch_csrf_token_for_provisioning(mac: false)
      response = request(:post, "account/#{platform_slug(mac)}/profile/listProvisioningProfiles.action", {
         teamId: team_id,
         pageNumber: 1,
         pageSize: 1,
         sort: 'name=asc'
       })

      parse_response(response, 'provisioningProfiles')
      return nil
    end

    def fetch_csrf_token_for_keys
      response = request(:post, 'account/auth/key/list', {
         teamId: team_id,
         pageNumber: 1,
         pageSize: 1,
         sort: 'name=asc'
       })

      parse_response(response, 'keys')
      return nil
    end
  end
  # rubocop:enable Metrics/ClassLength
end
