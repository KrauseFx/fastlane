require 'openssl'

require_relative 'app'
require_relative 'website_push'

module Spaceship
  module Portal
    # Represents a certificate from the Apple Developer Portal.
    #
    # This can either be a code signing identity or a push profile
    class Certificate < PortalBase
      # @return (String) The ID given from the developer portal. You'll probably not need it.
      # @example
      #   "P577TH3PAA"
      attr_accessor :id

      # @return (String) The name of the certificate
      # @example Company
      #   "SunApps GmbH"
      # @example Push Profile
      #   "Apple Push Services"
      attr_accessor :name

      # @return (String) Status of the certificate
      # @example
      #   "Issued"
      attr_accessor :status

      # @return (Date) The date and time when the certificate was created
      # @example
      #   2015-04-01 21:24:00 UTC
      attr_accessor :created

      # @return (Date) The date and time when the certificate will expire
      # @example
      #   2016-04-01 21:24:00 UTC
      attr_accessor :expires

      # @return (String) The owner type that defines if it's a push profile
      #  or a code signing identity
      #
      # @example Code Signing Identity
      #   "team"
      # @example Push Certificate
      #   "bundle"
      attr_accessor :owner_type

      # @return (String) The name of the owner
      #
      # @example Code Signing Identity (usually the company name)
      #   "SunApps Gmbh"
      # @example Push Certificate (the bundle identifier)
      #   "tools.fastlane.app"
      attr_accessor :owner_name

      # @return (String) The ID of the owner, that can be used to
      #  fetch more information
      # @example
      #   "75B83SPLAA"
      attr_accessor :owner_id

      # Indicates the type of this certificate
      # which is automatically used to determine the class of
      # the certificate. Available values listed in CERTIFICATE_TYPE_IDS
      # @return (String) The type of the certificate
      # @example Production Certificate
      #   "R58UK2EWSO"
      # @example Development Certificate
      #   "5QPB9NHCEI"
      attr_accessor :type_display_id

      # @return (Bool) Whether or not the certificate can be downloaded
      attr_accessor :can_download

      attr_mapping({
        'certificateId' => :id,
        'name' => :name,
        'statusString' => :status,
        'dateCreated' => :created,
        'expirationDate' => :expires,
        'ownerType' => :owner_type,
        'ownerName' => :owner_name,
        'ownerId' => :owner_id,
        'certificateTypeDisplayId' => :type_display_id,
        'canDownload' => :can_download
      })

      #####################################################
      # Certs are not associated with apps
      #####################################################

      # An Apple development code signing certificate used for development environment
      class AppleDevelopment < Certificate; end

      # An Apple distribution code signing certificate used for distribution environment
      class AppleDistribution < Certificate; end

      # A development code signing certificate used for development environment
      class Development < Certificate; end

      # A production code signing certificate used for distribution environment
      class Production < Certificate; end

      # An In House code signing certificate used for enterprise distributions
      class InHouse < Certificate; end

      # A Mac development code signing certificate used for development environment
      class MacDevelopment < Certificate; end

      # A Mac production code signing certificate for building .app bundles
      class MacAppDistribution < Certificate; end

      # A Mac production code signing certificate for building .pkg installers
      class MacInstallerDistribution < Certificate; end

      # A Mac Developer ID signing certificate for building .app bundles
      class DeveloperIdApplication < Certificate; end

      # A Mac Developer ID signing certificate for building .pkg installers
      class DeveloperIdInstaller < Certificate; end

      #####################################################
      # Certs that are specific for one app
      #####################################################

      # Abstract class for push certificates. Check out the subclasses
      # DevelopmentPush, ProductionPush, WebsitePush and VoipPush
      class PushCertificate < Certificate; end

      # A push notification certificate for development environment
      class DevelopmentPush < PushCertificate; end

      # A push notification certificate for production environment
      class ProductionPush < PushCertificate; end

      # A push notification certificate for websites
      class WebsitePush < PushCertificate
        def self.portal_type
          Spaceship::Portal::WebsitePush
        end
      end

      # A push notification certificate for the VOIP environment
      class VoipPush < PushCertificate; end

      # Passbook certificate
      class Passbook < Certificate; end

      # ApplePay certificate
      class ApplePay < Certificate; end

      # ApplePayMerchantIdentity certificate
      class ApplePayMerchantIdentity < Certificate; end

      # A Mac push notification certificate for development environment
      class MacDevelopmentPush < PushCertificate; end

      # A Mac push notification certificate for production environment
      class MacProductionPush < PushCertificate; end

      APPLE_CERTIFICATE_TYPE_IDS = {
        "83Q87W3TGH" => AppleDevelopment,
        "WXV89964HE" => AppleDistribution
      }

      IOS_CERTIFICATE_TYPE_IDS = {
        "5QPB9NHCEI" => Development,
        "R58UK2EWSO" => Production,
        "9RQEK7MSXA" => InHouse,
        "LA30L5BJEU" => Certificate,
        "BKLRAVXMGM" => DevelopmentPush,
        "UPV3DW712I" => ProductionPush,
        "Y3B2F3TYSI" => Passbook,
        "3T2ZP62QW8" => WebsitePush,
        "E5D663CMZW" => VoipPush,
        "4APLUP237T" => ApplePay,
        "MD8Q2VRT6A" => ApplePayMerchantIdentity
      }

      OLDER_IOS_CERTIFICATE_TYPES = [
        # those are also sent by the browser, but not sure what they represent
        "T44PTHVNID",
        "DZQUP8189Y",
        "FGQUP4785Z",
        "S5WE21TULA",
        "3BQKVH9I2X", # ProductionPush,
        "FUOY7LWJET"
      ]

      MAC_CERTIFICATE_TYPE_IDS = {
        "749Y1QAGU7" => MacDevelopment,
        "HXZEUKP0FP" => MacAppDistribution,
        "2PQI8IDXNH" => MacInstallerDistribution,
        "OYVN2GW35E" => DeveloperIdInstaller,
        "W0EURJRMC5" => DeveloperIdApplication,
        "CDZ7EMXIZ1" => MacProductionPush,
        "HQ4KP3I34R" => MacDevelopmentPush,
        "DIVN2GW3XT" => DeveloperIdApplication
      }

      CERTIFICATE_TYPE_IDS = APPLE_CERTIFICATE_TYPE_IDS
                             .merge(IOS_CERTIFICATE_TYPE_IDS)
                             .merge(MAC_CERTIFICATE_TYPE_IDS)

      # Class methods
      class << self
        # Create a new code signing request that can be used to
        # generate a new certificate
        # @example
        #  Create a new certificate signing request
        #  csr, pkey = Spaceship.certificate.create_certificate_signing_request
        #
        #  # Use the signing request to create a new distribution certificate
        #  Spaceship.certificate.production.create!(csr: csr)
        def create_certificate_signing_request
          key = OpenSSL::PKey::RSA.new(2048)
          csr = OpenSSL::X509::Request.new
          csr.version = 0
          csr.subject = OpenSSL::X509::Name.new([
                                                  ['CN', 'PEM', OpenSSL::ASN1::UTF8STRING]
                                                ])
          csr.public_key = key.public_key
          csr.sign(key, OpenSSL::Digest.new('SHA1'))
          return [csr, key]
        end

        # Create a new object based on a hash.
        # This is used to create a new object based on the server response.
        def factory(attrs)
          # Example:
          # => {"name"=>"iOS Distribution: SunApps GmbH",
          #  "certificateId"=>"XC5PH8DAAA",
          #  "serialNumber"=>"797E732CCE8B7AAA",
          #  "status"=>"Issued",
          #  "statusCode"=>0,
          #  "expirationDate"=>#<DateTime: 2015-11-25T22:45:50+00:00 ((2457352j,81950s,0n),+0s,2299161j)>,
          #  "certificatePlatform"=>"ios",
          #  "certificateType"=>
          #   {"certificateTypeDisplayId"=>"R58UK2EAAA",
          #    "name"=>"iOS Distribution",
          #    "platform"=>"ios",
          #    "permissionType"=>"distribution",
          #    "distributionType"=>"store",
          #    "distributionMethod"=>"app",
          #    "ownerType"=>"team",
          #    "daysOverlap"=>364,
          #    "maxActive"=>2}}

          if attrs['certificateType']
            # On some accounts this is nested, so we need to flatten it
            attrs.merge!(attrs['certificateType'])
            attrs.delete('certificateType')
          end

          # Parse the dates
          # rubocop:disable Style/RescueModifier
          attrs['expirationDate'] = (Time.parse(attrs['expirationDate']) rescue attrs['expirationDate'])
          attrs['dateCreated'] = (Time.parse(attrs['dateCreated']) rescue attrs['dateCreated'])
          # rubocop:enable Style/RescueModifier

          # Here we go
          klass = CERTIFICATE_TYPE_IDS[attrs['certificateTypeDisplayId']]
          klass ||= Certificate
          klass.client = @client
          klass.new(attrs)
        end

        # @param mac [Bool] Fetches Mac certificates if true. (Ignored if called from a subclass)
        # @return (Array) Returns all certificates of this account.
        #  If this is called from a subclass of Certificate, this will
        #  only include certificates matching the current type.
        def all(mac: false)
          if self == Certificate # are we the base-class?
            type_ids = mac ? MAC_CERTIFICATE_TYPE_IDS : IOS_CERTIFICATE_TYPE_IDS
            type_ids = APPLE_CERTIFICATE_TYPE_IDS.merge(type_ids)
            types = type_ids.keys
            types += OLDER_IOS_CERTIFICATE_TYPES unless mac
          else
            types = [CERTIFICATE_TYPE_IDS.key(self)]
            mac = MAC_CERTIFICATE_TYPE_IDS.values.include?(self)
          end

          client.certificates(types, mac: mac).map do |cert|
            factory(cert)
          end
        end

        # @param mac [Bool] Searches Mac certificates if true
        # @return (Certificate) Find a certificate based on the ID of the certificate.
        def find(certificate_id, mac: false)
          all(mac: mac).find do |c|
            c.id == certificate_id
          end
        end

        # Generate a new certificate based on a code certificate signing request
        # @param csr (OpenSSL::X509::Request) (required): The certificate signing request to use. Get one using
        #   `create_certificate_signing_request`
        # @param bundle_id (String) (optional): The app identifier this certificate is for.
        #  This value is only needed if you create a push profile. For normal code signing
        #  certificates, you must only pass a certificate signing request.
        # @example
        #  # Create a new certificate signing request
        #  csr, pkey = Spaceship::Certificate.create_certificate_signing_request
        #
        #  # Use the signing request to create a new distribution certificate
        #  Spaceship::Certificate::Production.create!(csr: csr)
        # @return (Certificate): The newly created certificate
        def create!(csr: nil, bundle_id: nil)
          type = CERTIFICATE_TYPE_IDS.key(self)
          mac = MAC_CERTIFICATE_TYPE_IDS.include?(type)

          # look up the app_id by the bundle_id
          if bundle_id
            app = portal_type.set_client(client).find(bundle_id)
            raise "Could not find app with bundle id '#{bundle_id}'" unless app
            app_id = app.app_id
          end

          # ensure csr is a OpenSSL::X509::Request
          csr = OpenSSL::X509::Request.new(csr) if csr.kind_of?(String)

          # if this succeeds, we need to save the .cer and the private key in keychain access or wherever they go in linux
          response = client.create_certificate!(type, csr.to_pem, app_id, mac)
          # munge the response to make it work for the factory
          response['certificateTypeDisplayId'] = response['certificateType']['certificateTypeDisplayId']
          self.new(response)
        end

        # Default portal class to use when finding by bundle_id
        # @return (Class): The class this type of certificate belongs to
        def portal_type
          Spaceship::Portal::App
        end
      end

      # instance methods

      # @return (String) Download the raw data of the certificate without parsing
      def download_raw
        client.download_certificate(id, type_display_id, mac: mac?)
      end

      # @return (OpenSSL::X509::Certificate) Downloads and parses the certificate
      def download
        OpenSSL::X509::Certificate.new(download_raw)
      end

      # Revoke the certificate. You shouldn't use this method probably.
      def revoke!
        client.revoke_certificate!(id, type_display_id, mac: mac?)
      end

      # @return (Bool): Is this certificate a push profile for apps?
      def is_push?
        self.kind_of?(PushCertificate)
      end

      # @return (Bool) Is this a Mac profile?
      def mac?
        MAC_CERTIFICATE_TYPE_IDS.include?(type_display_id)
      end
    end
  end
end
