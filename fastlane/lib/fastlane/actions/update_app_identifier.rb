module Fastlane
  module Actions
    class UpdateAppIdentifierAction < Action
      def self.run(params)
        require 'plist'
        require 'xcodeproj'

        info_plist_key = 'INFOPLIST_FILE'
        identifier_key = 'PRODUCT_BUNDLE_IDENTIFIER'

        # Read existing plist file
        info_plist_path = resolve_path(params[:plist_path], params[:xcodeproj])
        UI.user_error!("Couldn't find info plist file at path '#{params[:plist_path]}'") unless File.exist?(info_plist_path)
        plist = Plist.parse_xml(info_plist_path)

        # Check if current app identifier product bundle identifier
        app_id_equals_bundle_id = %W($(#{identifier_key}) ${#{identifier_key}}).include?(plist['CFBundleIdentifier'])
        if app_id_equals_bundle_id
          # Load .xcodeproj
          project_path = params[:xcodeproj]
          project = Xcodeproj::Project.open(project_path)

          # Fetch the build configuration objects
          configs = project.objects.select { |obj| obj.isa == 'XCBuildConfiguration' && !obj.build_settings[identifier_key].nil? }
          UI.user_error!("Info plist uses #{identifier_key}, but xcodeproj does not") if configs.empty?

          configs = configs.select { |obj| resolve_path(obj.build_settings[info_plist_key], params[:xcodeproj]) == info_plist_path }
          UI.user_error!("Xcodeproj doesn't have configuration with info plist #{params[:plist_path]}.") if configs.empty?

          # For each of the build configurations, set app identifier
          configs.each do |c|
            c.build_settings[identifier_key] = params[:app_identifier]
          end

          # Write changes to the file
          project.save

          UI.success("Updated #{params[:xcodeproj]} 💾.")
        else
          # Update plist value
          plist['CFBundleIdentifier'] = params[:app_identifier]

          # Write changes to file
          plist_string = Plist::Emit.dump(plist)
          File.write(info_plist_path, plist_string)

          UI.success("Updated #{params[:plist_path]} 💾.")
        end
      end

      def self.resolve_path(path, xcodeproj_path)
        return nil unless path
        project_dir = File.dirname(xcodeproj_path)
        # SRCROOT, SOURCE_ROOT and PROJECT_DIR are the same
        %w{SRCROOT SOURCE_ROOT PROJECT_DIR}.each do |variable_name|
          path = path.sub("$(#{variable_name})", project_dir)
        end
        File.absolute_path(path, project_dir)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end

      def self.description
        "Update the project's bundle identifier"
      end

      def self.details
        "Update an app identifier by either setting `CFBundleIdentifier` or `PRODUCT_BUNDLE_IDENTIFIER`, depending on which is already in use."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                                       env_name: "FL_UPDATE_APP_IDENTIFIER_PROJECT_PATH",
                                       description: "Path to your Xcode project",
                                       code_gen_sensitive: true,
                                       default_value: Dir['*.xcodeproj'].first,
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass the path to the project, not the workspace") unless value.end_with?(".xcodeproj")
                                         UI.user_error!("Could not find Xcode project") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :plist_path,
                                       env_name: "FL_UPDATE_APP_IDENTIFIER_PLIST_PATH",
                                       description: "Path to info plist, relative to your Xcode project",
                                       verify_block: proc do |value|
                                         UI.user_error!("Invalid plist file") unless value[-6..-1].casecmp(".plist").zero?
                                       end),
          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                       env_name: 'FL_UPDATE_APP_IDENTIFIER',
                                       description: 'The app Identifier you want to set',
                                       code_gen_sensitive: true,
                                       default_value: ENV['PRODUCE_APP_IDENTIFIER'] || CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier),
                                       default_value_dynamic: true)
        ]
      end

      def self.authors
        ['squarefrog', 'tobiasstrebitzer']
      end

      def self.example_code
        [
          'update_app_identifier(
            xcodeproj: "Example.xcodeproj", # Optional path to xcodeproj, will use the first .xcodeproj if not set
            plist_path: "Example/Info.plist", # Path to info plist file, relative to xcodeproj
            app_identifier: "com.test.example" # The App Identifier
          )'
        ]
      end

      def self.category
        :project
      end
    end
  end
end
