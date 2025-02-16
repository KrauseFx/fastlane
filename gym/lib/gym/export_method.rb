# From `xcodebuild -help`:
#
# method : String
#
# Describes how Xcode should export the archive.
# Available options:
#   app-store-connect,
#   release-testing,
#   enterprise,
#   debugging,
#   developer-id,
#   mac-application,
#   validation,
#   and package.
#
# The list of options varies based on the type of archive.
#
# Defaults to debugging.
#
# Additional options include:
#   app-store (deprecated: use app-store-connect),
#   ad-hoc (deprecated: use release-testing),
#   and development (deprecated: use debugging).
module Gym
  class ExportMethod
    APP_STORE = 'app-store-connect'
    RELEASE_TESTING = 'release-testing'
    ENTERPRISE = 'enterprise'
    DEBUGGING = 'debugging'
    DEVELOPER_ID = 'developer-id'
    MAC_APPLICATION = 'mac-application'
    VALIDATION = 'validation'
    PACKAGE = 'package'

    APP_STORE_DEPRECATED = 'app-store'
    RELEASE_TESTING_DEPRECATED = 'ad-hoc'
    DEBUGGING_DEPRECATED = 'development'

    def self.available_methods
      [
        APP_STORE,
        RELEASE_TESTING,
        ENTERPRISE,
        DEBUGGING,
        DEVELOPER_ID,
        MAC_APPLICATION,
        VALIDATION,
        PACKAGE
      ]
    end

    def self.deprecated_methods_notice
      deprecation_list = [
        [APP_STORE_DEPRECATED, APP_STORE],
        [RELEASE_TESTING_DEPRECATED, RELEASE_TESTING],
        [DEBUGGING_DEPRECATED, DEBUGGING]
      ].map { |p| "'#{p[0]} in favor of '#{p[1]}'" }.join(', ')

      "Notice that recent versions of xcodebuild have deprecated #{deprecation_list}. See 'xcodebuild -help' for more info."
    end
  end
end
