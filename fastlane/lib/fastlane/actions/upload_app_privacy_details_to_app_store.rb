module Fastlane
  module Actions
    class UploadAppPrivacyDetailsToAppStoreAction < Action
      DEFAULT_PATH = Fastlane::Helper.fastlane_enabled_folder_path
      DEFAULT_FILE_NAME = "app_privacy_details.json"

      def self.run(params)
        require 'spaceship'

        # Prompts select team if multiple teams and none specified
        UI.message("Login to App Store Connect (#{params[:username]})")
        Spaceship::ConnectAPI.login(params[:username], use_portal: false, use_tunes: true, tunes_team_id: params[:team_id], team_name: params[:team_name])
        UI.message("Login successful")

        # Get App
        app = Spaceship::ConnectAPI::App.find(params[:app_identifier])
        unless app
          UI.user_error!("Could not find app with bundle identifier '#{params[:app_identifier]}' on account #{params[:username]}")
        end

        # Attempt to load JSON file
        usages_config = load_json_file(params)

        # Start interactive questions to generate and save JSON file
        unless usages_config
          usages_config = ask_interactive_questions_for_json

          if params[:skip_json_file_saving]
            UI.message("Skipping JSON file saving...")
          else
            json = JSON.pretty_generate(usages_config)
            path = output_path(params)

            UI.message("Writing file to #{path}")
            File.write(path, json)
          end
        end

        # Process JSON file to save app data usages to API
        if params[:skip_upload]
          UI.message("Skipping uploading of data... (so you can verify your JSON file)")
        else
          upload_app_data_usages(params, app, usages_config)
        end
      end

      def self.load_json_file(params)
        path = params[:json_path]
        return nil if path.nil?
        return JSON.parse(File.read(path))
      end

      def self.output_path(params)
        path = params[:output_json_path]
        return File.absolute_path(path)
      end

      def self.ask_interactive_questions_for_json(show_intro = true)
        if show_intro
          UI.important("You did not provide a JSON file for updating the app data usages")
          UI.important("fastlane will now run you through interactive question to generate the JSON file")
          UI.important("")
          UI.important("This JSON file can be saved in source control and used in this action with the :json_file option")

          unless UI.confirm("Ready to start?")
            UI.user_error!("Cancelled")
          end
        end

        # Fetch categories and purposes used for generating interactive questions
        categories = Spaceship::ConnectAPI::AppDataUsageCategory.all(includes: "grouping")
        purposes = Spaceship::ConnectAPI::AppDataUsagePurpose.all

        json = []

        unless UI.confirm("Are you collecting data?")
          json << {
            "data_protections" => [Spaceship::ConnectAPI::AppDataUsageDataProtection::ID::DATA_NOT_COLLECTED]
          }

          return json
        end

        categories.each do |category|
          # Ask if using category
          next unless UI.confirm("Collect data for #{category.id}?")

          purpose_names = purposes.map(&:id).join(', ')
          UI.message("How will this data be used? You'll be offered with #{purpose_names}")

          # Ask purposes
          selected_purposes = []
          loop do
            purposes.each do |purpose|
              selected_purposes << purpose if UI.confirm("Used for #{purpose.id}?")
            end

            break unless selected_purposes.empty?
            break unless UI.confirm("No purposes selected. Do you want to try again?")
          end

          # Skip asking protections if purposes were skipped
          next if selected_purposes.empty?

          # Ask protections
          is_linked_to_user = UI.confirm("Is #{category.id} linked to the user?")
          is_used_for_tracking = UI.confirm("Is #{category.id} used for tracking purposes?")

          # Map answers to values for API requests
          protection_id = is_linked_to_user ? Spaceship::ConnectAPI::AppDataUsageDataProtection::ID::DATA_LINKED_TO_YOU : Spaceship::ConnectAPI::AppDataUsageDataProtection::ID::DATA_NOT_LINKED_TO_YOU
          tracking_id = is_used_for_tracking ? Spaceship::ConnectAPI::AppDataUsageDataProtection::ID::DATA_USED_TO_TRACK_YOU : nil

          json << {
            "category" => category.id,
            "purposes" => selected_purposes.map(&:id).sort.uniq,
            "data_protections" => [
              protection_id, tracking_id
            ].compact.sort.uniq
          }
        end

        json.sort_by! { |c| c["category"] }

        # Recursively call this method if no categories were selected for data collection
        if json.empty?
          UI.error("No categories were selected for data collection.")
          json = ask_interactive_questions_for_json(false)
        end

        return json
      end

      def self.upload_app_data_usages(params, app, usages_config)
        UI.message("Preparing to upload App Data Usage")

        remote_usages = Spaceship::ConnectAPI::AppDataUsage.all(app_id: app.id, includes: "category,grouping,purpose,dataProtection", limit: 500)
        remote_usages_config_hash = Fastlane::Helper::AppPrivacyDetailsHelper.usages_config_from_raw_usages(raw_usages: remote_usages)

        remote_advertising_data_config = remote_usages_config_hash.find do |config|
          config["category"] == Spaceship::ConnectAPI::AppDataUsageCategory::ID::ADVERTISING_DATA
        end
        local_advertising_data_config = usages_config.find do |config|
          config["category"] == Spaceship::ConnectAPI::AppDataUsageCategory::ID::ADVERTISING_DATA
        end
        local_usages_include_advertising_data = !local_advertising_data_config.nil?
        local_and_remote_advertising_data_config_are_identical = local_advertising_data_config == remote_advertising_data_config
        skipped_advertising_data_deletion = false

        # Delete all remote app data usage we can, so we can reupload local ones
        remote_usages.each do |usage|
          if usage.category.id == Spaceship::ConnectAPI::AppDataUsageCategory::ID::ADVERTISING_DATA
            if local_usages_include_advertising_data
              UI.verbose("The app privacy details currently stored in App Store Connect indicate this app tracks advertising data, and so does the local app privacy details that are being uploaded to App Store Connect.")
              UI.verbose("We normally delete all remote settings, but we can't delete the 'ADVERTISING_DATA' one. This is because:")
              UI.verbose("    a) If the app still collects advertising data (i.e. contains 'NSUserTrackingUsageDescription' in its Info.plist), then attempting to delete it from App Store Connect would raise an error such as 'Your binary indicates that your app tracks users.'")
              UI.verbose("    b) If the remote and local app privacy details are identical, we don't really have a need to delete or re-upload anything.")
              unless local_and_remote_advertising_data_config_are_identical
                UI.important("Looks like you're attempting to make changes to your ADVERTISING_DATA app privacy details.")
                UI.important("Please make this change manually via App Store Connect. Since this is a one-off (and rare) situation, which the App Store Connect API doesn't really support, unfortunately this is the only solution for now.")
                UI.important("Don't forget to download the app privacy details using the 'download_app_privacy_details_from_app_store' action when you're done, to update the local json.")
              end
              skipped_advertising_data_deletion = true
              next
            else
              UI.important("The app privacy details currently stored in App Store Connect indicate this app tracks advertising data, while the local app privacy details that is being uploaded to App Store Connect indicate it doesn't.")
              UI.important("We're going to assume that your app's Info.plist that is currently available in App Store Connect doesn't contain a `NSUserTrackingUsageDescription` key anymore, already. If it does, the following actions will fail.")
              UI.important("This is often caused by either bad configuration on the local app privacy settings, or because the app is legitimately not tracking advertisements anymore.")
              UI.important("If the former, make sure the data collection questionnaire (or json file) is accurate.")
              UI.important("If the latter, make sure you upload your app's latest binary to App Store Connect, and remember that its Info.plist cannot contain the `NSUserTrackingUsageDescription` key anymore.")
            end
          end
          usage.delete!
        end

        # Upload local app data usage
        usages_config.each do |usage_config|
          category = usage_config["category"]
          purposes = usage_config["purposes"] || []
          data_protections = usage_config["data_protections"] || []
          # If we don't skip it, an error would be raised, e.g. "A data usage with category ADVERTISING_DATA, purpose THIRD_PARTY_ADVERTISING and data protection DATA_NOT_LINKED_TO_YOU already exists." because we skipped the setting deletion previously
          next if skipped_advertising_data_deletion

          # There will not be any purposes if "not collecting data"
          # However, an AppDataUsage still needs to be created for not collecting data
          # Creating an array with nil so that purposes can be iterated over and
          # that AppDataUsage can be created
          purposes = [nil] if purposes.empty?

          purposes.each do |purpose|
            data_protections.each do |data_protection|
              if data_protection == Spaceship::ConnectAPI::AppDataUsageDataProtection::ID::DATA_NOT_COLLECTED
                UI.message("Setting #{data_protection}")
              else
                UI.message("Setting #{category} and #{purpose} to #{data_protection}")
              end

              Spaceship::ConnectAPI::AppDataUsage.create(
                app_id: app.id,
                app_data_usage_category_id: category,
                app_data_usage_protection_id: data_protection,
                app_data_usage_purpose_id: purpose
              )
            end
          end
        end

        # Publish
        if params[:skip_publish]
          UI.message("Skipping app data usage publishing... (so you can verify on App Store Connect)")
        else
          publish_state = Spaceship::ConnectAPI::AppDataUsagesPublishState.get(app_id: app.id)
          if publish_state.published
            UI.important("App data usage is already published")
          else
            UI.important("App data usage not published! Going to publish...")
            publish_state.publish!
            UI.important("App data usage is now published")
          end
        end
      end

      def self.description
        "Upload App Privacy Details for an app in App Store Connect"
      end

      def self.available_options
        user = CredentialsManager::AppfileConfig.try_fetch_value(:itunes_connect_id)
        user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)

        [
          FastlaneCore::ConfigItem.new(key: :username,
                                       env_name: "FASTLANE_USER",
                                       description: "Your Apple ID Username for App Store Connect",
                                       default_value: user,
                                       default_value_dynamic: true),
          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                       env_name: "UPLOAD_APP_PRIVACY_DETAILS_TO_APP_STORE_APP_IDENTIFIER",
                                       description: "The bundle identifier of your app",
                                       code_gen_sensitive: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier),
                                       default_value_dynamic: true),
          FastlaneCore::ConfigItem.new(key: :team_id,
                                       env_name: "FASTLANE_ITC_TEAM_ID",
                                       description: "The ID of your App Store Connect team if you're in multiple teams",
                                       optional: true,
                                       skip_type_validation: true, # as we also allow integers, which we convert to strings anyway
                                       code_gen_sensitive: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_id),
                                       default_value_dynamic: true),
          FastlaneCore::ConfigItem.new(key: :team_name,
                                       env_name: "FASTLANE_ITC_TEAM_NAME",
                                       description: "The name of your App Store Connect team if you're in multiple teams",
                                       optional: true,
                                       code_gen_sensitive: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_name),
                                       default_value_dynamic: true),

          # JSON paths
          FastlaneCore::ConfigItem.new(key: :json_path,
                                       env_name: "UPLOAD_APP_PRIVACY_DETAILS_TO_APP_STORE_JSON_PATH",
                                       description: "Path to the app usage data JSON",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Could not find JSON file at path '#{File.expand_path(value)}'") unless File.exist?(value)
                                         UI.user_error!("'#{value}' doesn't seem to be a JSON file") unless FastlaneCore::Helper.json_file?(File.expand_path(value))
                                       end),
          FastlaneCore::ConfigItem.new(key: :output_json_path,
                                       env_name: "UPLOAD_APP_PRIVACY_DETAILS_TO_APP_STORE_OUTPUT_JSON_PATH",
                                       description: "Path to the app usage data JSON file generated by interactive questions",
                                       conflicting_options: [:skip_json_file_saving],
                                       default_value: File.join(DEFAULT_PATH, DEFAULT_FILE_NAME)),

          # Skipping options
          FastlaneCore::ConfigItem.new(key: :skip_json_file_saving,
                                       env_name: "UPLOAD_APP_PRIVACY_DETAILS_TO_APP_STORE_OUTPUT_SKIP_JSON_FILE_SAVING",
                                       description: "Whether to skip the saving of the JSON file",
                                       conflicting_options: [:skip_output_json_path],
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :skip_upload,
                                       env_name: "UPLOAD_APP_PRIVACY_DETAILS_TO_APP_STORE_OUTPUT_SKIP_UPLOAD",
                                       description: "Whether to skip the upload and only create the JSON file with interactive questions",
                                       conflicting_options: [:skip_publish],
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :skip_publish,
                                       env_name: "UPLOAD_APP_PRIVACY_DETAILS_TO_APP_STORE_OUTPUT_SKIP_PUBLISH",
                                       description: "Whether to skip the publishing",
                                       conflicting_options: [:skip_upload],
                                       type: Boolean,
                                       default_value: false)
        ]
      end

      def self.author
        "joshdholtz"
      end

      def self.is_supported?(platform)
        [:ios, :mac, :tvos].include?(platform)
      end

      def self.details
        "Upload App Privacy Details for an app in App Store Connect. For more detail information, view https://docs.fastlane.tools/uploading-app-privacy-details"
      end

      def self.example_code
        [
          'upload_app_privacy_details_to_app_store(
            username: "your@email.com",
            team_name: "Your Team",
            app_identifier: "com.your.bundle"
          )',
          'upload_app_privacy_details_to_app_store(
            username: "your@email.com",
            team_name: "Your Team",
            app_identifier: "com.your.bundle",
            json_path: "fastlane/app_data_usages.json"
          )'
        ]
      end

      def self.category
        :production
      end
    end
  end
end
