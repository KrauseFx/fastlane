require_relative 'helper'
require 'xcodeproj'
require_relative './configuration/configuration'
require 'fastlane_core/command_executor'

module FastlaneCore
  # Represents an Xcode project
  class Project # rubocop:disable Metrics/ClassLength
    class << self
      # Project discovery
      def detect_projects(config)
        if config[:workspace].to_s.length > 0 && config[:project].to_s.length > 0
          UI.user_error!("You can only pass either a workspace or a project path, not both")
        end

        return if config[:project].to_s.length > 0

        if config[:workspace].to_s.length == 0
          workspace = Dir["./*.xcworkspace"]
          if workspace.count > 1
            puts("Select Workspace: ")
            config[:workspace] = choose(*workspace)
          elsif !workspace.first.nil?
            config[:workspace] = workspace.first
          end
        end

        return if config[:workspace].to_s.length > 0

        if config[:workspace].to_s.length == 0 && config[:project].to_s.length == 0
          project = Dir["./*.xcodeproj"]
          if project.count > 1
            puts("Select Project: ")
            config[:project] = choose(*project)
          elsif !project.first.nil?
            config[:project] = project.first
          end
        end

        if config[:workspace].nil? && config[:project].nil?
          select_project(config)
        end
      end

      def select_project(config)
        loop do
          path = UI.input("Couldn't automatically detect the project file, please provide a path: ")
          if File.directory?(path)
            if path.end_with?(".xcworkspace")
              config[:workspace] = path
              break
            elsif path.end_with?(".xcodeproj")
              config[:project] = path
              break
            else
              UI.error("Path must end with either .xcworkspace or .xcodeproj")
            end
          else
            UI.error("Couldn't find project at path '#{File.expand_path(path)}'")
          end
        end
      end
    end

    # Path to the project/workspace
    attr_accessor :path

    # Is this project a workspace?
    attr_accessor :is_workspace

    # @param options [FastlaneCore::Configuration|Hash] a set of configuration to run xcodebuild to work out build settings
    # @param xcodebuild_list_silent [Boolean] a flag to silent xcodebuild command's output
    # @param xcodebuild_suppress_stderr [Boolean] a flag to supress output to stderr from xcodebuild
    def initialize(options)
      @options = options
      @path = File.expand_path(self.options[:workspace] || self.options[:project])
      @is_workspace = (self.options[:workspace].to_s.length > 0)

      if !path || !File.directory?(path)
        UI.user_error!("Could not find project at path '#{path}'")
      end
    end

    # @return [Hash] a hash object containing project, workspace, scheme, any configuration related to xcodebuild, or etc...
    def options
      # To keep compatibility with actions using this class from outside of `fastlane` gem; i.e. `xcov`,
      # converts `options` to a plain Hash. Otherwise, it might crash when a new option's key is added
      # due to `FastlaneCore::Configuration` to validate valid keys defined.
      @options.kind_of?(FastlaneCore::Configuration) ? @options.values : @options
    end

    def options=(new_value)
      UI.deprecated('Update `options` is not worth doing since it can change behavior of this object entirely. Consider re-creating FastlaneCore::Project.')
      @options = new_value
    end

    def workspace?
      self.is_workspace
    end

    def project_name
      if is_workspace
        return File.basename(options[:workspace], ".xcworkspace")
      else
        return File.basename(options[:project], ".xcodeproj")
      end
    end

    # returns the Xcodeproj::Workspace or nil if it is a project
    def workspace
      return nil unless workspace?

      @workspace ||= Xcodeproj::Workspace.new_from_xcworkspace(path)
      @workspace
    end

    # returns the Xcodeproj::Project or nil if it is a workspace
    def project
      return nil if workspace?
      @project ||= Xcodeproj::Project.open(path)
    end

    # Get all available schemes in an array
    def schemes
      @schemes ||= if workspace?
                     if FastlaneCore::Env.truthy?("FASTLANE_INCLUDE_PODS_PROJECT_SCHEMES")
                       workspace.schemes.keys
                     else
                       workspace.schemes.reject do |k, v|
                         v.include?("Pods/Pods.xcodeproj")
                       end.keys
                     end
                   else
                     Xcodeproj::Project.schemes(path)
                   end
    end

    # Let the user select a scheme
    # Use a scheme containing the preferred_to_include string when multiple schemes were found
    def select_scheme(preferred_to_include: nil)
      if options[:scheme].to_s.length > 0
        # Verify the scheme is available
        unless schemes.include?(options[:scheme].to_s)
          UI.error("Couldn't find specified scheme '#{options[:scheme]}'. Please make sure that the scheme is shared, see https://developer.apple.com/library/content/documentation/IDEs/Conceptual/xcode_guide-continuous_integration/ConfigureBots.html#//apple_ref/doc/uid/TP40013292-CH9-SW3")
          options[:scheme] = nil
        end
      end

      return if options[:scheme].to_s.length > 0

      if schemes.count == 1
        options[:scheme] = schemes.last
      elsif schemes.count > 1
        preferred = nil
        if preferred_to_include
          preferred = schemes.find_all { |a| a.downcase.include?(preferred_to_include.downcase) }
        end

        if preferred_to_include && preferred.count == 1
          options[:scheme] = preferred.last
        elsif automated_scheme_selection? && schemes.include?(project_name)
          UI.important("Using scheme matching project name (#{project_name}).")
          options[:scheme] = project_name
        elsif Helper.ci?
          UI.error("Multiple schemes found but you haven't specified one.")
          UI.error("Since this is a CI, please pass one using the `scheme` option")
          show_scheme_shared_information
          UI.user_error!("Multiple schemes found")
        else
          puts("Select Scheme: ")
          options[:scheme] = choose(*schemes)
        end
      else
        show_scheme_shared_information

        UI.user_error!("No Schemes found")
      end
    end

    def show_scheme_shared_information
      UI.error("Couldn't find any schemes in this project, make sure that the scheme is shared if you are using a workspace")
      UI.error("Open Xcode, click on `Manage Schemes` and check the `Shared` box for the schemes you want to use")
      UI.error("Afterwards make sure to commit the changes into version control")
    end

    # Get all available configurations in an array
    def configurations
      @configurations ||= if workspace?
                            workspace
                              .file_references
                              .map(&:path)
                              .reject { |p| p.include?("Pods/Pods.xcodeproj") }
                              .map do |p|
                                # To maintain backwards compatibility, we
                                # silently ignore non-existent projects from
                                # workspaces.
                                begin
                                  Xcodeproj::Project.open(p).build_configurations
                                rescue
                                  []
                                end
                              end
                              .flatten
                              .compact
                              .map(&:name)
                          else
                            project.build_configurations.map(&:name)
                          end
    end

    # Returns bundle_id and sets the scheme for xcrun
    def default_app_identifier
      default_build_settings(key: "PRODUCT_BUNDLE_IDENTIFIER")
    end

    # Returns app name and sets the scheme for xcrun
    def default_app_name
      if is_workspace
        return default_build_settings(key: "PRODUCT_NAME")
      else
        return app_name
      end
    end

    def app_name
      # WRAPPER_NAME: Example.app
      # WRAPPER_SUFFIX: .app
      name = build_settings(key: "WRAPPER_NAME")

      return name.gsub(build_settings(key: "WRAPPER_SUFFIX"), "") if name
      return "App" # default value
    end

    def dynamic_library?
      (build_settings(key: "PRODUCT_TYPE") == "com.apple.product-type.library.dynamic")
    end

    def static_library?
      (build_settings(key: "PRODUCT_TYPE") == "com.apple.product-type.library.static")
    end

    def library?
      (static_library? || dynamic_library?)
    end

    def framework?
      (build_settings(key: "PRODUCT_TYPE") == "com.apple.product-type.framework")
    end

    def application?
      (build_settings(key: "PRODUCT_TYPE") == "com.apple.product-type.application")
    end

    def ios_library?
      ((static_library? or dynamic_library?) && build_settings(key: "PLATFORM_NAME") == "iphoneos")
    end

    def ios_tvos_app?
      (ios? || tvos?)
    end

    def ios_framework?
      (framework? && build_settings(key: "PLATFORM_NAME") == "iphoneos")
    end

    def ios_app?
      (application? && build_settings(key: "PLATFORM_NAME") == "iphoneos")
    end

    def produces_archive?
      !(framework? || static_library? || dynamic_library?)
    end

    def mac_app?
      (application? && build_settings(key: "PLATFORM_NAME") == "macosx")
    end

    def mac_library?
      ((dynamic_library? or static_library?) && build_settings(key: "PLATFORM_NAME") == "macosx")
    end

    def mac_framework?
      (framework? && build_settings(key: "PLATFORM_NAME") == "macosx")
    end

    def supports_mac_catalyst?
      build_settings(key: "SUPPORTS_MACCATALYST") == "YES" || build_settings(key: "SUPPORTS_UIKITFORMAC") == "YES"
    end

    def command_line_tool?
      (build_settings(key: "PRODUCT_TYPE") == "com.apple.product-type.tool")
    end

    def mac?
      supported_platforms.include?(:macOS)
    end

    def tvos?
      supported_platforms.include?(:tvOS)
    end

    def ios?
      supported_platforms.include?(:iOS)
    end

    def watchos?
      supported_platforms.include?(:watchOS)
    end

    def multiplatform?
      supported_platforms.count > 1
    end

    def supported_platforms
      supported_platforms = build_settings(key: "SUPPORTED_PLATFORMS")
      if supported_platforms.nil?
        UI.important("Could not read the \"SUPPORTED_PLATFORMS\" build setting, assuming that the project supports iOS only.")
        return [:iOS]
      end
      supported_platforms.split.map do |platform|
        case platform
        when "macosx" then :macOS
        when "iphonesimulator", "iphoneos" then :iOS
        when "watchsimulator", "watchos" then :watchOS
        when "appletvsimulator", "appletvos" then :tvOS
        end
      end.uniq.compact
    end

    def xcodebuild_parameters
      proj = []
      proj << "-workspace #{options[:workspace].shellescape}" if options[:workspace]
      proj << "-scheme #{options[:scheme].shellescape}" if options[:scheme]
      proj << "-project #{options[:project].shellescape}" if options[:project]
      proj << "-configuration #{options[:configuration].shellescape}" if options[:configuration]
      proj << "-derivedDataPath #{options[:derived_data_path].shellescape}" if options[:derived_data_path]
      proj << "-xcconfig #{options[:xcconfig].shellescape}" if options[:xcconfig]
      proj << "-scmProvider system" if options[:use_system_scm]

      xcode_at_least_11 = FastlaneCore::Helper.xcode_at_least?('11.0')
      if xcode_at_least_11 && options[:cloned_source_packages_path]
        proj << "-clonedSourcePackagesDirPath #{options[:cloned_source_packages_path].shellescape}"
      end

      if xcode_at_least_11 && options[:skip_package_dependencies_resolution]
        proj << "-disableAutomaticPackageResolution"
      end

      if xcode_at_least_11 && options[:disable_package_automatic_updates]
        proj << "-skipPackageUpdates"
      end

      return proj
    end

    #####################################################
    # @!group Raw Access
    #####################################################

    def build_xcodebuild_showbuildsettings_command
      # We also need to pass the workspace and scheme to this command.
      #
      # The 'clean' portion of this command was a workaround for an xcodebuild bug with Core Data projects.
      # This xcodebuild bug is fixed in Xcode 8.3 so 'clean' it's not necessary anymore
      # See: https://github.com/fastlane/fastlane/pull/5626
      if FastlaneCore::Helper.xcode_at_least?('8.3')
        command = "xcodebuild -showBuildSettings #{xcodebuild_parameters.join(' ')}#{xcodebuild_destination_parameter}"
      else
        command = "xcodebuild clean -showBuildSettings #{xcodebuild_parameters.join(' ')}"
      end
      command
    end

    def build_xcodebuild_resolvepackagedependencies_command
      return nil if options[:skip_package_dependencies_resolution]
      command = "xcodebuild -resolvePackageDependencies #{xcodebuild_parameters.join(' ')}#{xcodebuild_destination_parameter}"
      command
    end

    def xcodebuild_destination_parameter
      # Xcode13+ xcodebuild command 'without destination parameter' generates annoying warnings
      # See: https://github.com/fastlane/fastlane/issues/19579
      destination_parameter = ""
      xcode_at_least_13 = FastlaneCore::Helper.xcode_at_least?("13")
      if xcode_at_least_13 && options[:destination]
        begin
          destination_parameter = " " + "-destination #{options[:destination].shellescape}"
        rescue => ex
          # xcodebuild command can continue without destination parameter, so
          # we really don't care about this exception if something goes wrong with shellescape
          UI.important("Failed to set destination parameter for xcodebuild command: #{ex}")
        end
      end
      destination_parameter
    end

    # Get the build settings for our project
    # e.g. to properly get the DerivedData folder
    # @param [String] The key of which we want the value for (e.g. "PRODUCT_NAME")
    def build_settings(key: nil, optional: true)
      unless @build_settings
        if is_workspace
          if schemes.count == 0
            UI.user_error!("Could not find any schemes for Xcode workspace at path '#{self.path}'. Please make sure that the schemes you want to use are marked as `Shared` from Xcode.")
          end
          options[:scheme] ||= schemes.first
        end

        # SwiftPM support
        if FastlaneCore::Helper.xcode_at_least?('11.0')
          if (command = build_xcodebuild_resolvepackagedependencies_command)
            UI.important("Resolving Swift Package Manager dependencies...")
            FastlaneCore::CommandExecutor.execute(
              command: command,
              print_all: true,
              print_command: true
            )
          else
            UI.important("Skipped Swift Package Manager dependencies resolution.")
          end
        end

        command = build_xcodebuild_showbuildsettings_command

        # Xcode might hang here and retrying fixes the problem, see fastlane#4059
        begin
          timeout = FastlaneCore::Project.xcode_build_settings_timeout
          retries = FastlaneCore::Project.xcode_build_settings_retries
          @build_settings = FastlaneCore::Project.run_command(command, timeout: timeout, retries: retries, print: true)
          if @build_settings.empty?
            UI.error("Could not read build settings. Make sure that the scheme \"#{options[:scheme]}\" is configured for running by going to Product → Scheme → Edit Scheme…, selecting the \"Build\" section, checking the \"Run\" checkbox and closing the scheme window.")
          end
        rescue Timeout::Error
          raise FastlaneCore::Interface::FastlaneDependencyCausedException.new, "xcodebuild -showBuildSettings timed out after #{retries + 1} retries with a base timeout of #{timeout}." \
            " You can override the base timeout value with the environment variable FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT," \
            " and the number of retries with the environment variable FASTLANE_XCODEBUILD_SETTINGS_RETRIES ".red
        end
      end

      begin
        result = @build_settings.split("\n").find do |c|
          sp = c.split(" = ")
          next if sp.length == 0
          sp.first.strip == key
        end
        return result.split(" = ").last
      rescue => ex
        return nil if optional # an optional value, we really don't care if something goes wrong

        UI.error(caller.join("\n\t"))
        UI.error("Could not fetch #{key} from project file: #{ex}")
      end

      nil
    end

    # Returns the build settings and sets the default scheme to the options hash
    def default_build_settings(key: nil, optional: true)
      options[:scheme] ||= schemes.first if is_workspace
      build_settings(key: key, optional: optional)
    end

    # @internal to module
    def self.xcode_build_settings_timeout
      (ENV['FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT'] || 3).to_i
    end

    # @internal to module
    def self.xcode_build_settings_retries
      (ENV['FASTLANE_XCODEBUILD_SETTINGS_RETRIES'] || 3).to_i
    end

    # @internal to module
    # runs the specified command with the specified number of retries, killing each run if it times out.
    # the first run times out after specified timeout elapses, and each successive run times out after
    # a doubling of the previous timeout has elapsed.
    # @raises Timeout::Error if all tries result in a timeout
    # @returns the output of the command
    # Note: - currently affected by https://github.com/fastlane/fastlane/issues/1504
    #       - retry feature added to solve https://github.com/fastlane/fastlane/issues/4059
    def self.run_command(command, timeout: 0, retries: 0, print: true)
      require 'timeout'

      UI.command(command) if print

      result = ''

      total_tries = retries + 1
      try = 1
      try_timeout = timeout
      begin
        Timeout.timeout(try_timeout) do
          # Using Helper.backticks didn't work here. `Timeout` doesn't time out, and the command hangs forever
          result = `#{command}`.to_s
        end
      rescue Timeout::Error
        try_limit_reached = try >= total_tries

        # Try harder on each iteration
        next_timeout = try_timeout * 2

        message = "Command timed out after #{try_timeout} seconds on try #{try} of #{total_tries}"
        message += ", trying again with a #{next_timeout} second timeout..." unless try_limit_reached

        UI.important(message)

        raise if try_limit_reached

        try += 1
        try_timeout = next_timeout
        retry
      end

      return result
    end

    # Array of paths to all project files
    # (might be multiple, because of workspaces)
    def project_paths
      return @_project_paths if @_project_paths
      if self.workspace?
        # Find the xcodeproj file, as the information isn't included in the workspace file
        # We have a reference to the workspace, let's find the xcodeproj file
        # Use Xcodeproj gem here to
        # * parse the contents.xcworkspacedata XML file
        # * handle different types (group:, container: etc.) of file references and their paths
        # for details see https://github.com/CocoaPods/Xcodeproj/blob/e0287156d426ba588c9234bb2a4c824149889860/lib/xcodeproj/workspace/file_reference.rb```

        workspace_dir_path = File.expand_path("..", self.path)
        file_references_paths = workspace.file_references.map { |fr| fr.absolute_path(workspace_dir_path) }
        @_project_paths = file_references_paths.select do |current_match|
          # Xcode workspaces can contain loose files now, so let's filter non-xcodeproj files.
          current_match.end_with?(".xcodeproj")
        end.reject do |current_match|
          # We're not interested in a `Pods` project, as it doesn't contain any relevant information about code signing
          current_match.end_with?("Pods/Pods.xcodeproj")
        end

        return @_project_paths
      else
        # Return the path as an array
        return @_project_paths = [path]
      end
    end

    private

    # If scheme not specified, do we want the scheme
    # matching project name?
    def automated_scheme_selection?
      FastlaneCore::Env.truthy?("AUTOMATED_SCHEME_SELECTION")
    end
  end
end
