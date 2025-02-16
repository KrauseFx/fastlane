
require_relative '../client'
require_relative './response'
require_relative '../client'
require_relative './response'
require_relative './token_refresh_middleware'

require_relative '../stats_middleware'

module Spaceship
  class ConnectAPI
    class APIClient < Spaceship::Client
      attr_accessor :token

      #####################################################
      # @!group Client Init
      #####################################################

      # Instantiates a client with cookie session or a JWT token.
      def initialize(cookie: nil, current_team_id: nil, token: nil, csrf_tokens: nil, another_client: nil)
        params_count = [cookie, token, another_client].compact.size
        if params_count != 1
          raise "Must initialize with one of :cookie, :token, or :another_client"
        end

        if token.nil?
          if another_client.nil?
            super(cookie: cookie, current_team_id: current_team_id, csrf_tokens: csrf_tokens, timeout: 1200)
            return
          end
          super(cookie: another_client.instance_variable_get(:@cookie), current_team_id: another_client.team_id, csrf_tokens: another_client.csrf_tokens)
        else
          options = {
            request: {
              timeout:       (ENV["SPACESHIP_TIMEOUT"] || 300).to_i,
              open_timeout:  (ENV["SPACESHIP_TIMEOUT"] || 300).to_i
            }
          }
          @token = token
          @current_team_id = current_team_id

          @client = Faraday.new(hostname, options) do |c|
            c.response(:json, content_type: /\bjson$/)
            c.response(:plist, content_type: /\bplist$/)
            c.use(FaradayMiddleware::RelsMiddleware)
            c.use(Spaceship::StatsMiddleware)
            c.use(Spaceship::TokenRefreshMiddleware, token)
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
      end

      # Instance level hostname only used when creating
      # App Store Connect API Faraday client.
      # Forwarding to class level if using web session.
      def hostname
        if @token
          return @token.in_house ? "https://api.enterprise.developer.apple.com/" : "https://api.appstoreconnect.apple.com/"
        end
        return self.class.hostname
      end

      def self.hostname
        # Implemented in subclass
        not_implemented(__method__)
      end

      #
      # Helpers
      #

      def web_session?
        return @token.nil?
      end

      def build_params(filter: nil, includes: nil, fields: nil, limit: nil, sort: nil, cursor: nil)
        params = {}

        filter = filter.delete_if { |k, v| v.nil? } if filter

        params[:filter] = filter if filter && !filter.empty?
        params[:include] = includes if includes
        params[:fields] = fields if fields
        params[:limit] = limit if limit
        params[:sort] = sort if sort
        params[:cursor] = cursor if cursor

        return params
      end

      def get(url_or_path, params = nil)
        response = with_asc_retry do
          request(:get) do |req|
            req.url(url_or_path)
            req.options.params_encoder = Faraday::NestedParamsEncoder
            req.params = params if params
            req.headers['Content-Type'] = 'application/json'
          end
        end
        handle_response(response)
      end

      def post(url_or_path, body, tries: 5)
        response = with_asc_retry(tries) do
          request(:post) do |req|
            req.url(url_or_path)
            req.body = body.to_json
            req.headers['Content-Type'] = 'application/json'
          end
        end
        handle_response(response)
      end

      def patch(url_or_path, body)
        response = with_asc_retry do
          request(:patch) do |req|
            req.url(url_or_path)
            req.body = body.to_json
            req.headers['Content-Type'] = 'application/json'
          end
        end
        handle_response(response)
      end

      def delete(url_or_path, params = nil, body = nil)
        response = with_asc_retry do
          request(:delete) do |req|
            req.url(url_or_path)
            req.options.params_encoder = Faraday::NestedParamsEncoder if params
            req.params = params if params
            req.body = body.to_json if body
            req.headers['Content-Type'] = 'application/json' if body
          end
        end
        handle_response(response)
      end

      protected

      class TimeoutRetryError < StandardError
        def initialize(msg)
          super
        end
      end

      class TooManyRequestsError < StandardError
        def initialize(msg)
          super
        end
      end

      def with_asc_retry(tries = 5, backoff = 1, &_block)
        response = yield

        status = response.status if response

        if [500, 504].include?(status)
          msg = "Timeout received! Retrying after 3 seconds (remaining: #{tries})..."
          raise TimeoutRetryError, msg
        end

        if status == 429
          raise TooManyRequestsError, "Too many requests, backing off #{backoff} seconds"
        end

        return response
      rescue UnauthorizedAccessError => error
        tries -= 1
        puts(error) if Spaceship::Globals.verbose?
        if tries.zero?
          raise error
        else
          msg = "Token has expired, issued-at-time is in the future, or has been revoked! Trying to refresh..."
          puts(msg) if Spaceship::Globals.verbose?
          @token.refresh!
          retry
        end
      rescue TimeoutRetryError => error
        tries -= 1
        puts(error) if Spaceship::Globals.verbose?
        if tries.zero?
          return response
        else
          retry
        end
      rescue TooManyRequestsError => error
        if backoff > 3600
          raise TooManyRequestsError, "Too many requests, giving up after backing off for > 3600 seconds."
        end
        puts(error) if Spaceship::Globals.verbose?
        Kernel.sleep(backoff)
        backoff *= 2
        retry
      end

      def handle_response(response)
        if (200...300).cover?(response.status) && (response.body.nil? || response.body.empty?)
          return
        end

        raise InternalServerError, "Server error got #{response.status}" if (500...600).cover?(response.status)

        unless response.body.kind_of?(Hash)
          raise UnexpectedResponse, response.body
        end

        raise UnexpectedResponse, response.body['error'] if response.body['error']

        raise UnexpectedResponse, format_errors(response) if response.body['errors']

        raise UnexpectedResponse, "Temporary App Store Connect error: #{response.body}" if response.body['statusCode'] == 'ERROR'

        store_csrf_tokens(response)

        return Spaceship::ConnectAPI::Response.new(body: response.body, status: response.status, headers: response.headers, client: self)
      end

      # Overridden from Spaceship::Client
      def handle_error(response)
        body = response.body.empty? ? {} : response.body

        # Setting body nil if invalid JSON which can happen if 502
        begin
          body = JSON.parse(body) if body.kind_of?(String)
        rescue
          nil
        end

        case response.status.to_i
        when 401
          raise UnauthorizedAccessError, format_errors(response)
        when 403
          error = (body['errors'] || []).first || {}
          error_code = error['code']
          if error_code == "FORBIDDEN.REQUIRED_AGREEMENTS_MISSING_OR_EXPIRED"
            raise ProgramLicenseAgreementUpdated, format_errors(response)
          else
            raise AccessForbiddenError, format_errors(response)
          end
        when 502
          # Issue - https://github.com/fastlane/fastlane/issues/19264
          # This 502 with "Could not process this request" body sometimes
          # work and sometimes doesn't
          # Usually retrying once or twice will solve the issue
          if body && body.include?("Could not process this request")
            raise BadGatewayError, "Could not process this request"
          end
        end
      end

      def format_errors(response)
        # Example error format
        # {
        # "errors":[
        #     {
        #       "id":"cbfd8674-4802-4857-bfe8-444e1ea36e32",
        #       "status":"409",
        #       "code":"STATE_ERROR",
        #       "title":"The request cannot be fulfilled because of the state of another resource.",
        #       "detail":"Submit for review errors found.",
        #       "meta":{
        #           "associatedErrors":{
        #             "/v1/appScreenshots/":[
        #                 {
        #                   "id":"23d1734f-b81f-411a-98e4-6d3e763d54ed",
        #                   "status":"409",
        #                   "code":"STATE_ERROR.SCREENSHOT_REQUIRED.APP_WATCH_SERIES_4",
        #                   "title":"App screenshot missing (APP_WATCH_SERIES_4)."
        #                 },
        #                 {
        #                   "id":"db993030-0a93-48e9-9fd7-7e5676633431",
        #                   "status":"409",
        #                   "code":"STATE_ERROR.SCREENSHOT_REQUIRED.APP_WATCH_SERIES_4",
        #                   "title":"App screenshot missing (APP_WATCH_SERIES_4)."
        #                 }
        #             ],
        #             "/v1/builds/d710b6fa-5235-4fe4-b791-2b80d6818db0":[
        #                 {
        #                   "id":"e421fe6f-0e3b-464b-89dc-ba437e7bb77d",
        #                   "status":"409",
        #                   "code":"ENTITY_ERROR.ATTRIBUTE.REQUIRED",
        #                   "title":"The provided entity is missing a required attribute",
        #                   "detail":"You must provide a value for the attribute 'usesNonExemptEncryption' with this request",
        #                   "source":{
        #                       "pointer":"/data/attributes/usesNonExemptEncryption"
        #                   }
        #                 }
        #             ]
        #           }
        #       }
        #     }
        # ]
        # }

        # Detail is missing in this response making debugging super hard
        # {"errors" =>
        #   [
        #     {
        #       "id"=>"80ea6cff-0043-4543-9cd1-3e26b0fce383",
        #       "status"=>"409",
        #       "code"=>"ENTITY_ERROR.RELATIONSHIP.INVALID",
        #       "title"=>"The provided entity includes a relationship with an invalid value",
        #       "source"=>{
        #         "pointer"=>"/data/relationships/primarySubcategoryOne"
        #       }
        #     }
        #   ]
        # }

        # Membership expired
        # {
        #   "errors" : [
        #     {
        #       "id" : "UUID",
        #       "status" : "403",
        #       "code" : "FORBIDDEN_ERROR",
        #       "title" : "This request is forbidden for security reasons",
        #       "detail" : "Team ID: 'ID' is not associated with an active membership. To check your teams membership status, sign in your account on the developer website. https://developer.apple.com/account/"
        #     }
        #   ]
        # }

        body = response.body.empty? ? {} : response.body
        body = JSON.parse(body) if body.kind_of?(String)

        formatted_errors = (body['errors'] || []).map do |error|
          messages = [[error['title'], error['detail'], error.dig("source", "pointer")].compact.join(" - ")]

          meta = error["meta"] || {}
          associated_errors = meta["associatedErrors"] || {}

          messages + associated_errors.values.flatten.map do |associated_error|
            [[associated_error["title"], associated_error["detail"]].compact.join(" - ")]
          end
        end.flatten.join("\n")

        if formatted_errors.empty?
          formatted_errors << "Unknown error"
        end

        return {
          'errors' => formatted_errors,
          'resultString' => formatted_errors
        }
      end

      private

      def local_variable_get(binding, name)
        if binding.respond_to?(:local_variable_get)
          binding.local_variable_get(name)
        else
          binding.eval(name.to_s)
        end
      end

      def provider_id
        return team_id if self.provider.nil?
        self.provider.provider_id
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
