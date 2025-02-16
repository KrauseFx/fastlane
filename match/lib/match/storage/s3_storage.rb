require 'fastlane_core/command_executor'
require 'fastlane_core/configuration/configuration'
require 'fastlane/helper/s3_client_helper'

require_relative '../options'
require_relative '../module'
require_relative '../spaceship_ensure'
require_relative './interface'

module Match
  module Storage
    # Store the code signing identities on AWS S3
    class S3Storage < Interface
      attr_reader :s3_bucket
      attr_reader :s3_region
      attr_reader :s3_client
      attr_reader :s3_object_prefix
      attr_reader :readonly
      attr_reader :username
      attr_reader :team_id
      attr_reader :team_name
      attr_reader :api_key_path
      attr_reader :api_key

      def self.configure(params)
        s3_region = params[:s3_region]
        s3_access_key = params[:s3_access_key]
        s3_secret_access_key = params[:s3_secret_access_key]
        s3_session_token = params[:s3_session_token]
        s3_bucket = params[:s3_bucket]
        s3_object_prefix = params[:s3_object_prefix]

        if params[:git_url].to_s.length > 0
          UI.important("Looks like you still define a `git_url` somewhere, even though")
          UI.important("you use S3 Storage. You can remove the `git_url`")
          UI.important("from your Matchfile and Fastfile")
          UI.message("The above is just a warning, fastlane will continue as usual now...")
        end

        return self.new(
          s3_region: s3_region,
          s3_access_key: s3_access_key,
          s3_secret_access_key: s3_secret_access_key,
          s3_session_token: s3_session_token,
          s3_bucket: s3_bucket,
          s3_object_prefix: s3_object_prefix,
          readonly: params[:readonly],
          username: params[:username],
          team_id: params[:team_id],
          team_name: params[:team_name],
          api_key_path: params[:api_key_path],
          api_key: params[:api_key]
        )
      end

      def initialize(s3_region: nil,
                     s3_access_key: nil,
                     s3_secret_access_key: nil,
                     s3_session_token: nil,
                     s3_bucket: nil,
                     s3_object_prefix: nil,
                     readonly: nil,
                     username: nil,
                     team_id: nil,
                     team_name: nil,
                     api_key_path: nil,
                     api_key: nil)
        @s3_bucket = s3_bucket
        @s3_region = s3_region
        @s3_client = Fastlane::Helper::S3ClientHelper.new(access_key: s3_access_key, secret_access_key: s3_secret_access_key, session_token: s3_session_token, region: s3_region)
        @s3_object_prefix = s3_object_prefix.to_s
        @readonly = readonly
        @username = username
        @team_id = team_id
        @team_name = team_name
        @api_key_path = api_key_path
        @api_key = api_key
      end

      # To make debugging easier, we have a custom exception here
      def prefixed_working_directory
        # We fall back to "*", which means certificates and profiles
        # from all teams that use this bucket would be installed. This is not ideal, but
        # unless the user provides a `team_id`, we can't know which one to use
        # This only happens if `readonly` is activated, and no `team_id` was provided
        @_folder_prefix ||= currently_used_team_id
        if @_folder_prefix.nil?
          # We use a `@_folder_prefix` variable, to keep state between multiple calls of this
          # method, as the value won't change. This way the warning is only printed once
          UI.important("Looks like you run `match` in `readonly` mode, and didn't provide a `team_id`. This will still work, however it is recommended to provide a `team_id` in your Appfile or Matchfile")
          @_folder_prefix = "*"
        end
        return File.join(working_directory, @_folder_prefix)
      end

      # Call this method for the initial clone/download of the
      # user's certificates & profiles
      # As part of this method, the `self.working_directory` attribute
      # will be set
      def download
        # Check if we already have a functional working_directory
        return if @working_directory && Dir.exist?(@working_directory)

        # No existing working directory, creating a new one now
        self.working_directory = Dir.mktmpdir

        # If team_id is defined, use `:team/` as a prefix (appending it at the end of the `s3_object_prefix` if one provided by the user),
        # so that we limit the download to only files that are specific to this team, and avoid downloads + decryption of unnecessary files.
        key_prefix = team_id.nil? ? s3_object_prefix : File.join(s3_object_prefix, team_id, '').delete_prefix('/')

        s3_client.find_bucket!(s3_bucket).objects(prefix: key_prefix).each do |object|
          # Prevent download if the file path is a directory.
          # We need to check if string ends with "/" instead of using `File.directory?` because
          # the string represent a remote location, not a local file in disk.
          next if object.key.end_with?("/")

          file_path = strip_s3_object_prefix(object.key) # :s3_object_prefix:team_id/path/to/file

          # strip s3_prefix from file_path
          download_path = File.join(self.working_directory, file_path)

          FileUtils.mkdir_p(File.expand_path("..", download_path))
          UI.verbose("Downloading file from S3 '#{file_path}' on bucket #{self.s3_bucket}")

          object.download_file(download_path)
        end
        UI.verbose("Successfully downloaded files from S3 to #{self.working_directory}")
      end

      # Returns a short string describing + identifying the current
      # storage backend. This will be printed when nuking a storage
      def human_readable_description
        return "S3 Bucket [#{s3_bucket}] on region #{s3_region}"
      end

      def upload_files(files_to_upload: [], custom_message: nil)
        # `files_to_upload` is an array of files that need to be uploaded to S3
        # Those doesn't mean they're new, it might just be they're changed
        # Either way, we'll upload them using the same technique

        files_to_upload.each do |file_name|
          # Go from
          #   "/var/folders/px/bz2kts9n69g8crgv4jpjh6b40000gn/T/d20181026-96528-1av4gge/:team_id/profiles/development/Development_me.mobileprovision"
          # to
          #   ":s3_object_prefix:team_id/profiles/development/Development_me.mobileprovision"
          #
          target_path = s3_object_path(file_name)
          UI.verbose("Uploading '#{target_path}' to S3 Storage...")

          body = File.read(file_name)
          acl = 'private'
          s3_url = s3_client.upload_file(s3_bucket, target_path, body, acl)
          UI.verbose("Uploaded '#{s3_url}' to S3 Storage.")
        end
      end

      def delete_files(files_to_delete: [], custom_message: nil)
        files_to_delete.each do |file_name|
          target_path = s3_object_path(file_name)
          UI.verbose("Deleting '#{target_path}' from S3 Storage...")
          s3_client.delete_file(s3_bucket, target_path)
        end
      end

      def skip_docs
        false
      end

      def list_files(file_name: "", file_ext: "")
        Dir[File.join(working_directory, self.team_id, "**", file_name, "*.#{file_ext}")]
      end

      # Implement this for the `fastlane match init` command
      # This method must return the content of the Matchfile
      # that should be generated
      def generate_matchfile_content(template: nil)
        return "s3_bucket(\"#{self.s3_bucket}\")"
      end

      private

      def s3_object_path(file_name)
        sanitized = sanitize_file_name(file_name)
        return sanitized if sanitized.start_with?(s3_object_prefix)

        s3_object_prefix + sanitized
      end

      def strip_s3_object_prefix(object_path)
        object_path.delete_prefix(s3_object_prefix.to_s).delete_prefix('/')
      end

      def sanitize_file_name(file_name)
        file_name.gsub(self.working_directory + "/", "")
      end

      def currently_used_team_id
        if self.readonly
          # In readonly mode, we still want to see if the user provided a team_id
          # see `prefixed_working_directory` comments for more details
          return self.team_id
        else
          UI.user_error!("The `team_id` option is required. fastlane cannot automatically determine portal team id via the App Store Connect API (yet)") if self.team_id.to_s.empty?

          spaceship = SpaceshipEnsure.new(self.username, self.team_id, self.team_name, api_token)
          return spaceship.team_id
        end
      end

      def api_token
        api_token = Spaceship::ConnectAPI::Token.from(hash: self.api_key, filepath: self.api_key_path)
        api_token ||= Spaceship::ConnectAPI.token
        return api_token
      end
    end
  end
end
