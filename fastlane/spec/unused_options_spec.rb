describe Fastlane do
  describe Fastlane::Action do
    describe "No unused options" do
      let(:all_exceptions) do
        %w(
          pilot
          appstore
          cert
          deliver
          gym
          match
          pem
          produce
          scan
          sigh
          snapshot
          precheck
          supply
          testflight
          mailgun
          testfairy
          ipa
          import_from_git
          import_from_gem
          hockey
          deploygate
          crashlytics
          artifactory
          appledoc
          slather
          screengrab
          download_dsyms
          notification
          frameit
          set_changelog
          register_device
          register_devices
          latest_testflight_build_number
          app_store_build_number
          sh
          swiftlint
          plugin_scores
          google_play_track_version_codes
          google_play_track_release_names
          modify_services
          build_app
          build_android_app
          build_ios_app
          build_mac_app
          capture_screenshots
          capture_android_screenshots
          capture_ios_screenshots
          check_app_store_metadata
          get_certificates
          create_app_online
          frame_screenshots
          get_provisioning_profile
          get_push_certificate
          run_tests
          submit_build_to_app_store
          sync_code_signing
          upload_to_app_store
          upload_to_play_store
          upload_to_play_store_internal_app_sharing
          upload_to_testflight
          download_universal_apk_from_google_play
          puts
          println
          echo
          xcov
          create_app_on_managed_play_store
          download_from_play_store
          validate_play_store_json_key
          update_fastlane
          s3
          match_nuke
          trainer
        )
      end

      Fastlane::ActionsList.all_actions do |action, name|
        next unless action.available_options.kind_of?(Array)
        next unless action.available_options.last.kind_of?(FastlaneCore::ConfigItem)

        it "No unused parameters in '#{name}'" do
          next if all_exceptions.include?(name)
          content = File.read(File.join("fastlane", "lib", "fastlane", "actions", name + ".rb"))
          action.available_options.each do |option|
            unless content.include?("[:#{option.key}]")
              UI.user_error!("Action '#{name}' doesn't use the option :#{option.key}")
            end
          end
        end
      end
    end
  end
end
