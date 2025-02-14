require_relative '../model'
module Spaceship
  class ConnectAPI
    class AppClip
      include Spaceship::ConnectAPI::Model

      attr_accessor :bundle_id

      attr_mapping(
        'bundleId' => 'bundle_id'
      )

      def self.type
        'appClips'
      end
    end
  end
end
