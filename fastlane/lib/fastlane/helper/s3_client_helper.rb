require 'aws-sdk-s3'

module Fastlane
  module Helper
    class S3ClientHelper
      attr_reader :access_key
      attr_reader :region

      def initialize(access_key: nil, secret_access_key: nil, session_token: nil, region: nil, s3_client: nil)
        @access_key = access_key
        @secret_access_key = secret_access_key
        @session_token = session_token
        @region = region

        @client = s3_client
      end

      def list_buckets
        return client.list_buckets
      end

      def upload_file(bucket_name, file_name, file_data, acl)
        bucket = find_bucket!(bucket_name)
        details = {
          acl: acl,
          key: file_name,
          body: file_data
        }
        obj = bucket.put_object(details)

        # When you enable versioning on a S3 bucket,
        # writing to an object will create an object version
        # instead of replacing the existing object.
        # http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/S3/ObjectVersion.html
        if obj.kind_of?(Aws::S3::ObjectVersion)
          obj = obj.object
        end

        # Return public url
        obj.public_url.to_s
      end

      def delete_file(bucket_name, file_name)
        bucket = find_bucket!(bucket_name)
        file = bucket.object(file_name)
        file.delete
      end

      def find_bucket!(bucket_name)
        bucket = Aws::S3::Bucket.new(bucket_name, client: client)
        raise "Bucket '#{bucket_name}' not found" unless bucket.exists?

        return bucket
      end

      private

      attr_reader :secret_access_key
      attr_reader :session_token

      def client
        @client ||= Aws::S3::Client.new(
          {
            region: region,
            credentials: create_credentials
          }.compact
        )
      end

      def create_credentials
        return nil if access_key.to_s.empty? || secret_access_key.to_s.empty?

        Aws::Credentials.new(
          access_key,
          secret_access_key,
          session_token
        )
      end
    end
  end
end
