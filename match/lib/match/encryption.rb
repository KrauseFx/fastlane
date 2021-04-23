require_relative 'encryption/interface'
require_relative 'encryption/openssl'

module Match
  module Encryption
    class << self
      def backends
        @backends ||= {
          "git" => lambda { |params|
            # OpenSSL is storage agnostic so this maps git_url
            # to keychain_name for the name of the keychain entry
            params[:keychain_name] = params[:git_url]
            return Encryption::OpenSSL.configure(params)
          },
          "google_cloud" => lambda { |params|
          },
          "s3" => lambda { |params|
            params[:keychain_name] = params[:s3_bucket]
            return Encryption::OpenSSL.configure(params)
          }
        }
      end

      def register_backend(type: nil, encryption_class: nil, &configurator)
        UI.user_error!("No type specified for encryption backend") if type.nil?

        normalized_name = type.to_s
        UI.message("Replacing Match::Encryption backend for type '#{normalized_name}'") if backends.include?(normalized_name)

        if configurator
          @backends[normalized_name] = configurator
        elsif encryption_class
          @backends[normalized_name] = ->(params) { return encryption_class.configure(params) }
        else
          UI.user_error!("Specify either a `encryption_class` or a configuration block when registering a encryption backend")
        end
      end

      # Returns the class to be used for a given `storage_mode`
      def for_storage_mode(storage_mode, params)
        configurator = backends[storage_mode.to_s]
        return configurator.call(params) if configurator

        UI.user_error!("No encryption backend for storage mode '#{storage_mode}'")
      end
    end
  end
end
