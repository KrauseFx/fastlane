require 'logger'
require 'colored'
require 'tty-spinner'
require 'pathname'

require_relative 'fastlane_folder'
require_relative 'ui/ui'
require_relative 'env'

module FastlaneCore
  module Helper
    # fastlane
    #

    def self.fastlane_enabled?
      # This is called from the root context on the first start
      !FastlaneCore::FastlaneFolder.path.nil?
    end

    # Checks if fastlane is enabled for this project and returns the folder where the configuration lives
    def self.fastlane_enabled_folder_path
      fastlane_enabled? ? FastlaneCore::FastlaneFolder.path : '.'
    end

    # fastlane installation method
    #

    # @return [boolean] true if executing with bundler (like 'bundle exec fastlane [action]')
    def self.bundler?
      # Bundler environment variable
      ['BUNDLE_BIN_PATH', 'BUNDLE_GEMFILE'].each do |current|
        return true if ENV.key?(current)
      end
      return false
    end

    # Do we run from a bundled fastlane, which contains Ruby and OpenSSL?
    # Usually this means the fastlane directory is ~/.fastlane/bin/
    # We set this value via the environment variable `FASTLANE_SELF_CONTAINED`
    def self.contained_fastlane?
      ENV["FASTLANE_SELF_CONTAINED"].to_s == "true" && !self.homebrew?
    end

    # returns true if fastlane was installed from the Fabric Mac app
    def self.mac_app?
      ENV["FASTLANE_SELF_CONTAINED"].to_s == "false"
    end

    # returns true if fastlane was installed via Homebrew
    def self.homebrew?
      ENV["FASTLANE_INSTALLED_VIA_HOMEBREW"].to_s == "true"
    end

    # returns true if fastlane was installed via RubyGems
    def self.rubygems?
      !self.bundler? && !self.contained_fastlane? && !self.homebrew? && !self.mac_app?
    end

    # environment
    #

    # @return true if the currently running program is a unit test
    def self.test?
      Object.const_defined?("SpecHelper")
    end

    # @return true if it is enabled to execute external commands
    def self.sh_enabled?
      !self.test? || ENV["FORCE_SH_DURING_TESTS"]
    end

    # @return [boolean] true if building in a known CI environment
    def self.ci?
      return true if self.is_circle_ci?

      # Check for Jenkins, Travis CI, ... environment variables
      ['JENKINS_HOME', 'JENKINS_URL', 'TRAVIS', 'CI', 'APPCENTER_BUILD_ID', 'TEAMCITY_VERSION', 'GO_PIPELINE_NAME', 'bamboo_buildKey', 'GITLAB_CI', 'XCS', 'TF_BUILD', 'GITHUB_ACTION', 'GITHUB_ACTIONS', 'BITRISE_IO', 'BUDDY', 'CODEBUILD_BUILD_ARN'].each do |current|
        return true if FastlaneCore::Env.truthy?(current)
      end
      return false
    end

    def self.is_circle_ci?
      return ENV.key?('CIRCLECI')
    end

    # @return [boolean] true if environment variable CODEBUILD_BUILD_ARN is set
    def self.is_codebuild?
      return ENV.key?('CODEBUILD_BUILD_ARN')
    end

    def self.operating_system
      return "macOS" if RUBY_PLATFORM.downcase.include?("darwin")
      return "Windows" if RUBY_PLATFORM.downcase.include?("mswin")
      return "Linux" if RUBY_PLATFORM.downcase.include?("linux")
      return "Unknown"
    end

    def self.windows?
      # taken from: https://stackoverflow.com/a/171011/1945875
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def self.linux?
      (/linux/ =~ RUBY_PLATFORM) != nil
    end

    # Is the currently running computer a Mac?
    def self.mac?
      (/darwin/ =~ RUBY_PLATFORM) != nil
    end

    # @return architecture type
    def self.architecture_type
      return "" unless self.mac?
      return `arch`.split("\n").first
    end

    # Do we want to disable the colored output?
    def self.colors_disabled?
      FastlaneCore::Env.truthy?("FASTLANE_DISABLE_COLORS") || ENV.key?("NO_COLOR")
    end

    # Does the user use the Mac stock terminal
    def self.mac_stock_terminal?
      FastlaneCore::Env.truthy?("TERM_PROGRAM_VERSION")
    end

    # Logs base directory
    def self.buildlog_path
      return ENV["FL_BUILDLOG_PATH"] || "~/Library/Logs"
    end

    # Xcode
    #

    # @return the full path to the Xcode developer tools of the currently
    #  running system
    def self.xcode_path
      return "" unless self.mac?

      if self.xcode_server?
        # Xcode server always creates a link here
        xcode_server_xcode_path = "/Library/Developer/XcodeServer/CurrentXcodeSymlink/Contents/Developer"
        UI.verbose("We're running as XcodeServer, setting path to #{xcode_server_xcode_path}")
        return xcode_server_xcode_path
      end

      return `xcode-select -p`.delete("\n") + "/"
    end

    def self.xcode_server?
      # XCS is set by Xcode Server
      return ENV["XCS"].to_i == 1
    end

    # @return The version of the currently used Xcode installation (e.g. "7.0")
    def self.xcode_version
      return nil unless self.mac?
      return @xcode_version if @xcode_version && @developer_dir == ENV['DEVELOPER_DIR']

      xcodebuild_path = "#{xcode_path}/usr/bin/xcodebuild"

      xcode_build_installed = File.exist?(xcodebuild_path)
      unless xcode_build_installed
        UI.verbose("Couldn't find xcodebuild at #{xcodebuild_path}, check that it exists")
        return nil
      end

      begin
        output = `DEVELOPER_DIR='' "#{xcodebuild_path}" -version`
        @xcode_version = output.split("\n").first.split(' ')[1]
        @developer_dir = ENV['DEVELOPER_DIR']
      rescue => ex
        UI.error(ex)
        UI.user_error!("Error detecting currently used Xcode installation, please ensure that you have Xcode installed and set it using `sudo xcode-select -s [path]`")
      end
      @xcode_version
    end

    # @return true if installed Xcode version is 'greater than or equal to' the input parameter version
    def self.xcode_at_least?(version)
      installed_xcode_version = xcode_version
      UI.user_error!("Unable to locate Xcode. Please make sure to have Xcode installed on your machine") if installed_xcode_version.nil?
      Gem::Version.new(installed_xcode_version) >= Gem::Version.new(version)
    end

    # Swift
    #

    # @return Swift version
    def self.swift_version
      if system("which swift > /dev/null 2>&1")
        output = `swift --version 2> /dev/null`
        return output.split("\n").first.match(/version ([0-9.]+)/).captures.first
      end
      return nil
    end

    # iTMSTransporter
    #

    def self.transporter_java_executable_path
      return File.join(self.transporter_java_path, 'bin', 'java')
    end

    def self.transporter_java_ext_dir
      return File.join(self.transporter_java_path, 'lib', 'ext')
    end

    def self.transporter_java_jar_path
      return File.join(self.itms_path, 'lib', 'itmstransporter-launcher.jar')
    end

    def self.transporter_user_dir
      return File.join(self.itms_path, 'bin')
    end

    def self.transporter_java_path
      return File.join(self.itms_path, 'java')
    end

    # @return the full path to the iTMSTransporter executable
    def self.transporter_path
      return File.join(self.itms_path, 'bin', 'iTMSTransporter') unless Helper.windows?
      return File.join(self.itms_path, 'iTMSTransporter')
    end

    def self.user_defined_itms_path?
      return FastlaneCore::Env.truthy?("FASTLANE_ITUNES_TRANSPORTER_PATH")
    end

    def self.user_defined_itms_path
      return ENV["FASTLANE_ITUNES_TRANSPORTER_PATH"] if self.user_defined_itms_path?
    end

    # @return the full path to the iTMSTransporter executable
    def self.itms_path
      return self.user_defined_itms_path if FastlaneCore::Env.truthy?("FASTLANE_ITUNES_TRANSPORTER_PATH")

      if self.mac?
        # First check for manually install iTMSTransporter
        user_local_itms_path = "/usr/local/itms"
        return user_local_itms_path if File.exist?(user_local_itms_path)

        # Then check for iTMSTransporter in the Xcode path
        [
          "../Applications/Application Loader.app/Contents/MacOS/itms",
          "../Applications/Application Loader.app/Contents/itms",
          "../SharedFrameworks/ContentDeliveryServices.framework/Versions/A/itms" # For Xcode 11
        ].each do |path|
          result = File.expand_path(File.join(self.xcode_path, path))
          return result if File.exist?(result)
        end
        UI.user_error!("Could not find transporter at #{self.xcode_path}. Please make sure you set the correct path to your Xcode installation.")
      elsif self.windows?
        [
          "C:/Program Files (x86)/itms"
        ].each do |path|
          return path if File.exist?(path)
        end
        UI.user_error!("Could not find transporter at usual locations. Please use environment variable `FASTLANE_ITUNES_TRANSPORTER_PATH` to specify your installation path.")
      else
        # not Mac or Windows
        return ''
      end
    end

    # keychain
    #

    def self.keychain_path(keychain_name)
      # Existing code expects that a keychain name will be expanded into a default path to Library/Keychains
      # in the user's home directory. However, this will not allow the user to pass an absolute path
      # for the keychain value
      #
      # So, if the passed value can't be resolved as a file in Library/Keychains, just use it as-is
      # as the keychain path.
      #
      # We need to expand each path because File.exist? won't handle directories including ~ properly
      #
      # We also try to append `-db` at the end of the file path, as with Sierra the default Keychain name
      # has changed for some users: https://github.com/fastlane/fastlane/issues/5649

      # Remove the ".keychain" at the end of the keychain name
      name = keychain_name.sub(/\.keychain$/, "")

      possible_locations = [
        File.join(Dir.home, 'Library', 'Keychains', name),
        name
      ].map { |path| File.expand_path(path) }

      # Transforms ["thing"] to ["thing-db", "thing.keychain-db", "thing", "thing.keychain"]
      keychain_paths = []
      possible_locations.each do |location|
        keychain_paths << "#{location}-db"
        keychain_paths << "#{location}.keychain-db"
        keychain_paths << location
        keychain_paths << "#{location}.keychain"
      end

      keychain_path = keychain_paths.find { |path| File.file?(path) }
      UI.user_error!("Could not locate the provided keychain. Tried:\n\t#{keychain_paths.join("\n\t")}") unless keychain_path
      keychain_path
    end

    # helper methods
    #

    # Runs a given command using backticks (`)
    # and prints them out using the UI.command method
    def self.backticks(command, print: true)
      UI.command(command) if print
      result = `#{command}`
      UI.command_output(result) if print
      return result
    end

    # removes ANSI colors from string
    def self.strip_ansi_colors(str)
      str.gsub(/\e\[([;\d]+)?m/, '')
    end

    # Zips directory
    def self.zip_directory(path, output_path, contents_only: false, overwrite: false, print: true)
      if overwrite
        overwrite_command = " && rm -f '#{output_path}'"
      else
        overwrite_command = ""
      end

      if contents_only
        command = "cd '#{path}'#{overwrite_command} && zip -r '#{output_path}' *"
      else
        containing_path = File.expand_path("..", path)
        contents_path = File.basename(path)

        command = "cd '#{containing_path}'#{overwrite_command} && zip -r '#{output_path}' '#{contents_path}'"
      end

      UI.command(command) unless print
      Helper.backticks(command, print: print)
    end

    # Executes the provided block after adjusting the ENV to have the
    # provided keys and values set as defined in hash. After the block
    # completes, restores the ENV to its previous state.
    def self.with_env_values(hash, &block)
      old_vals = ENV.select { |k, v| hash.include?(k) }
      hash.each do |k, v|
        ENV[k] = hash[k]
      end
      yield
    ensure
      hash.each do |k, v|
        ENV.delete(k) unless old_vals.include?(k)
        ENV[k] = old_vals[k]
      end
    end

    # loading indicator
    #

    def self.should_show_loading_indicator?
      return false if FastlaneCore::Env.truthy?("FASTLANE_DISABLE_ANIMATION")
      return false if Helper.ci?
      return true
    end

    # Show/Hide loading indicator
    def self.show_loading_indicator(text = nil)
      if self.should_show_loading_indicator?
        # we set the default here, instead of at the parameters
        # as we don't want to `UI.message` a rocket that's just there for the loading indicator
        text ||= "🚀"
        @require_fastlane_spinner = TTY::Spinner.new("[:spinner] #{text} ", format: :dots)
        @require_fastlane_spinner.auto_spin
      else
        UI.message(text) if text
      end
    end

    def self.hide_loading_indicator
      if self.should_show_loading_indicator? && @require_fastlane_spinner
        @require_fastlane_spinner.success
      end
    end

    # files
    #

    # checks if a given path is an executable file
    def self.executable?(cmd_path)
      if !cmd_path || File.directory?(cmd_path)
        return false
      end

      return File.exist?(get_executable_path(cmd_path))
    end

    # returns the path of the executable with the correct extension on Windows
    def self.get_executable_path(cmd_path)
      cmd_path = localize_file_path(cmd_path)

      if self.windows?
        # PATHEXT contains the list of file extensions that Windows considers executable, semicolon separated.
        # e.g. ".COM;.EXE;.BAT;.CMD"
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : []

        # no executable files on Windows, so existing is enough there
        # also check if command + ext is present
        exts.each do |ext|
          executable_path = "#{cmd_path}#{ext.downcase}"
          return executable_path if File.exist?(executable_path)
        end
      end

      return cmd_path
    end

    # returns the path with the platform-specific path separator (`/` on UNIX, `\` on Windows)
    def self.localize_file_path(path)
      # change `/` to `\` on Windows
      return self.windows? ? path.gsub('/', '\\') : path
    end

    # checks if given file is a valid json file
    # base taken from: http://stackoverflow.com/a/26235831/1945875
    def self.json_file?(filename)
      return false unless File.exist?(filename)
      begin
        JSON.parse(File.read(filename))
        return true
      rescue JSON::ParserError
        return false
      end
    end

    # deprecated
    #

    # Use Helper.test?, Helper.ci?, Helper.mac? or Helper.windows? instead (legacy calls)
    def self.is_test?
      self.test?
    end

    def self.is_ci?
      ci?
    end

    def self.is_mac?
      self.mac?
    end

    def self.is_windows?
      self.windows?
    end

    # <b>DEPRECATED:</b> Use the `ROOT` constant from the appropriate tool module instead
    # e.g. File.join(Sigh::ROOT, 'lib', 'assets', 'resign.sh')
    #
    # Path to the installed gem to load resources (e.g. resign.sh)
    def self.gem_path(gem_name)
      UI.deprecated('`Helper.gem_path` is deprecated. Use the `ROOT` constant from the appropriate tool module instead.')

      if !Helper.test? && Gem::Specification.find_all_by_name(gem_name).any?
        return Gem::Specification.find_by_name(gem_name).gem_dir
      else
        return './'
      end
    end

    # This method is deprecated, use the `UI` class
    # https://docs.fastlane.tools/advanced/#user-input-and-output
    def self.log
      UI.deprecated("Helper.log is deprecated. Use `UI` class instead")
      UI.current.log
    end

    def self.ask_password(message: "Passphrase: ", confirm: nil, confirmation_message: "Type passphrase again: ")
      raise "This code should only run in interactive mode" unless UI.interactive?

      loop do
        password = UI.password(message)
        if confirm
          password2 = UI.password(confirmation_message)
          if password == password2
            return password
          end
        else
          return password
        end
        UI.error("Your entries do not match. Please try again")
      end
    end
  end
end
