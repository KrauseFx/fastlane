require 'babosa'
require 'faraday' # HTTP Client
require 'faraday-cookie_jar'
require 'faraday_middleware'
require 'logger'
require 'tmpdir'
require 'cgi'
require 'tempfile'
require 'openssl'

require 'fastlane/version'
require_relative 'helper/net_http_generic_request'
require_relative 'helper/plist_middleware'
require_relative 'helper/rels_middleware'
require_relative 'ui'
require_relative 'errors'
require_relative 'tunes/errors'
require_relative 'globals'
require_relative 'provider'
require_relative 'stats_middleware'
require_relative 'hashcash'

Faraday::Utils.default_params_encoder = Faraday::FlatParamsEncoder

module Spaceship
  # rubocop:disable Metrics/ClassLength
  class Client
    PROTOCOL_VERSION = "QH65B2"
    USER_AGENT = "Spaceship #{Fastlane::VERSION}"
    AUTH_TYPES = ["sa", "hsa", "non-sa", "hsa2"]

    attr_reader :client

    # The user that is currently logged in
    attr_accessor :user

    # The email of the user that is currently logged in
    attr_accessor :user_email

    # The logger in which all requests are logged
    # /tmp/spaceship[time]_[pid].log by default
    attr_accessor :logger

    attr_accessor :csrf_tokens
    attr_accessor :additional_headers

    attr_accessor :provider

    # legacy support
    BasicPreferredInfoError = Spaceship::BasicPreferredInfoError
    InvalidUserCredentialsError = Spaceship::InvalidUserCredentialsError
    NoUserCredentialsError = Spaceship::NoUserCredentialsError
    ProgramLicenseAgreementUpdated = Spaceship::ProgramLicenseAgreementUpdated
    InsufficientPermissions = Spaceship::InsufficientPermissions
    UnexpectedResponse = Spaceship::UnexpectedResponse
    AppleTimeoutError = Spaceship::AppleTimeoutError
    UnauthorizedAccessError = Spaceship::UnauthorizedAccessError
    GatewayTimeoutError = Spaceship::GatewayTimeoutError
    InternalServerError = Spaceship::InternalServerError
    BadGatewayError = Spaceship::BadGatewayError
    AccessForbiddenError = Spaceship::AccessForbiddenError
    TooManyRequestsError = Spaceship::TooManyRequestsError

    def self.hostname
      raise "You must implement self.hostname"
    end

    #####################################################
    # @!group Teams + User
    #####################################################

    # @return (Array) A list of all available teams
    def teams
      user_details_data['availableProviders'].sort_by do |team|
        [
          team['name'],
          team['providerId']
        ]
      end
    end

    # Fetch the general information of the user, is used by various methods across spaceship
    # Sample return value
    # => {"associatedAccounts"=>
    #   [{"contentProvider"=>{"contentProviderId"=>11142800, "name"=>"Felix Krause", "contentProviderTypes"=>["Purple Software"]}, "roles"=>["Developer"], "lastLogin"=>1468784113000}],
    #  "sessionToken"=>{"dsId"=>"8501011116", "contentProviderId"=>18111111, "expirationDate"=>nil, "ipAddress"=>nil},
    #  "permittedActivities"=>
    #   {"EDIT"=>
    #     ["UserManagementSelf",
    #      "GameCenterTestData",
    #      "AppAddonCreation"],
    #    "REPORT"=>
    #     ["UserManagementSelf",
    #      "AppAddonCreation"],
    #    "VIEW"=>
    #     ["TestFlightAppExternalTesterManagement",
    #      ...
    #      "HelpGeneral",
    #      "HelpApplicationLoader"]},
    #  "preferredCurrencyCode"=>"EUR",
    #  "preferredCountryCode"=>nil,
    #  "countryOfOrigin"=>"AT",
    #  "isLocaleNameReversed"=>false,
    #  "feldsparToken"=>nil,
    #  "feldsparChannelName"=>nil,
    #  "hasPendingFeldsparBindingRequest"=>false,
    #  "isLegalUser"=>false,
    #  "userId"=>"1771111155",
    #  "firstname"=>"Detlef",
    #  "lastname"=>"Mueller",
    #  "isEmailInvalid"=>false,
    #  "hasContractInfo"=>false,
    #  "canEditITCUsersAndRoles"=>false,
    #  "canViewITCUsersAndRoles"=>true,
    #  "canEditIAPUsersAndRoles"=>false,
    #  "transporterEnabled"=>false,
    #  "contentProviderFeatures"=>["APP_SILOING", "PROMO_CODE_REDESIGN", ...],
    #  "contentProviderType"=>"Purple Software",
    #  "displayName"=>"Detlef",
    #  "contentProviderId"=>"18742800",
    #  "userFeatures"=>[],
    #  "visibility"=>true,
    #  "DYCVisibility"=>false,
    #  "contentProvider"=>"Felix Krause",
    #  "userName"=>"detlef@krausefx.com"}
    def user_details_data
      return @_cached_user_details if @_cached_user_details
      r = request(:get, "https://appstoreconnect.apple.com/olympus/v1/session")
      @_cached_user_details = parse_response(r)
    end

    # @return (String) The currently selected Team ID
    def team_id
      return @current_team_id if @current_team_id

      if teams.count > 1
        puts("The current user is in #{teams.count} teams. Pass a team ID or call `select_team` to choose a team. Using the first one for now.")
      end
      @current_team_id ||= user_details_data['provider']['providerId']
    end

    # Set a new team ID which will be used from now on
    def team_id=(team_id)
      # First, we verify the team actually exists, because otherwise iTC would return the
      # following confusing error message
      #
      #     invalid content provider id
      available_teams = teams.collect do |team|
        {
          team_id: team["providerId"],
          public_team_id: team["publicProviderId"],
          team_name: team["name"]
        }
      end

      result = available_teams.find do |available_team|
        team_id.to_s == available_team[:team_id].to_s
      end

      unless result
        error_string = "Could not set team ID to '#{team_id}', only found the following available teams:\n\n#{available_teams.map { |team| "- #{team[:team_id]} (#{team[:team_name]})" }.join("\n")}\n"
        raise Tunes::Error.new, error_string
      end

      response = request(:post) do |req|
        req.url("https://appstoreconnect.apple.com/olympus/v1/session")
        req.body = { "provider": { "providerId": result[:team_id] } }.to_json
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Requested-With'] = 'olympus-ui'
      end

      handle_itc_response(response.body)

      # clear user_details_data cache, as session switch will have changed sessionToken attribute
      @_cached_user_details = nil

      @current_team_id = team_id
    end

    # @return (Hash) Fetches all information of the currently used team
    def team_information
      teams.find do |t|
        t['teamId'] == team_id
      end
    end

    # @return (String) Fetches name from currently used team
    def team_name
      (team_information || {})['name']
    end

    #####################################################
    # @!group Client Init
    #####################################################

    # Instantiates a client but with a cookie derived from another client.
    #
    # HACK: since the `@cookie` is not exposed, we use this hacky way of sharing the instance.
    def self.client_with_authorization_from(another_client)
      self.new(cookie: another_client.instance_variable_get(:@cookie), current_team_id: another_client.team_id)
    end

    def initialize(cookie: nil, current_team_id: nil, csrf_tokens: nil, timeout: nil)
      options = {
       request: {
          timeout:       (ENV["SPACESHIP_TIMEOUT"] || timeout || 300).to_i,
          open_timeout:  (ENV["SPACESHIP_TIMEOUT"] || timeout || 300).to_i
        }
      }
      @current_team_id = current_team_id
      @csrf_tokens = csrf_tokens
      @cookie = cookie || HTTP::CookieJar.new

      @client = Faraday.new(self.class.hostname, options) do |c|
        c.response(:json, content_type: /\bjson$/)
        c.response(:plist, content_type: /\bplist$/)
        c.use(:cookie_jar, jar: @cookie)
        c.use(FaradayMiddleware::RelsMiddleware)
        c.use(Spaceship::StatsMiddleware)
        c.adapter(Faraday.default_adapter)

        if ENV['SPACESHIP_DEBUG']
          # for debugging only
          # This enables tracking of networking requests using Charles Web Proxy
          c.proxy = "https://127.0.0.1:8888"
          c.ssl[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
        elsif ENV["SPACESHIP_PROXY"]
          c.proxy = ENV["SPACESHIP_PROXY"]
          c.ssl[:verify_mode] = OpenSSL::SSL::VERIFY_NONE if ENV["SPACESHIP_PROXY_SSL_VERIFY_NONE"]
        end

        if ENV["DEBUG"]
          puts("To run spaceship through a local proxy, use SPACESHIP_DEBUG")
        end
      end
    end

    #####################################################
    # @!group Request Logger
    #####################################################

    # The logger in which all requests are logged
    # /tmp/spaceship[time]_[pid]_["threadid"].log by default
    def logger
      unless @logger
        if ENV["VERBOSE"]
          @logger = Logger.new(STDOUT)
        else
          # Log to file by default
          case RbConfig::CONFIG['host_os']
          when /mswin|mingw32|windows/
            path = "tmp/spaceship#{Time.now.to_i}_#{Process.pid}_#{Thread.current.object_id}.log"
          else
            path = "/tmp/spaceship#{Time.now.to_i}_#{Process.pid}_#{Thread.current.object_id}.log"
          end
          @logger = Logger.new(path)
        end

        @logger.formatter = proc do |severity, datetime, progname, msg|
          severity = format('%-5.5s', severity)
          "#{severity} [#{datetime.strftime('%H:%M:%S')}]: #{msg}\n"
        end
      end

      @logger
    end

    #####################################################
    # @!group Session Cookie
    #####################################################

    ##
    # Return the session cookie.
    #
    # @return (String) the cookie-string in the RFC6265 format: https://tools.ietf.org/html/rfc6265#section-4.2.1
    def cookie
      @cookie.map(&:to_s).join(';')
    end

    def store_cookie(path: nil)
      path ||= persistent_cookie_path
      FileUtils.mkdir_p(File.expand_path("..", path))

      # really important to specify the session to true
      # otherwise myacinfo and more won't be stored
      @cookie.save(path, :yaml, session: true)
      return File.read(path)
    end

    # This is a duplicate method of fastlane_core/fastlane_core.rb#fastlane_user_dir
    def fastlane_user_dir
      path = File.expand_path(File.join(Dir.home, ".fastlane"))
      FileUtils.mkdir_p(path) unless File.directory?(path)
      return path
    end

    # Returns preferred path for storing cookie
    # for two step verification.
    def persistent_cookie_path
      if ENV["SPACESHIP_COOKIE_PATH"]
        path = File.expand_path(File.join(ENV["SPACESHIP_COOKIE_PATH"], "spaceship", self.user, "cookie"))
      else
        [File.join(self.fastlane_user_dir, "spaceship"), "~/.spaceship", "/var/tmp/spaceship", "#{Dir.tmpdir}/spaceship"].each do |dir|
          dir_parts = File.split(dir)
          if directory_accessible?(File.expand_path(dir_parts.first))
            path = File.expand_path(File.join(dir, self.user, "cookie"))
            break
          end
        end
      end

      return path
    end

    #####################################################
    # @!group Automatic Paging
    #####################################################

    # The page size we want to request, defaults to 500
    def page_size
      @page_size ||= 500
    end

    # Handles the paging for you... for free
    # Just pass a block and use the parameter as page number
    def paging
      page = 0
      results = []
      loop do
        page += 1
        current = yield(page)

        results += current

        break if (current || []).count < page_size # no more results
      end

      return results
    end

    #####################################################
    # @!group Login and Team Selection
    #####################################################

    # Authenticates with Apple's web services. This method has to be called once
    # to generate a valid session. The session will automatically be used from then
    # on.
    #
    # This method will automatically use the username from the Appfile (if available)
    # and fetch the password from the Keychain (if available)
    #
    # @param user (String) (optional): The username (usually the email address)
    # @param password (String) (optional): The password
    #
    # @raise InvalidUserCredentialsError: raised if authentication failed
    #
    # @return (Spaceship::Client) The client the login method was called for
    def self.login(user = nil, password = nil)
      instance = self.new
      if instance.login(user, password)
        instance
      else
        raise InvalidUserCredentialsError.new, "Invalid User Credentials"
      end
    end

    # Authenticates with Apple's web services. This method has to be called once
    # to generate a valid session. The session will automatically be used from then
    # on.
    #
    # This method will automatically use the username from the Appfile (if available)
    # and fetch the password from the Keychain (if available)
    #
    # @param user (String) (optional): The username (usually the email address)
    # @param password (String) (optional): The password
    #
    # @raise InvalidUserCredentialsError: raised if authentication failed
    #
    # @return (Spaceship::Client) The client the login method was called for
    def login(user = nil, password = nil)
      if user.to_s.empty? || password.to_s.empty?
        require 'credentials_manager/account_manager'

        puts("Reading keychain entry, because either user or password were empty") if Spaceship::Globals.verbose?

        keychain_entry = CredentialsManager::AccountManager.new(user: user, password: password)
        user ||= keychain_entry.user
        password = keychain_entry.password(ask_if_missing: !Spaceship::Globals.check_session)
      end

      if user.to_s.strip.empty? || password.to_s.strip.empty?
        exit_with_session_state(user, false) if Spaceship::Globals.check_session
        raise NoUserCredentialsError.new, "No login data provided"
      end

      self.user = user
      @password = password
      begin
        do_login(user, password) # calls `send_login_request` in sub class (which then will redirect back here to `send_shared_login_request`, below)
      rescue InvalidUserCredentialsError => ex
        raise ex unless keychain_entry

        if keychain_entry.invalid_credentials
          login(user)
        else
          raise ex
        end
      end
    end

    # Check if we have a cached/valid session
    #
    # Background:
    # December 4th 2017 Apple introduced a rate limit - which is of course fine by itself -
    # but unfortunately also rate limits successful logins. If you call multiple tools in a
    # lane (e.g. call match 5 times), this would lock you out of the account for a while.
    # By loading existing sessions and checking if they're valid, we're sending less login requests.
    # More context on why this change was necessary https://github.com/fastlane/fastlane/pull/11108
    #
    def has_valid_session
      # If there was a successful manual login before, we have a session on disk
      if load_session_from_file
        # Check if the session is still valid here
        begin
          # We use the olympus session to determine if the old session is still valid
          # As this will raise an exception if the old session has expired
          # If the old session is still valid, we don't have to do anything else in this method
          # that's why we return true
          return true if fetch_olympus_session
        rescue
          # If the `fetch_olympus_session` method raises an exception
          # we'll land here, and therefore continue doing a full login process
          # This happens if the session we loaded from the cache isn't valid any more
          # which is common, as the session automatically invalidates after x hours (we don't know x)
          # In this case we don't actually care about the exact exception, and why it was failing
          # because either way, we'll have to do a fresh login, where we do the actual error handling
          puts("Available session is not valid anymore. Continuing with normal login.")
        end
      end
      #
      # The user can pass the session via environment variable (Mainly used in CI environments)
      if load_session_from_env
        # see above
        begin
          # see above
          return true if fetch_olympus_session
        rescue
          puts("Session loaded from environment variable is not valid. Continuing with normal login.")
          # see above
        end
      end
      #
      # After this point, we sure have no valid session any more and have to create a new one
      #
      return false
    end

    def do_sirp(user, password, modified_cookie)
      require 'fastlane-sirp'
      require 'base64'

      client = SIRP::Client.new(2048)
      a = client.start_authentication

      data = {
        a: Base64.strict_encode64(to_byte(a)),
        accountName: user,
        protocols: ['s2k', 's2k_fo']
      }

      response = request(:post) do |req|
        req.url("https://idmsa.apple.com/appleauth/auth/signin/init")
        req.body = data.to_json
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Requested-With'] = 'XMLHttpRequest'
        req.headers['X-Apple-Widget-Key'] = self.itc_service_key
        req.headers['Accept'] = 'application/json, text/javascript'
        req.headers["Cookie"] = modified_cookie if modified_cookie
      end

      puts("Received SIRP signin init response: #{response.body}") if Spaceship::Globals.verbose?

      body = response.body
      iterations = body["iteration"]
      salt = Base64.strict_decode64(body["salt"])
      b = Base64.strict_decode64(body["b"])
      c = body["c"]

      key_length = 32
      encrypted_password = pbkdf2(password, salt, iterations, key_length)

      m1 = client.process_challenge(
        user,
        to_hex(encrypted_password),
        to_hex(salt),
        to_hex(b),
        is_password_encrypted: true
      )
      m2 = client.H_AMK

      if m1 == false
        puts("Error processing SIRP challenge") if Spaceship::Globals.verbose?
        raise SIRPAuthenticationError
      end

      data = {
        accountName: user,
        c: c,
        m1: Base64.encode64(to_byte(m1)).strip,
        m2: Base64.encode64(to_byte(m2)).strip,
        rememberMe: false
      }

      hashcash = self.fetch_hashcash

      response = request(:post) do |req|
        req.url("https://idmsa.apple.com/appleauth/auth/signin/complete?isRememberMeEnabled=false")
        req.body = data.to_json
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Requested-With'] = 'XMLHttpRequest'
        req.headers['X-Apple-Widget-Key'] = self.itc_service_key
        req.headers['Accept'] = 'application/json, text/javascript'
        req.headers["Cookie"] = modified_cookie if modified_cookie
        req.headers["X-Apple-HC"] = hashcash if hashcash
      end

      puts("Completed SIRP authentication with status of #{response.status}") if Spaceship::Globals.verbose?

      return response
    end

    def pbkdf2(password, salt, iterations, key_length, digest = OpenSSL::Digest::SHA256.new)
      require 'openssl'
      password = OpenSSL::Digest::SHA256.digest(password)
      OpenSSL::PKCS5.pbkdf2_hmac(password, salt, iterations, key_length, digest)
    end

    def to_hex(str)
      str.unpack1('H*')
    end

    def to_byte(str)
      [str].pack('H*')
    end

    # This method is used for both the Apple Dev Portal and App Store Connect
    # This will also handle 2 step verification and 2 factor authentication
    #
    # It is called in `send_login_request` of sub classes (which the method `login`, above, transferred over to via `do_login`)
    # rubocop:disable Metrics/PerceivedComplexity
    def send_shared_login_request(user, password)
      # Check if the cache or FASTLANE_SESSION is still valid
      has_valid_session = self.has_valid_session

      # Exit if `--check_session` flag was passed
      exit_with_session_state(user, has_valid_session) if Spaceship::Globals.check_session

      # If the session is valid no need to attempt to generate a new one.
      return true if has_valid_session

      begin
        # The below workaround is only needed for 2 step verified machines
        # Due to escaping of cookie values we have a little workaround here
        # By default the cookie jar would generate the following header
        #   DES5c148...=HSARM.......xaA/O69Ws/CHfQ==SRVT
        # However we need the following
        #   DES5c148...="HSARM.......xaA/O69Ws/CHfQ==SRVT"
        # There is no way to get the cookie jar value with " around the value
        # so we manually modify the cookie (only this one) to be properly escaped
        # Afterwards we pass this value manually as a header
        # It's not enough to just modify @cookie, it needs to be done after self.cookie
        # as a string operation
        important_cookie = @cookie.store.entries.find { |a| a.name.include?("DES") }
        if important_cookie
          modified_cookie = self.cookie # returns a string of all cookies
          unescaped_important_cookie = "#{important_cookie.name}=#{important_cookie.value}"
          escaped_important_cookie = "#{important_cookie.name}=\"#{important_cookie.value}\""
          modified_cookie.gsub!(unescaped_important_cookie, escaped_important_cookie)
        end

        response = perform_login_method(user, password, modified_cookie)
      rescue UnauthorizedAccessError
        raise InvalidUserCredentialsError.new, "Invalid username and password combination. Used '#{user}' as the username."
      end

      # Now we know if the login is successful or if we need to do 2 factor

      case response.status
      when 403
        raise InvalidUserCredentialsError.new, "Invalid username and password combination. Used '#{user}' as the username."
      when 200
        fetch_olympus_session
        return response
      when 409
        # 2 step/factor is enabled for this account, first handle that
        handle_two_step_or_factor(response)
        # and then get the olympus session
        fetch_olympus_session
        return true
      else
        if (response.body || "").include?('invalid="true"')
          # User Credentials are wrong
          raise InvalidUserCredentialsError.new, "Invalid username and password combination. Used '#{user}' as the username."
        elsif response.status == 412 && AUTH_TYPES.include?(response.body["authType"])

          if try_upgrade_2fa_later(response)
            store_cookie
            return true
          end

          # Need to acknowledge Apple ID and Privacy statement - https://github.com/fastlane/fastlane/issues/12577
          # Looking for status of 412 might be enough but might be safer to keep looking only at what is being reported
          raise AppleIDAndPrivacyAcknowledgementNeeded.new, "Need to acknowledge to Apple's Apple ID and Privacy statement. " \
                                                            "Please manually log into https://appleid.apple.com (or https://appstoreconnect.apple.com) to acknowledge the statement. " \
                                                            "Your account might also be asked to upgrade to 2FA. " \
                                                            "Set SPACESHIP_SKIP_2FA_UPGRADE=1 for fastlane to automatically bypass 2FA upgrade if possible."
        elsif (response['Set-Cookie'] || "").include?("itctx")
          raise "Looks like your Apple ID is not enabled for App Store Connect, make sure to be able to login online"
        else
          info = [response.body, response['Set-Cookie']]
          raise Tunes::Error.new, info.join("\n")
        end
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def perform_login_method(user, password, modified_cookie)
      do_legacy_signin = ENV['FASTLANE_USE_LEGACY_PRE_SIRP_AUTH']
      if do_legacy_signin
        puts("Starting legacy Apple ID login") if Spaceship::Globals.verbose?

        # Fixes issue https://github.com/fastlane/fastlane/issues/21071
        # On 2023-02-23, Apple added a custom implementation
        # of hashcash to their auth flow
        # hashcash = nil
        hashcash = self.fetch_hashcash

        data = {
          accountName: user,
          password: password,
          rememberMe: true
        }

        return request(:post) do |req|
          req.url("https://idmsa.apple.com/appleauth/auth/signin")
          req.body = data.to_json
          req.headers['Content-Type'] = 'application/json'
          req.headers['X-Requested-With'] = 'XMLHttpRequest'
          req.headers['X-Apple-Widget-Key'] = self.itc_service_key
          req.headers['Accept'] = 'application/json, text/javascript'
          req.headers["Cookie"] = modified_cookie if modified_cookie
          req.headers["X-Apple-HC"] = hashcash if hashcash
        end
      else
        # Fixes issue https://github.com/fastlane/fastlane/issues/26368#issuecomment-2424190032
        puts("Starting SIRP Apple ID login") if Spaceship::Globals.verbose?
        return do_sirp(user, password, modified_cookie)
      end
    end

    def fetch_hashcash
      response = request(:get, "https://idmsa.apple.com/appleauth/auth/signin?widgetKey=#{self.itc_service_key}")
      headers = response.headers

      bits = headers["X-Apple-HC-Bits"]
      challenge = headers["X-Apple-HC-Challenge"]

      if bits.nil? || challenge.nil?
        puts("Unable to find 'X-Apple-HC-Bits' and 'X-Apple-HC-Challenge' to make hashcash")
        return nil
      end

      return Spaceship::Hashcash.make(bits: bits, challenge: challenge)
    end

    # Get the `itctx` from the new (22nd May 2017) API endpoint "olympus"
    # Update (29th March 2019) olympus migrates to new appstoreconnect API
    def fetch_olympus_session
      response = request(:get, "https://appstoreconnect.apple.com/olympus/v1/session")
      body = response.body
      if body
        body = JSON.parse(body) if body.kind_of?(String)
        user_map = body["user"]
        if user_map
          self.user_email = user_map["emailAddress"]
        end

        provider = body["provider"]
        if provider
          self.provider = Spaceship::Provider.new(provider_hash: provider)
          return true
        end
      end

      return false
    end

    # This method is used to log if the session is valid or not and then exit
    # It is called when the `--check_session` flag is passed
    def exit_with_session_state(user, has_valid_session)
      puts("#{has_valid_session ? 'Valid' : 'No valid'} session found (#{user}). Exiting.")
      exit(has_valid_session)
    end

    def itc_service_key
      return @service_key if @service_key

      # Check if we have a local cache of the key
      itc_service_key_path = "/tmp/spaceship_itc_service_key.txt"
      return File.read(itc_service_key_path) if File.exist?(itc_service_key_path)

      # Fixes issue https://github.com/fastlane/fastlane/issues/13281
      # Even though we are using https://appstoreconnect.apple.com, the service key needs to still use a
      # hostname through itunesconnect.apple.com
      response = request(:get, "https://appstoreconnect.apple.com/olympus/v1/app/config?hostname=itunesconnect.apple.com")
      @service_key = response.body["authServiceKey"].to_s

      raise "Service key is empty" if @service_key.length == 0

      # Cache the key locally
      File.write(itc_service_key_path, @service_key)

      return @service_key
    rescue => ex
      puts(ex.to_s)
      raise AppleTimeoutError.new, "Could not receive latest API key from App Store Connect, this might be a server issue."
    end

    #####################################################
    # @!group Session
    #####################################################

    def load_session_from_file
      begin
        if File.exist?(persistent_cookie_path)
          puts("Loading session from '#{persistent_cookie_path}'") if Spaceship::Globals.verbose?
          @cookie.load(persistent_cookie_path)
          return true
        end
      rescue => ex
        puts(ex.to_s)
        puts("Continuing with normal login.")
      end
      return false
    end

    def load_session_from_env
      return if self.class.spaceship_session_env.to_s.length == 0
      puts("Loading session from environment variable") if Spaceship::Globals.verbose?

      file = Tempfile.new('cookie.yml')
      file.write(self.class.spaceship_session_env.gsub("\\n", "\n"))
      file.close

      begin
        @cookie.load(file.path)
      rescue => ex
        puts("Error loading session from environment")
        puts("Make sure to pass the session in a valid format")
        raise ex
      ensure
        file.unlink
      end
    end

    # Fetch the session cookie from the environment
    # (if exists)
    def self.spaceship_session_env
      ENV["FASTLANE_SESSION"] || ENV["SPACESHIP_SESSION"]
    end

    # Get contract messages from App Store Connect's "olympus" endpoint
    def fetch_program_license_agreement_messages
      all_messages = []

      messages_request = request(:get, "https://appstoreconnect.apple.com/olympus/v1/contractMessages")
      body = messages_request.body
      if body
        body = JSON.parse(body) if body.kind_of?(String)
        body.map do |messages|
          all_messages.push(messages["message"])
        end
      end

      return all_messages
    end

    #####################################################
    # @!group Helpers
    #####################################################

    def with_retry(tries = 5, &_block)
      return yield
    rescue \
        Faraday::ConnectionFailed,
        Faraday::TimeoutError,
        BadGatewayError,
        AppleTimeoutError,
        GatewayTimeoutError,
        AccessForbiddenError => ex
      tries -= 1
      unless tries.zero?
        msg = "Timeout received: '#{ex.class}', '#{ex.message}'. Retrying after 3 seconds (remaining: #{tries})..."
        puts(msg) if Spaceship::Globals.verbose?
        logger.warn(msg)

        sleep(3) unless Object.const_defined?("SpecHelper")
        retry
      end
      raise ex # re-raise the exception
    rescue TooManyRequestsError => ex
      tries -= 1
      unless tries.zero?
        msg = "Timeout received: '#{ex.class}', '#{ex.message}'. Retrying after #{ex.retry_after} seconds (remaining: #{tries})..."
        puts(msg) if Spaceship::Globals.verbose?
        logger.warn(msg)

        sleep(ex.retry_after) unless Object.const_defined?("SpecHelper")
        retry
      end
      raise ex # re-raise the exception
    rescue \
        Faraday::ParsingError, # <h2>Internal Server Error</h2> with content type json
        InternalServerError => ex
      tries -= 1
      unless tries.zero?
        msg = "Internal Server Error received: '#{ex.class}', '#{ex.message}'. Retrying after 3 seconds (remaining: #{tries})..."
        puts(msg) if Spaceship::Globals.verbose?
        logger.warn(msg)

        sleep(3) unless Object.const_defined?("SpecHelper")
        retry
      end
      raise ex # re-raise the exception
    rescue UnauthorizedAccessError => ex
      if @loggedin && !(tries -= 1).zero?
        msg = "Auth error received: '#{ex.class}', '#{ex.message}'. Login in again then retrying after 3 seconds (remaining: #{tries})..."
        puts(msg) if Spaceship::Globals.verbose?
        logger.warn(msg)

        if self.class.spaceship_session_env.to_s.length > 0
          raise UnauthorizedAccessError.new, "Authentication error, you passed an invalid session using the environment variable FASTLANE_SESSION or SPACESHIP_SESSION"
        end

        do_login(self.user, @password)
        sleep(3) unless Object.const_defined?("SpecHelper")
        retry
      end
      raise ex # re-raise the exception
    end

    # memorize the last csrf tokens from responses
    def csrf_tokens
      @csrf_tokens || {}
    end

    def additional_headers
      @additional_headers || {}
    end

    def request(method, url_or_path = nil, params = nil, headers = {}, auto_paginate = false, &block)
      headers.merge!(csrf_tokens)
      headers.merge!(additional_headers)
      headers['User-Agent'] = USER_AGENT

      # Before encoding the parameters, log them
      log_request(method, url_or_path, params, headers, &block)

      # form-encode the params only if there are params, and the block is not supplied.
      # this is so that certain requests can be made using the block for more control
      if method == :post && params && !block_given?
        params, headers = encode_params(params, headers)
      end

      response = if auto_paginate
                   send_request_auto_paginate(method, url_or_path, params, headers, &block)
                 else
                   send_request(method, url_or_path, params, headers, &block)
                 end

      return response
    end

    def parse_response(response, expected_key = nil)
      if response.body
        # If we have an `expected_key`, select that from response.body Hash
        # Else, don't.

        # the returned error message and info, is html encoded ->  &quot;issued&quot; -> make this readable ->  "issued"
        response.body["userString"] = CGI.unescapeHTML(response.body["userString"]) if response.body["userString"]
        response.body["resultString"] = CGI.unescapeHTML(response.body["resultString"]) if response.body["resultString"]

        content = expected_key ? response.body[expected_key] : response.body
      end

      # if content (filled with whole body or just expected_key) is missing
      if content.nil?
        detect_most_common_errors_and_raise_exceptions(response.body) if response.body
        raise UnexpectedResponse, response.body
      # else if it is a hash and `resultString` includes `NotAllowed`
      elsif content.kind_of?(Hash) && (content["resultString"] || "").include?("NotAllowed")
        # example content when doing a Developer Portal action with not enough permission
        # => {"responseId"=>"e5013d83-c5cb-4ba0-bb62-734a8d56007f",
        #    "resultCode"=>1200,
        #    "resultString"=>"webservice.certificate.downloadNotAllowed",
        #    "userString"=>"You are not permitted to download this certificate.",
        #    "creationTimestamp"=>"2017-01-26T22:44:13Z",
        #    "protocolVersion"=>"QH65B2",
        #    "userLocale"=>"en_US",
        #    "requestUrl"=>"https://developer.apple.com/services-account/QH65B2/account/ios/certificate/downloadCertificateContent.action",
        #    "httpCode"=>200}
        raise_insufficient_permission_error!(additional_error_string: content["userString"])
      else
        store_csrf_tokens(response)
        content
      end
    end

    def detect_most_common_errors_and_raise_exceptions(body)
      # Check if the failure is due to missing permissions (App Store Connect)
      if body["messages"] && body["messages"]["error"].include?("Forbidden")
        raise_insufficient_permission_error!
      elsif body["messages"] && body["messages"]["error"].include?("insufficient privileges")
        # Passing a specific `caller_location` here to make sure we return the correct method
        # With the default location the error would say that `parse_response` is the caller
        raise_insufficient_permission_error!(caller_location: 3)
      elsif body.to_s.include?("Internal Server Error - Read")
        raise InternalServerError, "Received an internal server error from App Store Connect / Developer Portal, please try again later"
      elsif body.to_s.include?("Gateway Timeout - In read")
        raise GatewayTimeoutError, "Received a gateway timeout error from App Store Connect / Developer Portal, please try again later"
      elsif (body["userString"] || "").include?("Program License Agreement")
        raise ProgramLicenseAgreementUpdated, "#{body['userString']} Please manually log into your Apple Developer account to review and accept the updated agreement."
      end
    end

    # This also gets called from subclasses
    def raise_insufficient_permission_error!(additional_error_string: nil, caller_location: 2)
      # get the method name of the request that failed
      # `block in` is used very often for requests when surrounded for paging or retrying blocks
      # The ! is part of some methods when they modify or delete a resource, so we don't want to show it
      # Using `sub` instead of `delete` as we don't want to allow multiple matches
      calling_method_name = caller_locations(caller_location, 2).first.label.sub("block in", "").delete("!").strip

      # calling the computed property self.team_id can get us into an exception handling loop
      team_id = @current_team_id ? "(Team ID #{@current_team_id}) " : ""

      error_message = "User #{self.user} #{team_id}doesn't have enough permission for the following action: #{calling_method_name}"
      error_message += " (#{additional_error_string})" if additional_error_string.to_s.length > 0
      raise InsufficientPermissions, error_message
    end

    private

    def directory_accessible?(path)
      Dir.exist?(File.expand_path(path))
    end

    def do_login(user, password)
      @loggedin = false
      ret = send_login_request(user, password) # different in subclasses
      @loggedin = true
      ret
    end

    # Is called from `parse_response` to store the latest csrf_token (if available)
    def store_csrf_tokens(response)
      if response && response.headers
        tokens = response.headers.select { |k, v| %w(csrf csrf_ts).include?(k) }
        if tokens && !tokens.empty?
          @csrf_tokens = tokens
        end
      end
    end

    def log_request(method, url, params, headers = nil, &block)
      url ||= extract_key_from_block('url', &block)
      body = extract_key_from_block('body', &block)
      body_to_log = '[undefined body]'
      if body
        begin
          body = JSON.parse(body)
          # replace password in body if present
          body['password'] = '***' if body.kind_of?(Hash) && body.key?("password")
          body_to_log = body.to_json
        rescue JSON::ParserError
          # no json, no password to replace
          body_to_log = "[non JSON body]"
        end
      end
      params_to_log = Hash(params).dup # to also work with nil
      params_to_log.delete(:accountPassword) # Dev Portal
      params_to_log.delete(:theAccountPW) # iTC
      params_to_log = params_to_log.collect do |key, value|
        "{#{key}: #{value}}"
      end
      logger.info(">> #{method.upcase} #{url}: #{body_to_log} #{params_to_log.join(', ')}")
    end

    def log_response(method, url, response, headers = nil, &block)
      url ||= extract_key_from_block('url', &block)
      body = response.body.kind_of?(String) ? response.body.force_encoding(Encoding::UTF_8) : response.body
      logger.debug("<< #{method.upcase} #{url}: #{response.status} #{body}")
    end

    def extract_key_from_block(key, &block)
      if block_given?
        obj = Object.new
        class << obj
          attr_accessor :body, :headers, :params, :url, :options
          # rubocop: disable Style/TrivialAccessors
          # the block calls `url` (not `url=`) so need to define `url` method
          def url(url)
            @url = url
          end

          def options
            options_obj = Object.new
            class << options_obj
              attr_accessor :params_encoder
            end
            options_obj
          end
          # rubocop: enable Style/TrivialAccessors
        end
        obj.headers = {}
        yield(obj)
        obj.instance_variable_get("@#{key}")
      end
    end

    # Actually sends the request to the remote server
    # Automatically retries the request up to 3 times if something goes wrong
    def send_request(method, url_or_path, params, headers, &block)
      with_retry do
        response = @client.send(method, url_or_path, params, headers, &block)
        log_response(method, url_or_path, response, headers, &block)

        handle_error(response)

        if response.body.to_s.include?("<title>302 Found</title>")
          raise AppleTimeoutError.new, "Apple 302 detected - this might be temporary server error, check https://developer.apple.com/system-status/ to see if there is a known downtime"
        end

        if response.body.to_s.include?("<h3>Bad Gateway</h3>")
          raise BadGatewayError.new, "Apple 502 detected - this might be temporary server error, try again later"
        end

        return response
      end
    end

    def handle_error(response)
      case response.status
      when 401
        msg = "Auth lost"
        logger.warn(msg)
        raise UnauthorizedAccessError.new, "Unauthorized Access"
      when 403
        msg = "Access forbidden"
        logger.warn(msg)
        raise AccessForbiddenError.new, msg
      when 429
        raise TooManyRequestsError, response.to_hash
      end
    end

    def send_request_auto_paginate(method, url_or_path, params, headers, &block)
      response = send_request(method, url_or_path, params, headers, &block)
      return response unless should_process_next_rel?(response)
      last_response = response
      while last_response.env.rels[:next]
        last_response = send_request(method, last_response.env.rels[:next], params, headers, &block)
        break unless should_process_next_rel?(last_response)
        response.body['data'].concat(last_response.body['data'])
      end
      response
    end

    def should_process_next_rel?(response)
      response.body.kind_of?(Hash) && response.body['data'].kind_of?(Array)
    end

    def encode_params(params, headers)
      params = Faraday::Utils::ParamsHash[params].to_query
      headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }.merge(headers)
      return params, headers
    end
  end
  # rubocop:enable Metrics/ClassLength
end

require 'spaceship/two_step_or_factor_client'
require 'spaceship/upgrade_2fa_later_client'
