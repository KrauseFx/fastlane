module Fastlane
  module Actions
    module SharedValues
      VERSION_NUMBER ||= :VERSION_NUMBER # originally defined in IncrementVersionNumberAction
    end

    class GetVersionNumberAction < Action
      require 'shellwords'

      def self.run(params)
        xcodeproj_path_or_dir = params[:xcodeproj] || '.'
        xcodeproj_dir = File.extname(xcodeproj_path_or_dir) == ".xcodeproj" ? File.dirname(xcodeproj_path_or_dir) : xcodeproj_path_or_dir
        target_name = params[:target]
        configuration = params[:configuration]

        # Get version_number
        project = get_project!(xcodeproj_path_or_dir)
        target = get_target!(project, target_name)
        plist_file = get_plist!(xcodeproj_dir, target, configuration)
        version_number = get_version_number_from_plist!(plist_file)

        # Get from build settings (or project settings) if needed (ex: $(MARKETING_VERSION) is default in Xcode 11)
        if version_number =~ /\$\(([\w\-]+)\)/
          version_number = get_version_number_from_build_settings!(target, $1, configuration) || get_version_number_from_build_settings!(project, $1, configuration)

        # ${MARKETING_VERSION} also works
        elsif version_number =~ /\$\{([\w\-]+)\}/
          version_number = get_version_number_from_build_settings!(target, $1, configuration) || get_version_number_from_build_settings!(project, $1, configuration)
        end

        # Error out if version_number is not set
        if version_number.nil?
          UI.user_error!("Unable to find Xcode build setting: #{$1}")
        end

        # Store the number in the shared hash
        Actions.lane_context[SharedValues::VERSION_NUMBER] = version_number

        # Return the version number because Swift might need this return value
        return version_number
      end

      def self.get_project!(xcodeproj_path_or_dir)
        require 'xcodeproj'
        if File.extname(xcodeproj_path_or_dir) == ".xcodeproj"
          project_path = xcodeproj_path_or_dir
        else
          project_path = Dir.glob("#{xcodeproj_path_or_dir}/*.xcodeproj").first
        end

        if project_path && File.exist?(project_path)
          return Xcodeproj::Project.open(project_path)
        else
          UI.user_error!("Unable to find Xcode project at #{project_path || xcodeproj_path_or_dir}")
        end
      end

      def self.get_target!(project, target_name)
        targets = project.targets

        # Prompt targets if no name
        unless target_name

          # Gets non-test targets
          non_test_targets = targets.reject do |t|
            # Not all targets respond to `test_target_type?`
            t.respond_to?(:test_target_type?) && t.test_target_type?
          end

          # Returns if only one non-test target
          if non_test_targets.count == 1
            return non_test_targets.first
          end

          options = targets.map(&:name)
          target_name = UI.select("What target would you like to use?", options)
        end

        # Find target
        target = targets.find do |t|
          t.name == target_name
        end
        UI.user_error!("Cannot find target named '#{target_name}'") unless target

        target
      end

      def self.get_version_number_from_build_settings!(target, variable, configuration = nil)
        target.build_configurations.each do |config|
          if configuration.nil? || config.name == configuration
            value = config.resolve_build_setting(variable)
            return value if value
          end
        end

        return nil
      end

      def self.get_plist!(folder, target, configuration = nil)
        plist_files = target.resolved_build_setting("INFOPLIST_FILE", true)
        plist_files_count = plist_files.values.compact.uniq.count

        # Get plist file for specified configuration
        # Or: Prompt for configuration if plist has different files in each configurations
        # Else: Get first(only) plist value
        if configuration
          plist_file = plist_files[configuration]
        elsif plist_files_count > 1
          options = plist_files.keys
          selected = UI.select("What build configuration would you like to use?", options)
          plist_file = plist_files[selected]
        elsif plist_files_count > 0
          plist_file = plist_files.values.first
        else
          return nil
        end

        # $(SRCROOT) is the path of where the XcodeProject is
        # We can just set this as empty string since we join with `folder` below
        if plist_file.include?("$(SRCROOT)/")
          plist_file.gsub!("$(SRCROOT)/", "")
        end

        # plist_file can be `Relative` or `Absolute` path.
        # Make to `Absolute` path when plist_file is `Relative` path
        unless File.exist?(plist_file)
          plist_file = File.absolute_path(File.join(folder, plist_file))
        end

        UI.user_error!("Cannot find plist file: #{plist_file}") unless File.exist?(plist_file)

        plist_file
      end

      def self.get_version_number_from_plist!(plist_file)
        return '$(MARKETING_VERSION)' if plist_file.nil?

        plist = Xcodeproj::Plist.read_from_path(plist_file)
        UI.user_error!("Unable to read plist: #{plist_file}") unless plist

        return '${MARKETING_VERSION}' if plist["CFBundleShortVersionString"].nil?
        plist["CFBundleShortVersionString"]
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Get the version number of your project"
      end

      def self.details
        "This action will return the current version number set on your project. It first looks in the plist and then for '$(MARKETING_VERSION)' in the build settings."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                             env_name: "FL_VERSION_NUMBER_PROJECT",
                             description: "Path to the Xcode project to read version number from, or its containing directory, optional. If omitted, or if a directory is passed instead, it will use the first Xcode project found within the given directory, or the project root directory if none is passed",
                             optional: true,
                             verify_block: proc do |value|
                               UI.user_error!("Please pass the path to the project or its containing directory, not the workspace path") if value.end_with?(".xcworkspace")
                               UI.user_error!("Could not find file or directory at path '#{File.expand_path(value)}'") unless File.exist?(value)
                               UI.user_error!("Could not find Xcode project in directory at path '#{File.expand_path(value)}'") if File.extname(value) != ".xcodeproj" && Dir.glob("#{value}/*.xcodeproj").empty?
                             end),
          FastlaneCore::ConfigItem.new(key: :target,
                             env_name: "FL_VERSION_NUMBER_TARGET",
                             description: "Target name, optional. Will be needed if you have more than one non-test target to avoid being prompted to select one",
                             optional: true),
          FastlaneCore::ConfigItem.new(key: :configuration,
                             env_name: "FL_VERSION_NUMBER_CONFIGURATION",
                             description: "Configuration name, optional. Will be needed if you have altered the configurations from the default or your version number depends on the configuration selected",
                             optional: true)
        ]
      end

      def self.output
        [
          ['VERSION_NUMBER', 'The version number']
        ]
      end

      def self.authors
        ["Liquidsoul", "joshdholtz"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.example_code
        [
          'version = get_version_number(xcodeproj: "Project.xcodeproj")',
          'version = get_version_number(
            xcodeproj: "Project.xcodeproj",
            target: "App"
          )'
        ]
      end

      def self.return_type
        :string
      end

      def self.category
        :project
      end
    end
  end
end
