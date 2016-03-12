module Spaceship
  class PortalConstants < Spaceship::Client
    APP_ID_URL = {
        Spaceship::Portal::AppType::IOS => 'account/ios/identifiers/listAppIds.action',
        Spaceship::Portal::AppType::WEB => 'account/ios/identifiers/listWebsitePushIds.action',
        Spaceship::Portal::AppType::TVOS => 'account/ios/identifiers/listAppIds.action',
        Spaceship::Portal::AppType::MAC => 'account/mac/identifiers/listAppIds.action',
        Spaceship::Portal::AppType::PASS => 'account/ios/identifiers/listPassTypeIds.action',
        Spaceship::Portal::AppType::ICLOUD => 'account/cloudContainer/listCloudContainers.action',
        Spaceship::Portal::AppType::MERCHANT => 'account/ios/identifiers/listOMCs.action'
    }.freeze

    EXPECTED_KEY_APP_ID_URL = {
        Spaceship::Portal::AppType::IOS => 'appIds',
        Spaceship::Portal::AppType::WEB => 'websitePushIdList',
        Spaceship::Portal::AppType::TVOS => 'appIds',
        Spaceship::Portal::AppType::MAC => 'appIds',
        Spaceship::Portal::AppType::PASS => 'passTypeIdList',
        Spaceship::Portal::AppType::ICLOUD => 'cloudContainerList',
        Spaceship::Portal::AppType::MERCHANT => 'identifierList'
    }.freeze

    CREATE_APP_ID_URL = {
        Spaceship::Portal::AppType::IOS => 'account/ios/identifiers/addAppId.action',
        Spaceship::Portal::AppType::WEB => 'account/ios/identifiers/addWebsitePushId.action',
        Spaceship::Portal::AppType::TVOS => 'account/ios/identifiers/addAppId.action',
        Spaceship::Portal::AppType::MAC => 'account/mac/identifiers/addAppId.action',
        Spaceship::Portal::AppType::PASS => 'account/ios/identifiers/addPassTypeId.action',
        Spaceship::Portal::AppType::ICLOUD => 'account/cloudContainer/addCloudContainer.action',
        Spaceship::Portal::AppType::MERCHANT => 'account/ios/identifiers/addOMC.action'
    }.freeze

    DELETE_APP_ID_URL = {
        Spaceship::Portal::AppType::IOS => 'account/ios/identifiers/deleteAppId.action',
        Spaceship::Portal::AppType::WEB => 'account/ios/identifiers/deleteWebsitePushId.action',
        Spaceship::Portal::AppType::TVOS => 'account/ios/identifiers/deleteAppId.action',
        Spaceship::Portal::AppType::MAC => 'account/mac/identifiers/deleteAppId.action',
        Spaceship::Portal::AppType::PASS => 'account/ios/identifiers/deletePassTypeId.action',
        Spaceship::Portal::AppType::ICLOUD => '', # You can not delete iCloud Containers
        Spaceship::Portal::AppType::MERCHANT => 'account/ios/identifiers/deleteOMC.action'
    }.freeze
  end
  class PortalClient < Spaceship::Client
    #####################################################
    # @!group Init and Login
    #####################################################

    def self.hostname
      "https://developer.apple.com/services-account/#{PROTOCOL_VERSION}/"
    end

    # Fetches the latest API Key from the Apple Dev Portal
    def api_key
      cache_path = File.expand_path("~/Library/Caches/spaceship_api_key.txt")
      begin
        cached = File.read(cache_path)
      rescue Errno::ENOENT
      end
      return cached if cached

      landing_url = "https://developer.apple.com/membercenter/index.action"
      logger.info("GET: " + landing_url)
      headers = @client.get(landing_url).headers
      results = headers['location'].match(/.*appIdKey=(\h+)/)
      if (results || []).length > 1
        api_key = results[1]
        FileUtils.mkdir_p(File.dirname(cache_path))
        File.write(cache_path, api_key) if api_key.length == 64
        return api_key
      else
        raise "Could not find latest API Key from the Dev Portal - the server might be slow right now"
      end
    end

    def send_login_request(user, password)
      response = request(:post, "https://idmsa.apple.com/IDMSWebAuth/authenticate", {
        appleId: user,
        accountPassword: password,
        appIdKey: api_key
      })

      if (response.body || "").include?("Your Apple ID or password was entered incorrectly")
        # User Credentials are wrong
        raise InvalidUserCredentialsError.new, "Invalid username and password combination. Used '#{user}' as the username."
      elsif (response.body || "").include?("Verify your identity")
        raise "spaceship / fastlane doesn't support 2 step enabled accounts yet. Please temporary disable 2 step verification until spaceship was updated."
      end

      case response.status
      when 302
        return response
      when 200
        raise InvalidUserCredentialsError.new, "Invalid username and password combination. Used '#{user}' as the username."
      else
        # Something went wrong. Was it invalid credentials or server issue
        info = [response.body, response['Set-Cookie']]
        raise UnexpectedResponse.new, info.join("\n")
      end
    end

    # @return (Array) A list of all available teams
    def teams
      req = request(:post, "https://developerservices2.apple.com/services/QH65B2/listTeams.action")
      parse_response(req, 'teams')
    end

    # @return (String) The currently selected Team ID
    def team_id
      return @current_team_id if @current_team_id

      if teams.count > 1
        puts "The current user is in #{teams.count} teams. Pass a team ID or call `select_team` to choose a team. Using the first one for now."
      end
      @current_team_id ||= teams[0]['teamId']
    end

    # Shows a team selection for the user in the terminal. This should not be
    # called on CI systems
    def select_team
      @current_team_id = self.UI.select_team
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

    def platform_slug(platform)
      if platform == Spaceship::Portal::AppType::MAC
        Spaceship::Portal::AppType::MAC
      else
        Spaceship::Portal::AppType::IOS
      end
    end
    private :platform_slug

    #####################################################
    # @!group Apps
    #####################################################

    # <b>DEPRECATED:</b> Use <tt>apps_by_platform</tt> instead.
    def apps(mac: false)
      Helper.log.warn '`apps` is deprecated. Please use `apps_by_platform` instead.'.red
      apps_by_platform(platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def apps_by_platform(platform: nil)
      platforms = [platform]
      platforms = Spaceship::Portal::AppType::PLATFORMS if platform.nil?

      results = []

      platforms.each do |the_platform|
        output = paging do |page_number|
          r = request(:post, Spaceship::PortalConstants::APP_ID_URL[the_platform], {
              teamId: team_id,
              pageNumber: page_number,
              pageSize: page_size,
              sort: 'name=asc'
          })
          parse_response(r, Spaceship::PortalConstants::EXPECTED_KEY_APP_ID_URL[the_platform])
        end

        output.each {|app| app['appIdPlatform'] = the_platform } if Spaceship::Portal::AppType::ADD_PLATFORM.include? the_platform # We add the platform here for some of the app platform types because there response data does not include it.
        results += output
      end

      results
    end

    def details_for_app(app)
      raise 'The developer portal does not allow details the specified platform' if app.platform == Spaceship::Portal::AppType::MERCHANT or app.platform == Spaceship::Portal::AppType::ICLOUD or app.platform == Spaceship::Portal::AppType::PASS or app.platform == Spaceship::Portal::AppType::WEB

      r = request(:post, "account/#{platform_slug(app.platform)}/identifiers/getAppIdDetail.action", {
        teamId: team_id,
        appIdId: app.app_id
      })
      parse_response(r, 'appId')
    end

    def update_service_for_app(app, service)
      request(:post, service.service_uri, {
        teamId: team_id,
        displayId: app.app_id,
        featureType: service.service_id,
        featureValue: service.value
      })

      details_for_app(app)
    end

    def associate_groups_with_app(app, groups)
      request(:post, 'account/ios/identifiers/assignApplicationGroupToAppId.action', {
        teamId: team_id,
        appIdId: app.app_id,
        displayId: app.app_id,
        applicationGroups: groups.map(&:app_group_id)
      })

      details_for_app(app)
    end

    # <b>DEPRECATED:</b> Use <tt>create_app_by_platform!</tt> instead.
    def create_app!(type, name, bundle_id, mac: false)
      Helper.log.warn '`create_app!` is deprecated. Please use `create_app_by_platform!` instead.'.red
      create_app_by_platform!(type, name, bundle_id, platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def create_app_by_platform!(type, name, bundle_id, platform: Spaceship::Portal::AppType::IOS)
      ident_params = case type.to_sym
                     when :explicit
                       {
                           type: 'explicit',
                           explicitIdentifier: bundle_id,
                           appIdentifierString: bundle_id,
                           push: 'on',
                           inAppPurchase: 'on',
                           gameCenter: 'on'
                       }
                     when :wildcard
                       {
                           type: 'wildcard',
                           wildcardIdentifier: bundle_id,
                           appIdentifierString: bundle_id
                       }
                     end

      params = {
          appIdName: name,
          teamId: team_id
      }

      params.merge!(ident_params)

      ensure_csrf

      r = request(:post, Spaceship::PortalConstants::CREATE_APP_ID_URL[platform], params)
      parse_response(r, 'appId')
    end

    # <b>DEPRECATED:</b> Use <tt>delete_app_by_platform!</tt> instead.
    def delete_app!(app_id, mac: false)
      Helper.log.warn '`delete_app!` is deprecated. Please use `delete_app_by_platform!` instead.'.red
      delete_app_by_platform!(app_id, platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def delete_app_by_platform!(app_id, platform: Spaceship::Portal::AppType::IOS)
      raise 'The developer portal does not allow deleting of iCloud Container App Ids' if platform == Spaceship::Portal::AppType::ICLOUD

      r = request(:post, Spaceship::PortalConstants::DELETE_APP_ID_URL[platform], {
          teamId: team_id,
          appIdId: app_id
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
      r = request(:post, 'account/ios/identifiers/addApplicationGroup.action', {
        name: name,
        identifier: group_id,
        teamId: team_id
      })
      parse_response(r, 'applicationGroup')
    end

    def delete_app_group!(app_group_id)
      r = request(:post, 'account/ios/identifiers/deleteApplicationGroup.action', {
        teamId: team_id,
        applicationGroup: app_group_id
      })
      parse_response(r)
    end

    #####################################################
    # @!group Devices
    #####################################################

    # <b>DEPRECATED:</b> Use <tt>devices_by_platform</tt> instead.
    def devices(mac: false)
      Helper.log.warn '`devices` is deprecated. Please use `devices_by_platform` instead.'.red
      devices_by_platform(platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def devices_by_platform(platform: Spaceship::Portal::AppType::IOS)
      paging do |page_number|
        r = request(:post, "account/#{platform_slug(platform)}/device/listDevices.action", {
          teamId: team_id,
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'name=asc'
        })
        parse_response(r, 'devices')
      end
    end

    def devices_by_class(device_class)
      paging do |page_number|
        r = request(:post, 'account/ios/device/listDevices.action', {
          teamId: team_id,
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'name=asc',
          deviceClasses: device_class
        })
        parse_response(r, 'devices')
      end
    end

    # <b>DEPRECATED:</b> Use <tt>create_device_by_platform!</tt> instead.
    def create_device!(device_name, device_id, mac: false)
      Helper.log.warn '`create_device!` is deprecated. Please use `create_device_by_platform!` instead.'.red
      create_device_by_platform!(device_name, device_id, platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def create_device_by_platform!(device_name, device_id, platform: Spaceship::Portal::AppType::IOS)
      req = request(:post) do |r|
        r.url "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(platform)}/addDevice.action"
        r.params = {
            teamId: team_id,
            deviceNumber: device_id,
            name: device_name
        }
      end

      parse_response(req, 'device')
    end

    #####################################################
    # @!group Certificates
    #####################################################

    # <b>DEPRECATED:</b> Use <tt>certificates_by_platform</tt> instead.
    def certificates(types, mac: false)
      Helper.log.warn '`certificates` is deprecated. Please use `certificates_by_platform` instead.'.red
      certificates_by_platform(types, platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def certificates_by_platform(types, platform: Spaceship::Portal::AppType::IOS)
      paging do |page_number|
        r = request(:post, "account/#{platform_slug(platform)}/certificate/listCertRequests.action", {
          teamId: team_id,
          types: types.join(','),
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'certRequestStatusCode=asc'
        })
        parse_response(r, 'certRequests')
      end
    end

    def create_certificate!(type, csr, app_id = nil)
      ensure_csrf

      r = request(:post, 'account/ios/certificate/submitCertificateRequest.action', {
        teamId: team_id,
        type: type,
        csrContent: csr,
        appIdId: app_id # optional
      })
      parse_response(r, 'certRequest')
    end

    # <b>DEPRECATED:</b> Use <tt>download_certificate_by_platform</tt> instead.
    def download_certificate(certificate_id, type, mac: false)
      Helper.log.warn '`download_certificate` is deprecated. Please use `download_certificate_by_platform` instead.'.red
      download_certificate_by_platform(certificate_id, type, platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def download_certificate_by_platform(certificate_id, type, platform: Spaceship::Portal::AppType::IOS)
      { type: type, certificate_id: certificate_id }.each { |k, v| raise "#{k} must not be nil" if v.nil? }

      r = request(:get, "account/#{platform_slug(platform)}/certificate/downloadCertificateContent.action", {
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

    # <b>DEPRECATED:</b> Use <tt>revoke_certificate_by_platform!</tt> instead.
    def revoke_certificate!(certificate_id, type, mac: false)
      Helper.log.warn '`revoke_certificate!` is deprecated. Please use `revoke_certificate_by_platform!` instead.'.red
      revoke_certificate_by_platform!(certificate_id, type, platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def revoke_certificate_by_platform!(certificate_id, type, platform: Spaceship::Portal::AppType::IOS)
      r = request(:post, "account/#{platform_slug(platform)}/certificate/revokeCertificate.action", {
          teamId: team_id,
          certificateId: certificate_id,
          type: type
      })
      parse_response(r, 'certRequests')
    end

    #####################################################
    # @!group Provisioning Profiles
    #####################################################

    # <b>DEPRECATED:</b> Use <tt>provisioning_profiles_by_platform</tt> instead.
    def provisioning_profiles(mac: false)
      Helper.log.warn '`provisioning_profiles` is deprecated. Please use `provisioning_profiles_by_platform` instead.'.red
      provisioning_profiles_by_platform(platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def provisioning_profiles_by_platform(platform: Spaceship::Portal::AppType::IOS)
      req = request(:post) do |r|
        r.url "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(platform)}/listProvisioningProfiles.action"
        r.params = {
            teamId: team_id,
            includeInactiveProfiles: true,
            onlyCountLists: true
        }
      end

      parse_response(req, 'provisioningProfiles')
    end

    # <b>DEPRECATED:</b> Use <tt>create_provisioning_profile_by_platform!</tt> instead.
    def create_provisioning_profile!(name, distribution_method, app_id, certificate_ids, device_ids, mac: false)
      Helper.log.warn '`create_provisioning_profile!` is deprecated. Please use `create_provisioning_profile_by_platform!` instead.'.red
      create_provisioning_profile_by_platform!(name, distribution_method, app_id, certificate_ids, device_ids, platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def create_provisioning_profile_by_platform!(name, distribution_method, app_id, certificate_ids, device_ids, platform: Spaceship::Portal::AppType::IOS, sub_platform: nil)
      ensure_csrf

      params = {
          teamId: team_id,
          provisioningProfileName: name,
          appIdId: app_id,
          distributionType: distribution_method,
          certificateIds: certificate_ids,
          deviceIds: device_ids
      }

      params[:subPlatform] = sub_platform unless sub_platform.nil?

      r = request(:post, "account/#{platform_slug(platform)}/profile/createProvisioningProfile.action", params)
      parse_response(r, 'provisioningProfile')
    end

    # <b>DEPRECATED:</b> Use <tt>create_provisioning_profile_by_platform!</tt> instead.
    def download_provisioning_profile(profile_id, mac: false)
      Helper.log.warn '`download_provisioning_profile` is deprecated. Please use `download_provisioning_profile_by_platform` instead.'.red
      download_provisioning_profile_by_platform(profile_id, platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def download_provisioning_profile_by_platform(profile_id, platform: Spaceship::Portal::AppType::IOS)
      r = request(:get, "account/#{platform_slug(platform)}/profile/downloadProfileContent", {
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

    # <b>DEPRECATED:</b> Use <tt>delete_provisioning_profile_by_platform!</tt> instead.
    def delete_provisioning_profile!(profile_id, mac: false)
      Helper.log.warn '`delete_provisioning_profile!` is deprecated. Please use `delete_provisioning_profile_by_platform!` instead.'.red
      delete_provisioning_profile_by_platform!(profile_id, platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def delete_provisioning_profile_by_platform!(profile_id, platform: Spaceship::Portal::AppType::IOS)
      ensure_csrf

      r = request(:post, "account/#{platform_slug(platform)}/profile/deleteProvisioningProfile.action", {
        teamId: team_id,
        provisioningProfileId: profile_id
      })
      parse_response(r)
    end

    # <b>DEPRECATED:</b> Use <tt>repair_provisioning_profile_by_platform!</tt> instead.
    def repair_provisioning_profile!(profile_id, name, distribution_method, app_id, certificate_ids, device_ids, mac: false)
      Helper.log.warn '`repair_provisioning_profile!` is deprecated. Please use `repair_provisioning_profile_by_platform!` instead.'.red
      repair_provisioning_profile_by_platform!(profile_id, name, distribution_method, app_id, certificate_ids, device_ids, platform: mac ? Spaceship::Portal::AppType::MAC : Spaceship::Portal::AppType::IOS)
    end

    def repair_provisioning_profile_by_platform!(profile_id, name, distribution_method, app_id, certificate_ids, device_ids, platform: Spaceship::Portal::AppType::IOS)
      r = request(:post, "account/#{platform_slug(platform)}/profile/regenProvisioningProfile.action", {
        teamId: team_id,
        provisioningProfileId: profile_id,
        provisioningProfileName: name,
        appIdId: app_id,
        distributionType: distribution_method,
        certificateIds: certificate_ids.join(','),
        deviceIds: device_ids
      })

      parse_response(r, 'provisioningProfile')
    end

    private

    def ensure_csrf
      if csrf_tokens.count == 0
        # If we directly create a new resource (e.g. app) without querying anything before
        # we don't have a valid csrf token, that's why we have to do at least one request
        apps
      end
    end
  end
end
