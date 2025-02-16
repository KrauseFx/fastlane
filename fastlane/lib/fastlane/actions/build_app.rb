module Fastlane
  module Actions
    module SharedValues
      IPA_OUTPUT_PATH ||= :IPA_OUTPUT_PATH
      PKG_OUTPUT_PATH ||= :PKG_OUTPUT_PATH
      DSYM_OUTPUT_PATH ||= :DSYM_OUTPUT_PATH
      XCODEBUILD_ARCHIVE ||= :XCODEBUILD_ARCHIVE # originally defined in XcodebuildAction
      GYM_BUILD_TIME = :GYM_BUILD_TIME
    end

    class BuildAppAction < Action
      # rubocop:disable Metrics/PerceivedComplexity
      def self.run(values)
        require 'gym'

        unless Actions.lane_context[SharedValues::SIGH_PROFILE_TYPE].to_s == "development"
          values[:export_method] ||= Actions.lane_context[SharedValues::SIGH_PROFILE_TYPE]
        end

        if Actions.lane_context[SharedValues::MATCH_PROVISIONING_PROFILE_MAPPING]
          # Since Xcode 9 you need to explicitly provide the provisioning profile per app target
          # If the user is smart and uses match and gym together with fastlane, we can do all
          # the heavy lifting for them
          values[:export_options] ||= {}
          # It's not always a hash, because the user might have passed a string path to a ready plist file
          # If that's the case, we won't set the provisioning profiles
          # see https://github.com/fastlane/fastlane/issues/9490
          if values[:export_options].kind_of?(Hash)
            match_mapping = (Actions.lane_context[SharedValues::MATCH_PROVISIONING_PROFILE_MAPPING] || {}).dup
            existing_mapping = (values[:export_options][:provisioningProfiles] || {}).dup

            # Be smart about how we merge those mappings in case there are conflicts
            mapping_object = Gym::CodeSigningMapping.new
            hash_to_use = mapping_object.merge_profile_mapping(primary_mapping: existing_mapping,
                                                             secondary_mapping: match_mapping,
                                                                export_method: values[:export_method])

            values[:export_options][:provisioningProfiles] = hash_to_use
          else
            self.show_xcode_9_warning
          end
        elsif Actions.lane_context[SharedValues::SIGH_PROFILE_PATHS]
          # Since Xcode 9 you need to explicitly provide the provisioning profile per app target
          # If the user used sigh we can match the profiles from sigh
          values[:export_options] ||= {}
          if values[:export_options].kind_of?(Hash)
            # It's not always a hash, because the user might have passed a string path to a ready plist file
            # If that's the case, we won't set the provisioning profiles
            # see https://github.com/fastlane/fastlane/issues/9684
            values[:export_options][:provisioningProfiles] ||= {}
            Actions.lane_context[SharedValues::SIGH_PROFILE_PATHS].each do |profile_path|
              begin
                profile = FastlaneCore::ProvisioningProfile.parse(profile_path)
                app_id_prefix = profile["ApplicationIdentifierPrefix"].first
                entitlements = profile["Entitlements"]
                bundle_id = (entitlements["application-identifier"] || entitlements["com.apple.application-identifier"]).gsub("#{app_id_prefix}.", "")
                values[:export_options][:provisioningProfiles][bundle_id] = profile["Name"]
              rescue => ex
                UI.error("Couldn't load profile at path: #{profile_path}")
                UI.error(ex)
                UI.verbose(ex.backtrace.join("\n"))
              end
            end
          else
            self.show_xcode_9_warning
          end
        end

        manager = Gym::Manager.new
        gym_output_path = manager.work(values)
        if gym_output_path.nil?
          UI.important("No output path received from gym")
          return nil
        end

        absolute_output_path = File.expand_path(gym_output_path)

        # Binary path
        if File.extname(absolute_output_path) == ".ipa"
          absolute_dsym_path = absolute_output_path.gsub(/.ipa$/, ".app.dSYM.zip")

          Actions.lane_context[SharedValues::IPA_OUTPUT_PATH] = absolute_output_path
          ENV[SharedValues::IPA_OUTPUT_PATH.to_s] = absolute_output_path # for deliver
        elsif File.extname(absolute_output_path) == ".pkg"
          absolute_dsym_path = absolute_output_path.gsub(/.pkg$/, ".dSYM.zip")

          Actions.lane_context[SharedValues::PKG_OUTPUT_PATH] = absolute_output_path
          ENV[SharedValues::PKG_OUTPUT_PATH.to_s] = absolute_output_path # for deliver
        end

        # xcarchive path
        Actions.lane_context[SharedValues::XCODEBUILD_ARCHIVE] = Gym::BuildCommandGenerator.archive_path

        # dSYM path
        if absolute_dsym_path && File.exist?(absolute_dsym_path)
          Actions.lane_context[SharedValues::DSYM_OUTPUT_PATH] = absolute_dsym_path
          ENV[SharedValues::DSYM_OUTPUT_PATH.to_s] = absolute_dsym_path
        end

        # build time spent for `xcodebuild build/archive`
        # If you give true to skip_build_archive, this is going to be `nil`.
        Actions.lane_context[SharedValues::GYM_BUILD_TIME] = manager.build_time

        return absolute_output_path
      end
      # rubocop:enable Metrics/PerceivedComplexity

      def self.description
        "Easily build and sign your app (via _gym_)"
      end

      def self.details
        "More information: https://fastlane.tools/gym"
      end

      def self.output
        [
          ['IPA_OUTPUT_PATH', 'The path to the newly generated ipa file'],
          ['PKG_OUTPUT_PATH', 'The path to the newly generated pkg file'],
          ['DSYM_OUTPUT_PATH', 'The path to the dSYM files'],
          ['XCODEBUILD_ARCHIVE', 'The path to the xcodebuild archive'],
          ['GYM_BUILD_TIME', 'The build time spent for xcodebuild archive/build']
        ]
      end

      def self.return_value
        "The absolute path to the generated ipa file"
      end

      def self.return_type
        :string
      end

      def self.author
        "KrauseFx"
      end

      def self.available_options
        require 'gym'
        Gym::Options.available_options
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.example_code
        [
          'build_app(scheme: "MyApp", workspace: "MyApp.xcworkspace")',
          'build_app(
            workspace: "MyApp.xcworkspace",
            configuration: "Debug",
            scheme: "MyApp",
            silent: true,
            clean: true,
            output_directory: "path/to/dir", # Destination directory. Defaults to current directory.
            output_name: "my-app.ipa",       # specify the name of the .ipa file to generate (including file extension)
            sdk: "iOS 11.1"                  # use SDK as the name or path of the base SDK when building the project.
          )',
          'gym              # alias for "build_app"',
          'build_ios_app    # alias for "build_app (only iOS options)"',
          'build_mac_app    # alias for "build_app (only macOS options)"'
        ]
      end

      def self.category
        :building
      end

      def self.show_xcode_9_warning
        return unless Helper.xcode_at_least?("9.0")
        UI.message("You passed a path to a custom plist file for exporting the binary.")
        UI.message("Make sure to include information about what provisioning profiles to use with Xcode 9")
        UI.message("More information: https://docs.fastlane.tools/codesigning/xcode-project/#xcode-9-and-up")
      end
    end
  end
end
