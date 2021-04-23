require_relative 'module'

module Gym
  class Xcode
    class << self
      def xcode_path
        Helper.xcode_path
      end

      def xcode_version
        Helper.xcode_version
      end

      # Below Xcode 7 (which offers a new nice API to sign the app)
      def pre_7?
        UI.user_error!("Unable to locate Xcode. Please make sure to have Xcode installed on your machine") if xcode_version.nil?
        v = xcode_version
        v.split('.')[0].to_i < 7
      end

      def legacy_api_deprecated?
        FastlaneCore::Helper.xcode_at_least?('8.3')
      end
    end
  end
end
