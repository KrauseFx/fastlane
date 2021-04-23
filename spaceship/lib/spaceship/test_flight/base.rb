require_relative '../base'
require_relative '../tunes/tunes_client'

module Spaceship
  module TestFlight
    class Base < Spaceship::Base
      def self.client
        # Verify there is a client that can be used
        if Spaceship::Tunes.client
          # Initialize new client if new or if team changed
          if @client.nil? || @client.team_id != Spaceship::Tunes.client.team_id
            @client = Client.client_with_authorization_from(Spaceship::Tunes.client)
          end
        end

        # Need to handle not having a client but this shouldn't ever happen
        raise "Please login using `Spaceship::Tunes.login('user', 'password')`" unless @client

        @client
      end

      ##
      # Have subclasses inherit the client from their superclass
      #
      # Essentially, we are making a class-inheritable-accessor as described here:
      # https://apidock.com/rails/v4.2.7/Class/class_attribute
      def self.inherited(subclass)
        this_class = self
        subclass.define_singleton_method(:client) do
          this_class.client
        end
      end

      def to_json(*_args)
        raw_data.to_json
      end
    end
  end
end
