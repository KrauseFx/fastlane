require 'fastlane/erb_template_helper'
require 'ostruct'

module Fastlane
  module Actions
    module SharedValues
      S3_IPA_OUTPUT_PATH = :S3_IPA_OUTPUT_PATH
      S3_DSYM_OUTPUT_PATH = :S3_DSYM_OUTPUT_PATH
      S3_PLIST_OUTPUT_PATH = :S3_PLIST_OUTPUT_PATH
      S3_HTML_OUTPUT_PATH = :S3_HTML_OUTPUT_PATH
      S3_VERSION_OUTPUT_PATH = :S3_VERSION_OUTPUT_PATH
    end

    S3_ARGS_MAP = {
      ipa: '-f',
      dsym: '-d',
      access_key: '-a',
      secret_access_key: '-s',
      bucket: '-b',
      region: '-r',
      acl: '--acl',
      source: '--source-dir',
      path: '-P'
    }

    class S3Action < Action
      def self.run(config)
        # Calling fetch on config so that default values will be used
        params = {}
        params[:ipa] = config[:ipa]
        params[:dsym] = config[:dsym]
        params[:access_key] = config[:access_key]
        params[:secret_access_key] = config[:secret_access_key]
        params[:bucket] = config[:bucket]
        params[:region] = config[:region]
        params[:acl] = config[:acl]
        params[:source] = config[:source]
        params[:path] = config[:path]
        params[:upload_metadata] = config[:upload_metadata]
        params[:plist_template_path] = config[:plist_template_path]
        params[:html_template_path] = config[:html_template_path]
        params[:html_file_name] = config[:html_file_name]
        params[:version_template_path] = config[:version_template_path]
        params[:version_file_name] = config[:version_file_name]
        params [:acl] = config[:acl]

        # Pulling parameters for other uses
        s3_region = params[:region]
        s3_subdomain = params[:region] ? "s3-#{params[:region]}" : "s3"
        s3_access_key = params[:access_key]
        s3_secret_access_key = params[:secret_access_key]
        s3_bucket = params[:bucket]
        ipa_file = params[:ipa]
        dsym_file = params[:dsym]
        s3_path = params[:path]
        acl     = params[:acl].to_sym

        UI.user_error!("No S3 access key given, pass using `access_key: 'key'`") unless s3_access_key.to_s.length > 0
        UI.user_error!("No S3 secret access key given, pass using `secret_access_key: 'secret key'`") unless s3_secret_access_key.to_s.length > 0
        UI.user_error!("No S3 bucket given, pass using `bucket: 'bucket'`") unless s3_bucket.to_s.length > 0
        UI.user_error!("No IPA file path given, pass using `ipa: 'ipa path'`") unless ipa_file.to_s.length > 0

        plist_template_path = params[:plist_template_path]
        html_template_path = params[:html_template_path]
        html_file_name = params[:html_file_name]
        version_template_path = params[:version_template_path]
        version_file_name = params[:version_file_name]

        s3_client = self.s3_client(s3_access_key, s3_secret_access_key, s3_region)
        bucket = s3_client.buckets[s3_bucket]

        url_part = self.expand_path_with_substitutions_from_ipa_plist(ipa_file, s3_path)

        ipa_file_basename = File.basename(ipa_file)
        ipa_file_name = "#{url_part}#{ipa_file_basename}"
        ipa_file_data = File.open(ipa_file, 'rb')

        ipa_url = self.upload_file(bucket, ipa_file_name, ipa_file_data, acl)

        # Setting action and environment variables
        Actions.lane_context[SharedValues::S3_IPA_OUTPUT_PATH] = ipa_url
        ENV[SharedValues::S3_IPA_OUTPUT_PATH.to_s] = ipa_url

        if dsym_file
          dsym_file_basename = File.basename(dsym_file)
          dsym_file_name = "#{url_part}#{dsym_file_basename}"
          dsym_file_data = File.open(dsym_file, 'rb')

          dsym_url = self.upload_file(bucket, dsym_file_name, dsym_file_data, acl)

          # Setting action and environment variables
          Actions.lane_context[SharedValues::S3_DSYM_OUTPUT_PATH] = dsym_url
          ENV[SharedValues::S3_DSYM_OUTPUT_PATH.to_s] = dsym_url

        end

        if params[:upload_metadata] == false
          return true
        end

        #####################################
        #
        # html and plist building
        #
        #####################################

        # Gets info used for the plist
        info = FastlaneCore::IpaFileAnalyser.fetch_info_plist_file(ipa_file)

        build_num = info['CFBundleVersion']
        bundle_id = info['CFBundleIdentifier']
        bundle_version = info['CFBundleShortVersionString']
        title = info['CFBundleName']        
        device_family = info['UIDeviceFamily']

        full_version = "#{bundle_version}.#{build_num}"

        # Creating plist and html names
        plist_file_name = "#{url_part}#{title.delete(' ')}.plist"
        plist_url = "https://#{s3_subdomain}.amazonaws.com/#{s3_bucket}/#{plist_file_name}"

        html_file_name ||= "index.html"

        version_file_name ||= "version.json"

        # grabs module
        eth = Fastlane::ErbTemplateHelper

        # Creates plist from template
        if plist_template_path && File.exist?(plist_template_path)
          plist_template = eth.load_from_path(plist_template_path)
        else
          plist_template = eth.load("s3_plist_template")
        end
        plist_render = eth.render(plist_template, {
          url: ipa_url,
          ipa_url: ipa_url,
          build_num: build_num,
          bundle_id: bundle_id,
          bundle_version: bundle_version,
          title: title
        })

        # Creates html from template
        if html_template_path && File.exist?(html_template_path)
          html_template = eth.load_from_path(html_template_path)
        else
          html_template = eth.load("s3_html_template")
        end
        
        print html_template_path
        print html_template

        html_render = eth.render(html_template, {
          url: plist_url,
          plist_url: plist_url,
          ipa_url: ipa_url,
          build_num: build_num,
          bundle_id: bundle_id,
          bundle_version: bundle_version,
          title: title,
          device_family: device_family
        })

        # Creates version from template
        if version_template_path && File.exist?(version_template_path)
          version_template = eth.load_from_path(version_template_path)
        else
          version_template = eth.load("s3_version_template")
        end
        version_render = eth.render(version_template, {
          url: plist_url,
          plist_url: plist_url,
          ipa_url: ipa_url,
          build_num: build_num,
          bundle_version: bundle_version,
          full_version: full_version
        })

        #####################################
        #
        # html and plist uploading
        #
        #####################################

        plist_url = self.upload_file(bucket, plist_file_name, plist_render, acl)
        html_url = self.upload_file(bucket, html_file_name, html_render, acl)
        version_url = self.upload_file(bucket, version_file_name, version_render, acl)

        # Setting action and environment variables
        Actions.lane_context[SharedValues::S3_PLIST_OUTPUT_PATH] = plist_url
        ENV[SharedValues::S3_PLIST_OUTPUT_PATH.to_s] = plist_url

        Actions.lane_context[SharedValues::S3_HTML_OUTPUT_PATH] = html_url
        ENV[SharedValues::S3_HTML_OUTPUT_PATH.to_s] = html_url

        Actions.lane_context[SharedValues::S3_VERSION_OUTPUT_PATH] = version_url
        ENV[SharedValues::S3_VERSION_OUTPUT_PATH.to_s] = version_url

        UI.success("Successfully uploaded ipa file to '#{Actions.lane_context[SharedValues::S3_IPA_OUTPUT_PATH]}'")

        return true
      end

      def self.s3_client(s3_access_key, s3_secret_access_key, s3_region)
        Actions.verify_gem!('aws-sdk')
        require 'aws-sdk'
        if s3_region
          s3_client = AWS::S3.new(
            access_key_id: s3_access_key,
            secret_access_key: s3_secret_access_key,
            region: s3_region
          )
        else
          s3_client = AWS::S3.new(
            access_key_id: s3_access_key,
            secret_access_key: s3_secret_access_key
          )
        end
        s3_client
      end

      def self.upload_file(bucket, file_name, file_data, acl)
        obj = bucket.objects.create(file_name, file_data, acl: acl)

        # When you enable versioning on a S3 bucket,
        # writing to an object will create an object version
        # instead of replacing the existing object.
        # http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/S3/ObjectVersion.html
        if obj.kind_of? AWS::S3::ObjectVersion
          obj = obj.object
        end

        # Return public url
        obj.public_url.to_s
      end

      #
      # NOT a fan of this as this was taken straight from Shenzhen
      # https://github.com/nomad/shenzhen/blob/986792db5d4d16a80c865a2748ee96ba63644821/lib/shenzhen/plugins/s3.rb#L32
      #
      # Need to find a way to not use this copied method
      #
      # AGAIN, I am not happy about this right now.
      # Using this for prototype reasons.
      #
      def self.expand_path_with_substitutions_from_ipa_plist(ipa, path)
        substitutions = path.scan(/\{CFBundle[^}]+\}/)
        return path if substitutions.empty?
        info = FastlaneCore::IpaFileAnalyser.fetch_info_plist_file(ipa) or return path

        substitutions.uniq.each do |substitution|
          key = substitution[1...-1]
          value = info[key]
          path.gsub!(Regexp.new(substitution), value) if value
        end

        return path
      end

      def self.description
        "Generates a plist file and uploads all to AWS S3"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :ipa,
                                       env_name: "",
                                       description: ".ipa file for the build ",
                                       optional: true,
                                       default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH]),
          FastlaneCore::ConfigItem.new(key: :dsym,
                                       env_name: "",
                                       description: "zipped .dsym package for the build ",
                                       optional: true,
                                       default_value: Actions.lane_context[SharedValues::DSYM_OUTPUT_PATH]),
          FastlaneCore::ConfigItem.new(key: :upload_metadata,
                                       env_name: "",
                                       description: "Upload relevant metadata for this build",
                                       optional: true,
                                       default_value: true,
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :plist_template_path,
                                       env_name: "",
                                       description: "plist template path",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :html_template_path,
                                       env_name: "",
                                       description: "html erb template path",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :html_file_name,
                                       env_name: "",
                                       description: "uploaded html filename",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :version_template_path,
                                       env_name: "",
                                       description: "version erb template path",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :version_file_name,
                                       env_name: "",
                                       description: "uploaded version filename",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :access_key,
                                       env_name: "S3_ACCESS_KEY",
                                       description: "AWS Access Key ID ",
                                       optional: true,
                                       default_value: ENV['AWS_ACCESS_KEY_ID']),
          FastlaneCore::ConfigItem.new(key: :secret_access_key,
                                       env_name: "S3_SECRET_ACCESS_KEY",
                                       description: "AWS Secret Access Key ",
                                       optional: true,
                                       default_value: ENV['AWS_SECRET_ACCESS_KEY']),
          FastlaneCore::ConfigItem.new(key: :bucket,
                                       env_name: "S3_BUCKET",
                                       description: "AWS bucket name",
                                       optional: true,
                                       default_value: ENV['AWS_BUCKET_NAME']),
          FastlaneCore::ConfigItem.new(key: :region,
                                       env_name: "S3_REGION",
                                       description: "AWS region (for bucket creation) ",
                                       optional: true,
                                       default_value: ENV['AWS_REGION']),
          FastlaneCore::ConfigItem.new(key: :path,
                                       env_name: "S3_PATH",
                                       description: "S3 'path'. Values from Info.plist will be substituded for keys wrapped in {}  ",
                                       optional: true,
                                       default_value: 'v{CFBundleShortVersionString}_b{CFBundleVersion}/'),
          FastlaneCore::ConfigItem.new(key: :source,
                                       env_name: "S3_SOURCE",
                                       description: "Optional source directory e.g. ./build ",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :acl,
                                       env_name: "S3_ACL",
                                       description: "Uploaded object permissions e.g public_read (default), private, public_read_write, authenticated_read ",
                                       optional: true,
                                       default_value: "public_read")
        ]
      end

      def self.output
        [
          ['S3_IPA_OUTPUT_PATH', 'Direct HTTP link to the uploaded ipa file'],
          ['S3_DSYM_OUTPUT_PATH', 'Direct HTTP link to the uploaded dsym file'],
          ['S3_PLIST_OUTPUT_PATH', 'Direct HTTP link to the uploaded plist file'],
          ['S3_HTML_OUTPUT_PATH', 'Direct HTTP link to the uploaded HTML file'],
          ['S3_VERSION_OUTPUT_PATH', 'Direct HTTP link to the uploaded Version file']
        ]
      end

      def self.author
        "joshdholtz"
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
