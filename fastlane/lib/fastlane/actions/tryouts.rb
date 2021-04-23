module Fastlane
  module Actions
    module SharedValues
      # Contains all the data returned from the Tryouts API. See http://tryouts.readthedocs.org/en/latest/releases.html#create-release
      TRYOUTS_BUILD_INFORMATION = :TRYOUTS_BUILD_INFORMATION
    end

    class TryoutsAction < Action
      TRYOUTS_API_BUILD_RELEASE_TEMPLATE = "https://api.tryouts.io/v1/applications/%s/releases/"

      def self.run(params)
        UI.success('Upload to Tryouts has been started. This may take some time.')

        response = self.upload_build(params)

        case response.status
        when 200...300
          Actions.lane_context[SharedValues::TRYOUTS_BUILD_INFORMATION] = response.body
          UI.success('Build successfully uploaded to Tryouts!')
          UI.message("Release download url: #{response.body['download_url']}") if response.body["download_url"]
        else
          UI.user_error!("Error when trying to upload build file to Tryouts: #{response.body}")
        end
      end

      def self.upload_build(params)
        require 'faraday'
        require 'faraday_middleware'

        url = TRYOUTS_API_BUILD_RELEASE_TEMPLATE % params[:app_id]
        connection = Faraday.new(url) do |builder|
          builder.request(:multipart)
          builder.request(:url_encoded)
          builder.response(:json, content_type: /\bjson$/)
          builder.use(FaradayMiddleware::FollowRedirects)
          builder.adapter(:net_http)
        end

        options = {}
        options[:build] = Faraday::UploadIO.new(params[:build_file], 'application/octet-stream')

        if params[:notes_path]
          options[:notes] = File.read(params[:notes_path])
        elsif params[:notes]
          options[:notes] = params[:notes]
        end

        options[:notify] = params[:notify].to_s
        options[:status] = params[:status].to_s

        post_request = connection.post do |req|
          req.headers['Authorization'] = params[:api_token]
          req.body = options
        end

        post_request.on_complete do |env|
          yield(env[:status], env[:body]) if block_given?
        end
      end

      def self.description
        "Upload a new build to [Tryouts](https://tryouts.io/)"
      end

      def self.details
        "More information: [http://tryouts.readthedocs.org/en/latest/releases.html#create-release](http://tryouts.readthedocs.org/en/latest/releases.html#create-release)"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :app_id,
                                     env_name: "TRYOUTS_APP_ID",
                                     description: "Tryouts application hash",
                                     verify_block: proc do |value|
                                       UI.user_error!("No application identifier for Tryouts given, pass using `app_id: 'application id'`") unless value && !value.empty?
                                     end),
          FastlaneCore::ConfigItem.new(key: :api_token,
                                     env_name: "TRYOUTS_API_TOKEN",
                                     sensitive: true,
                                     description: "API Token (api_key:api_secret) for Tryouts Access",
                                     verify_block: proc do |value|
                                       UI.user_error!("No API token for Tryouts given, pass using `api_token: 'token'`") unless value && !value.empty?
                                     end),
          FastlaneCore::ConfigItem.new(key: :build_file,
                                     env_name: "TRYOUTS_BUILD_FILE",
                                     description: "Path to your IPA or APK file. Optional if you use the _gym_ or _xcodebuild_ action",
                                     default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
                                       default_value_dynamic: true,
                                     verify_block: proc do |value|
                                       UI.user_error!("Couldn't find build file at path '#{value}'") unless File.exist?(value)
                                     end),
          FastlaneCore::ConfigItem.new(key: :notes,
                                     env_name: "TRYOUTS_NOTES",
                                     description: "Release notes",
                                     is_string: true,
                                     optional: true),
          FastlaneCore::ConfigItem.new(key: :notes_path,
                                     env_name: "TRYOUTS_NOTES_PATH",
                                     description: "Release notes text file path. Overrides the :notes parameter",
                                     verify_block: proc do |value|
                                       UI.user_error!("Couldn't find notes file at path '#{value}'") unless File.exist?(value)
                                     end,
                                     optional: true),
          FastlaneCore::ConfigItem.new(key: :notify,
                                     env_name: "TRYOUTS_NOTIFY",
                                     description: "Notify testers? 0 for no",
                                     is_string: false,
                                     default_value: 1),
          FastlaneCore::ConfigItem.new(key: :status,
                                     env_name: "TRYOUTS_STATUS",
                                     description: "2 to make your release public. Release will be distributed to available testers. 1 to make your release private. Release won't be distributed to testers. This also prevents release from showing up for SDK update",
                                     verify_block: proc do |value|
                                       available_options = ["1", "2"]
                                       UI.user_error!("'#{value}' is not a valid 'status' value. Available options are #{available_options.join(', ')}") unless available_options.include?(value.to_s)
                                     end,
                                     is_string: false,
                                     default_value: 2)
        ]
      end

      def self.example_code
        [
          'tryouts(
            api_token: "...",
            app_id: "application-id",
            build_file: "test.ipa",
          )'
        ]
      end

      def self.category
        :beta
      end

      def self.output
        [
          ['TRYOUTS_BUILD_INFORMATION', 'Contains release info like :application_name, :download_url. See http://tryouts.readthedocs.org/en/latest/releases.html#create-release']
        ]
      end

      def self.authors
        ["alicertel"]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end
