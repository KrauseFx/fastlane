module Fastlane
  module Actions
    require 'fastlane/actions/build_ios_app'
    class GymAction < BuildIOSAppAction
      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Alias for the `build_app` action"
      end
    end
  end
end
