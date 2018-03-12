module Fastlane
  module Actions
    class GetVersionNumberAction < Action
      require 'shellwords'

      def self.run(params)
        folder = params[:xcodeproj] ? File.join(params[:xcodeproj], '..') : '.'
        scheme = params[:scheme] || ""
        target_name = params[:target]
        configuration = params[:configuration]

        # Get version_number 
        project = get_project!(folder)
        target = get_target!(project, target_name)
        plist_file = get_plist!(folder, target, configuration)
        version_number = get_version_number!(plist_file)

        # Store the number in the shared hash
        Actions.lane_context[SharedValues::VERSION_NUMBER] = version_number

        # Return the version number because Swift might need this return value
        return version_number
      end

      def self.get_project!(folder)
        require 'xcodeproj'
        project_path = Dir.glob("#{folder}/*.xcodeproj").first
        if project_path
          project = Xcodeproj::Project.open(project_path)
        else
          UI.user_error!("Unable to find Xcode project in folder: #{folder}")
        end
      end

      def self.get_target!(project, target_name)
        targets = project.targets

        # Prompt targets if no name
        unless target_name
          options = targets.map(&:name)
          target_name = UI.select("What target would you like to use?", options)
        end

        # Find target
        target = targets.find do |target|
          target.name == target_name
        end
        UI.user_error!("Cannot find target named '#{target_name}'") unless target

        target
      end

      def self.get_plist!(folder, target, configuration = nil)
        plist_files = target.resolved_build_setting("INFOPLIST_FILE")
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
        else
          plist_file = plist_files.values.first
        end

        plist_file = File.absolute_path(File.join(folder, plist_file))
        UI.user_error!("Cannot find plist file: #{plist_file}") unless File.exists?(plist_file)

        plist_file
      end

      def self.get_version_number!(plist_file)
        plist = Xcodeproj::Plist.read_from_path(plist_file)
        UI.user_error!("Unable to read plist: #{plist_file}") unless plist

        plist["CFBundleShortVersionString"]
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Get the version number of your project"
      end

      def self.details
        [
          "This action will return the current version number set on your project.",
          "You first have to set up your Xcode project, if you haven't done it already:",
          "https://developer.apple.com/library/ios/qa/qa1827/_index.html"
        ].join(' ')
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                             env_name: "FL_VERSION_NUMBER_PROJECT",
                             description: "optional, you must specify the path to your main Xcode project if it is not in the project root directory",
                             optional: true,
                             verify_block: proc do |value|
                               UI.user_error!("Please pass the path to the project, not the workspace") if value.end_with?(".xcworkspace")
                               UI.user_error!("Could not find Xcode project at path '#{File.expand_path(value)}'") if !File.exist?(value) and !Helper.test?
                             end),
          FastlaneCore::ConfigItem.new(key: :scheme,
                             env_name: "FL_VERSION_NUMBER_SCHEME",
                             description: "Specify a specific scheme if you have multiple per project, optional. " \
                                          "This parameter is deprecated and will be removed in a future release. " \
                                          "Please use the 'target' parameter instead. The behavior of this parameter " \
                                          "is currently undefined if your scheme name doesn't match your target name",
                             optional: true,
                             deprecated: true),
          FastlaneCore::ConfigItem.new(key: :target,
                             env_name: "FL_VERSION_NUMBER_TARGET",
                             description: "Specify a specific target if you have multiple per project, optional",
                             optional: true),
          FastlaneCore::ConfigItem.new(key: :configuration,
                             env_name: "FL_VERSION_NUMBER_CONFIGURATION",
                             description: "Specify a specific configuration if you have multiple per target, optional",
                             optional: true)
        ]
      end

      def self.output
        [
          ['VERSION_NUMBER', 'The version number']
        ]
      end

      def self.authors
        ["Liquidsoul"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.example_code
        [
          'version = get_version_number(xcodeproj: "Project.xcodeproj")'
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
