require_relative './client'

require_relative './testflight/testflight'

module Spaceship
  class ConnectAPI
    class << self
      # This client stores the global client when using the lazy syntax
      attr_accessor :client

      # Forward class calls to the global client
      # This is implemented for backwards compatibility
      extend(Forwardable)
      def_delegators(:client, *Spaceship::ConnectAPI::IAP::API.instance_methods(false))
      def_delegators(:client, *Spaceship::ConnectAPI::Provisioning::API.instance_methods(false))
      def_delegators(:client, *Spaceship::ConnectAPI::TestFlight::API.instance_methods(false))
      def_delegators(:client, *Spaceship::ConnectAPI::Tunes::API.instance_methods(false))
      def_delegators(:client, *Spaceship::ConnectAPI::Users::API.instance_methods(false))

      def client
        # Always look for a client set explicitly by the client first
        return @client if @client

        # A client may not always be explicitly set (specially when running tools like match, sigh, pilot, etc)
        # In that case, create a new client based on existing sessions
        # Note: This does not perform logins on the user. It is only reusing the cookies and selected teams
        return nil if Spaceship::Tunes.client.nil? && Spaceship::Portal.client.nil?

        implicit_client = ConnectAPI::Client.new(tunes_client: Spaceship::Tunes.client, portal_client: Spaceship::Portal.client)
        return implicit_client
      end

      def token=(token)
        @client = ConnectAPI::Client.new(token: token)
      end

      def token
        return nil if @client.nil?
        return @client.token
      end

      def token?
        (@client && @client.token)
      end

      # Initializes client with Apple's App Store Connect JWT auth key.
      #
      # This method will automatically use the arguments from environment
      # variables if not given.
      #
      # The key_id, issuer_id and either filepath or key are needed to authenticate.
      #
      # @param key_id (String) (optional): The key id
      # @param issuer_id (String) (optional): The issuer id
      # @param filepath (String) (optional): The filepath
      # @param key (String) (optional): The key
      # @param duration (Integer) (optional): How long this session should last
      # @param in_house (Boolean) (optional): Whether this session is an Enterprise one
      #
      # @raise InvalidUserCredentialsError: raised if authentication failed
      #
      # @return (Spaceship::ConnectAPI::Client) The client the login method was called for
      def auth(key_id: nil, issuer_id: nil, filepath: nil, key: nil, duration: nil, in_house: nil)
        @client = ConnectAPI::Client.auth(key_id: key_id, issuer_id: issuer_id, filepath: filepath, key: key, duration: duration, in_house: in_house)
      end

      # Authenticates with Apple's web services. This method has to be called once
      # to generate a valid session.
      #
      # This method will automatically use the username from the Appfile (if available)
      # and fetch the password from the Keychain (if available)
      #
      # @param user (String) (optional): The username (usually the email address)
      # @param password (String) (optional): The password
      # @param use_portal (Boolean) (optional): Whether to log in to Spaceship::Portal or not
      # @param use_tunes (Boolean) (optional): Whether to log in to Spaceship::Tunes or not
      # @param portal_team_id (String) (optional): The Spaceship::Portal team id
      # @param tunes_team_id (String) (optional): The Spaceship::Tunes team id
      # @param team_name (String) (optional): The team name
      # @param skip_select_team (Boolean) (optional): Whether to skip automatic selection or prompt for team
      #
      # @raise InvalidUserCredentialsError: raised if authentication failed
      #
      # @return (Spaceship::ConnectAPI::Client) The client the login method was called for
      def login(user = nil, password = nil, use_portal: true, use_tunes: true, portal_team_id: nil, tunes_team_id: nil, team_name: nil, skip_select_team: false)
        @client = ConnectAPI::Client.login(user, password, use_portal: use_portal, use_tunes: use_tunes, portal_team_id: portal_team_id, tunes_team_id: tunes_team_id, team_name: team_name, skip_select_team: skip_select_team)
      end

      # Open up the team selection for the user (if necessary).
      #
      # If the user is in multiple teams, a team selection is shown.
      # The user can then select a team by entering the number
      #
      # @param portal_team_id (String) (optional): The Spaceship::Portal team id
      # @param tunes_team_id (String) (optional): The Spaceship::Tunes team id
      # @param team_name (String) (optional): The name of an App Store Connect team
      def select_team(portal_team_id: nil, tunes_team_id: nil, team_name: nil)
        return if client.nil?
        client.select_team(portal_team_id: portal_team_id, tunes_team_id: tunes_team_id, team_name: team_name)
      end
    end
  end
end
