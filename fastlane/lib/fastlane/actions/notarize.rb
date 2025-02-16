module Fastlane
  module Actions
    class NotarizeAction < Action
      # rubocop:disable Metrics/PerceivedComplexity
      def self.run(params)
        package_path = params[:package]
        bundle_id = params[:bundle_id]
        skip_stapling = params[:skip_stapling]
        try_early_stapling = params[:try_early_stapling]
        print_log = params[:print_log]
        verbose = params[:verbose]

        # Only set :api_key from SharedValues if :api_key_path isn't set (conflicting options)
        unless params[:api_key_path]
          params[:api_key] ||= Actions.lane_context[SharedValues::APP_STORE_CONNECT_API_KEY]
        end
        api_key = Spaceship::ConnectAPI::Token.from(hash: params[:api_key], filepath: params[:api_key_path])

        use_notarytool = params[:use_notarytool]

        # Compress and read bundle identifier only for .app bundle.
        compressed_package_path = nil
        if File.extname(package_path) == '.app'
          compressed_package_path = "#{package_path}.zip"
          Actions.sh(
            "ditto -c -k --rsrc --sequesterRsrc --keepParent \"#{package_path}\" \"#{compressed_package_path}\"",
            log: verbose
          )

          unless bundle_id
            info_plist_path = File.join(package_path, 'Contents', 'Info.plist')
            bundle_id = Actions.sh(
              "/usr/libexec/PlistBuddy -c \"Print :CFBundleIdentifier\" \"#{info_plist_path}\"",
              log: verbose
            ).strip
          end
        end

        UI.user_error!('Could not read bundle identifier, provide as a parameter') unless bundle_id

        if use_notarytool
          notarytool(params, package_path, bundle_id, skip_stapling, print_log, verbose, api_key, compressed_package_path)
        else
          altool(params, package_path, bundle_id, try_early_stapling, skip_stapling, print_log, verbose, api_key, compressed_package_path)
        end
      end

      def self.notarytool(params, package_path, bundle_id, skip_stapling, print_log, verbose, api_key, compressed_package_path)
        temp_file = nil

        # Create authorization part of command with either API Key or Apple ID
        auth_parts = []
        if api_key
          # Writes key contents to temporary file for command
          require 'tempfile'
          temp_file = Tempfile.new
          api_key.write_key_to_file(temp_file.path)

          auth_parts << "--key #{temp_file.path}"
          auth_parts << "--key-id #{api_key.key_id}"
          auth_parts << "--issuer #{api_key.issuer_id}"
        else
          auth_parts << "--apple-id #{params[:username]}"
          auth_parts << "--password #{ENV['FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD']}"
          auth_parts << "--team-id #{params[:asc_provider]}"
        end

        # Submits package and waits for processing using `xcrun notarytool submit --wait`
        submit_parts = [
          "xcrun notarytool submit",
          (compressed_package_path || package_path).shellescape,
          "--output-format json",
          "--wait"
        ] + auth_parts

        submit_command = submit_parts.join(' ')
        submit_response = Actions.sh(
          submit_command,
          log: verbose,
          error_callback: lambda { |msg|
            UI.error("Error polling for notarization info: #{msg}")
          }
        )

        notarization_info = JSON.parse(submit_response)

        # Staple
        submission_id = notarization_info["id"]
        case notarization_info['status']
        when 'Accepted'
          UI.success("Successfully uploaded package to notarization service with request identifier #{submission_id}")

          if skip_stapling
            UI.success("Successfully notarized artifact")
          else
            UI.message('Stapling package')

            self.staple(package_path, verbose)

            UI.success("Successfully notarized and stapled package")
          end
        when 'Invalid'
          if submission_id && print_log
            log_request_parts = [
              "xcrun notarytool log #{submission_id}"
            ] + auth_parts
            log_request_command = log_request_parts.join(' ')
            log_request_response = Actions.sh(
              log_request_command,
              log: verbose,
              error_callback: lambda { |msg|
                UI.error("Error requesting the notarization log: #{msg}")
              }
            )
            UI.user_error!("Could not notarize package with message '#{log_request_response}'")
          else
            UI.user_error!("Could not notarize package. To see the error, please set 'print_log' to true.")
          end
        else
          UI.crash!("Could not notarize package with status '#{notarization_info['status']}'")
        end
      ensure
        temp_file.delete if temp_file
      end

      def self.altool(params, package_path, bundle_id, try_early_stapling, skip_stapling, print_log, verbose, api_key, compressed_package_path)
        UI.message('Uploading package to notarization service, might take a while')

        notarization_upload_command = "xcrun altool --notarize-app -t osx -f \"#{compressed_package_path || package_path}\" --primary-bundle-id #{bundle_id} --output-format xml"

        notarization_info = {}
        with_notarize_authenticator(params, api_key) do |notarize_authenticator|
          notarization_upload_command << " --asc-provider \"#{params[:asc_provider]}\"" if params[:asc_provider] && api_key.nil?

          notarization_upload_response = Actions.sh(
            notarize_authenticator.call(notarization_upload_command),
            log: verbose
          )

          FileUtils.rm_rf(compressed_package_path) if compressed_package_path

          notarization_upload_plist = Plist.parse_xml(notarization_upload_response)

          if notarization_upload_plist.key?('product-errors') && notarization_upload_plist['product-errors'].any?
            UI.important("🚫 Could not upload package to notarization service! Here are the reasons:")
            notarization_upload_plist['product-errors'].each { |product_error| UI.error("#{product_error['message']} (#{product_error['code']})") }
            UI.user_error!("Package upload to notarization service cancelled. Please check the error messages above.")
          end

          notarization_request_id = notarization_upload_plist['notarization-upload']['RequestUUID']

          UI.success("Successfully uploaded package to notarization service with request identifier #{notarization_request_id}")

          while notarization_info.empty? || (notarization_info['Status'] == 'in progress')
            if notarization_info.empty?
              UI.message('Waiting to query request status')
            elsif try_early_stapling && !skip_stapling
              UI.message('Request in progress, trying early staple')

              begin
                self.staple(package_path, verbose)
                UI.message('Successfully notarized and early stapled package.')

                return
              rescue
                UI.message('Early staple failed, waiting to query again')
              end
            end

            sleep(30)

            UI.message('Querying request status')

            # As of July 2020, the request UUID might not be available for polling yet which returns an error code
            # This is now handled with the error_callback (which prevents an error from being raised)
            # Catching this error allows for polling to continue until the notarization is complete
            error = false
            notarization_info_response = Actions.sh(
              notarize_authenticator.call("xcrun altool --notarization-info #{notarization_request_id} --output-format xml"),
              log: verbose,
              error_callback: lambda { |msg|
                error = true
                UI.error("Error polling for notarization info: #{msg}")
              }
            )

            unless error
              notarization_info_plist = Plist.parse_xml(notarization_info_response)
              notarization_info = notarization_info_plist['notarization-info']
            end
          end
        end
        # rubocop:enable Metrics/PerceivedComplexity

        log_url = notarization_info['LogFileURL']
        ENV['FL_NOTARIZE_LOG_FILE_URL'] = log_url
        log_suffix = ''
        if log_url && print_log
          log_response = Net::HTTP.get(URI(log_url))
          log_json_object = JSON.parse(log_response)
          log_suffix = ", with log:\n#{JSON.pretty_generate(log_json_object)}"
        end

        case notarization_info['Status']
        when 'success'
          if skip_stapling
            UI.success("Successfully notarized artifact#{log_suffix}")
          else
            UI.message('Stapling package')

            self.staple(package_path, verbose)

            UI.success("Successfully notarized and stapled package#{log_suffix}")
          end
        when 'invalid'
          UI.user_error!("Could not notarize package with message '#{notarization_info['Status Message']}'#{log_suffix}")
        else
          UI.crash!("Could not notarize package with status '#{notarization_info['Status']}'#{log_suffix}")
        end
      ensure
        ENV.delete('FL_NOTARIZE_PASSWORD')
      end

      def self.staple(package_path, verbose)
        Actions.sh(
          "xcrun stapler staple #{package_path.shellescape}",
          log: verbose
        )
      end

      def self.with_notarize_authenticator(params, api_key)
        if api_key
          # From xcrun altool for --apiKey:
          # This option will search the following directories in sequence for a private key file with the name of 'AuthKey_<api_key>.p8':  './private_keys', '~/private_keys', '~/.private_keys', and '~/.appstoreconnect/private_keys'.
          api_key_folder_path = File.expand_path('~/.appstoreconnect/private_keys')
          api_key_file_path = File.join(api_key_folder_path, "AuthKey_#{api_key.key_id}.p8")
          directory_exists = File.directory?(api_key_folder_path)
          file_exists = File.exist?(api_key_file_path)
          begin
            FileUtils.mkdir_p(api_key_folder_path) unless directory_exists
            api_key.write_key_to_file(api_key_file_path) unless file_exists

            yield(proc { |command| "#{command} --apiKey #{api_key.key_id} --apiIssuer #{api_key.issuer_id}" })
          ensure
            FileUtils.rm(api_key_file_path) unless file_exists
            FileUtils.rm_r(api_key_folder_path) unless directory_exists
          end
        else
          apple_id_account = CredentialsManager::AccountManager.new(user: params[:username])

          # Add password as a temporary environment variable for altool.
          # Use app specific password if specified.
          ENV['FL_NOTARIZE_PASSWORD'] = ENV['FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD'] || apple_id_account.password

          yield(proc { |command| "#{command} -u #{apple_id_account.user} -p @env:FL_NOTARIZE_PASSWORD" })
        end
      end

      def self.description
        'Notarizes a macOS app'
      end

      def self.authors
        ['zeplin']
      end

      def self.available_options
        username = CredentialsManager::AppfileConfig.try_fetch_value(:apple_dev_portal_id)
        username ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)

        asc_provider = CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_id)

        [
          FastlaneCore::ConfigItem.new(key: :package,
                                       env_name: 'FL_NOTARIZE_PACKAGE',
                                       description: 'Path to package to notarize, e.g. .app bundle or disk image',
                                       verify_block: proc do |value|
                                         UI.user_error!("Could not find package at '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :use_notarytool,
                                       env_name: 'FL_NOTARIZE_USE_NOTARYTOOL',
                                       description: 'Whether to `xcrun notarytool` or `xcrun altool`',
                                       default_value: Helper.mac? && Helper.xcode_at_least?("13.0"), # Notary tool added in Xcode 13
                                       default_value_dynamic: true,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :try_early_stapling,
                                       env_name: 'FL_NOTARIZE_TRY_EARLY_STAPLING',
                                       description: 'Whether to try early stapling while the notarization request is in progress',
                                       optional: true,
                                       conflicting_options: [:skip_stapling],
                                       default_value: false,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :skip_stapling,
                                       env_name: 'FL_NOTARIZE_SKIP_STAPLING',
                                       description: 'Do not staple the notarization ticket to the artifact; useful for single file executables and ZIP archives',
                                       optional: true,
                                       conflicting_options: [:try_early_stapling],
                                       default_value: false,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :bundle_id,
                                       env_name: 'FL_NOTARIZE_BUNDLE_ID',
                                       description: 'Bundle identifier to uniquely identify the package',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :username,
                                       env_name: 'FL_NOTARIZE_USERNAME',
                                       description: 'Apple ID username',
                                       default_value: username,
                                       optional: true,
                                       conflicting_options: [:api_key_path, :api_key],
                                       default_value_dynamic: true),
          FastlaneCore::ConfigItem.new(key: :asc_provider,
                                       env_name: 'FL_NOTARIZE_ASC_PROVIDER',
                                       description: 'Provider short name for accounts associated with multiple providers',
                                       optional: true,
                                       default_value: asc_provider),
          FastlaneCore::ConfigItem.new(key: :print_log,
                                       env_name: 'FL_NOTARIZE_PRINT_LOG',
                                       description: 'Whether to print notarization log file, listing issues on failure and warnings on success',
                                       optional: true,
                                       default_value: false,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :verbose,
                                       env_name: 'FL_NOTARIZE_VERBOSE',
                                       description: 'Whether to log requests',
                                       optional: true,
                                       default_value: false,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :api_key_path,
                                       env_names: ['FL_NOTARIZE_API_KEY_PATH', "APP_STORE_CONNECT_API_KEY_PATH"],
                                       description: "Path to your App Store Connect API Key JSON file (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)",
                                       optional: true,
                                       conflicting_options: [:username, :api_key],
                                       verify_block: proc do |value|
                                         UI.user_error!("API Key not found at '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :api_key,
                                       env_names: ['FL_NOTARIZE_API_KEY', "APP_STORE_CONNECT_API_KEY"],
                                       description: "Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)",
                                       optional: true,
                                       conflicting_options: [:username, :api_key_path],
                                       sensitive: true,
                                       type: Hash)
        ]
      end

      def self.is_supported?(platform)
        platform == :mac
      end

      def self.category
        :code_signing
      end
    end
  end
end
