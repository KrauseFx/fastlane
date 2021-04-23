require 'shellwords'
require 'fileutils'
require 'credentials_manager/account_manager'

require_relative 'features'
require_relative 'helper'
require_relative 'fastlane_pty'

module FastlaneCore
  # The TransporterInputError occurs when you passed wrong inputs to the {Deliver::ItunesTransporter}
  class TransporterInputError < StandardError
  end

  # The TransporterTransferError occurs when some error happens
  # while uploading or downloading something from/to iTC
  class TransporterTransferError < StandardError
  end

  # Used internally
  class TransporterRequiresApplicationSpecificPasswordError < StandardError
  end

  # Base class for executing the iTMSTransporter
  class TransporterExecutor
    ERROR_REGEX = />\s*ERROR:\s+(.+)/
    WARNING_REGEX = />\s*WARN:\s+(.+)/
    OUTPUT_REGEX = />\s+(.+)/
    RETURN_VALUE_REGEX = />\sDBG-X:\sReturning\s+(\d+)/

    SKIP_ERRORS = ["ERROR: An exception has occurred: Scheduling automatic restart in 1 minute"]

    private_constant :ERROR_REGEX, :WARNING_REGEX, :OUTPUT_REGEX, :RETURN_VALUE_REGEX, :SKIP_ERRORS

    def execute(command, hide_output)
      if Helper.test?
        yield(nil) if block_given?
        return command
      end

      @errors = []
      @warnings = []
      @all_lines = []

      if hide_output
        # Show a one time message instead
        UI.success("Waiting for App Store Connect transporter to be finished.")
        UI.success("iTunes Transporter progress... this might take a few minutes...")
      end

      begin
        exit_status = FastlaneCore::FastlanePty.spawn(command) do |command_stdout, command_stdin, pid|
          command_stdout.each do |line|
            @all_lines << line
            parse_line(line, hide_output) # this is where the parsing happens
          end
        end
      rescue => ex
        # FastlanePty adds exit_status on to StandardError so every error will have a status code
        exit_status = ex.exit_status
        @errors << ex.to_s
      end

      unless exit_status.zero?
        @errors << "The call to the iTMSTransporter completed with a non-zero exit status: #{exit_status}. This indicates a failure."
      end

      if @warnings.count > 0
        UI.important(@warnings.join("\n"))
      end

      if @errors.join("").include?("app-specific")
        raise TransporterRequiresApplicationSpecificPasswordError
      end

      if @errors.count > 0 && @all_lines.count > 0
        # Print out the last 15 lines, this is key for non-verbose mode
        @all_lines.last(15).each do |line|
          UI.important("[iTMSTransporter] #{line}")
        end
        UI.message("iTunes Transporter output above ^")
        UI.error(@errors.join("\n"))
      end

      # this is to handle GitHub issue #1896, which occurs when an
      #  iTMSTransporter file transfer fails; iTMSTransporter will log an error
      #  but will then retry; if that retry is successful, we will see the error
      #  logged, but since the status code is zero, we want to return success
      if @errors.count > 0 && exit_status.zero?
        UI.important("Although errors occurred during execution of iTMSTransporter, it returned success status.")
      end

      yield(@all_lines) if block_given?
      return exit_status.zero?
    end

    def displayable_errors
      @errors.map { |error| "[Transporter Error Output]: #{error}" }.join("\n").gsub!(/"/, "")
    end

    private

    def parse_line(line, hide_output)
      # Taken from https://github.com/sshaw/itunes_store_transporter/blob/master/lib/itunes/store/transporter/output_parser.rb

      output_done = false

      re = Regexp.union(SKIP_ERRORS)
      if line.match(re)
        # Those lines will not be handled like errors or warnings

      elsif line =~ ERROR_REGEX
        @errors << $1

        # Check if it's a login error
        if $1.include?("Your Apple ID or password was entered incorrectly") ||
           $1.include?("This Apple ID has been locked for security reasons")

          unless Helper.test?
            CredentialsManager::AccountManager.new(user: @user).invalid_credentials
            UI.error("Please run this tool again to apply the new password")
          end
        end

        output_done = true
      elsif line =~ WARNING_REGEX
        @warnings << $1
        UI.important("[Transporter Warning Output]: #{$1}")
        output_done = true
      end

      if line =~ RETURN_VALUE_REGEX
        if $1.to_i != 0
          UI.error("Transporter transfer failed.")
          UI.important(@warnings.join("\n"))
          UI.error(@errors.join("\n"))
          UI.crash!("Return status of iTunes Transporter was #{$1}: #{@errors.join('\n')}")
        else
          UI.success("iTunes Transporter successfully finished its job")
        end
      end

      if !hide_output && line =~ OUTPUT_REGEX
        # General logging for debug purposes
        unless output_done
          UI.verbose("[Transporter]: #{$1}")
        end
      end
    end

    def additional_upload_parameters
      # As Apple recommends in Transporter User Guide we shouldn't specify the -t transport parameter
      # and instead allow Transporter to use automatic transport discovery
      # to determine the best transport mode for packages.
      # It became crucial after WWDC 2020 as it leaded to "Broken pipe (Write failed)" exception
      # More information https://github.com/fastlane/fastlane/issues/16749
      env_deliver_additional_params = ENV["DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS"]
      if env_deliver_additional_params.to_s.strip.empty?
        return nil
      end

      deliver_additional_params = env_deliver_additional_params.to_s.strip
      if deliver_additional_params.include?("-t ")
        UI.important("Apple recommends you don’t specify the -t transport and instead allow Transporter to use automatic transport discovery to determine the best transport mode for your packages. For more information, please read Apple's Transporter User Guide 2.1: https://help.apple.com/itc/transporteruserguide/#/apdATD1E1288-D1E1A1303-D1E1288A1126")
      end
      return deliver_additional_params
    end
  end

  # Generates commands and executes the iTMSTransporter through the shell script it provides by the same name
  class ShellScriptTransporterExecutor < TransporterExecutor
    def build_upload_command(username, password, source = "/tmp", provider_short_name = "", jwt = nil)
      use_jwt = !jwt.to_s.empty?
      [
        '"' + Helper.transporter_path + '"',
        "-m upload",
        ("-u #{username.shellescape}" unless use_jwt),
        ("-p #{shell_escaped_password(password)}" unless use_jwt),
        ("-jwt #{jwt}" if use_jwt),
        "-f \"#{source}\"",
        additional_upload_parameters, # that's here, because the user might overwrite the -t option
        "-k 100000",
        ("-WONoPause true" if Helper.windows?), # Windows only: process instantly returns instead of waiting for key press
        ("-itc_provider #{provider_short_name}" if jwt.nil? && !provider_short_name.to_s.empty?)
      ].compact.join(' ')
    end

    def build_download_command(username, password, apple_id, destination = "/tmp", provider_short_name = "", jwt = nil)
      use_jwt = !jwt.to_s.empty?
      [
        '"' + Helper.transporter_path + '"',
        "-m lookupMetadata",
        ("-u #{username.shellescape}" unless use_jwt),
        ("-p #{shell_escaped_password(password)}" unless use_jwt),
        ("-jwt #{jwt}" if use_jwt),
        "-apple_id #{apple_id}",
        "-destination '#{destination}'",
        ("-itc_provider #{provider_short_name}" if jwt.nil? && !provider_short_name.to_s.empty?)
      ].compact.join(' ')
    end

    def build_provider_ids_command(username, password, jwt = nil)
      use_jwt = !jwt.to_s.empty?
      [
        '"' + Helper.transporter_path + '"',
        '-m provider',
        ("-u \"#{username.shellescape}\"" unless use_jwt),
        ("-p #{shell_escaped_password(password)}" unless use_jwt),
        ("-jwt #{jwt}" if use_jwt)
      ].compact.join(' ')
    end

    def handle_error(password)
      # rubocop:disable Style/CaseEquality
      # rubocop:disable Style/YodaCondition
      unless /^[0-9a-zA-Z\.\$\_\-]*$/ === password
        UI.error([
          "Password contains special characters, which may not be handled properly by iTMSTransporter.",
          "If you experience problems uploading to App Store Connect, please consider changing your password to something with only alphanumeric characters."
        ].join(' '))
      end
      # rubocop:enable Style/CaseEquality
      # rubocop:enable Style/YodaCondition

      UI.error("Could not download/upload from App Store Connect! It's probably related to your password or your internet connection.")
    end

    private

    def shell_escaped_password(password)
      password = password.shellescape
      unless Helper.windows?
        # because the shell handles passwords with single-quotes incorrectly, use `gsub` to replace `shellescape`'d single-quotes of this form:
        #    \'
        # with a sequence that wraps the escaped single-quote in double-quotes:
        #    '"\'"'
        # this allows us to properly handle passwords with single-quotes in them
        # background: https://stackoverflow.com/questions/1250079/how-to-escape-single-quotes-within-single-quoted-strings/1250098#1250098
        password = password.gsub("\\'") do
          # we use the 'do' version of gsub, because two-param version interprets the replace text as a pattern and does the wrong thing
          "'\"\\'\"'"
        end

        # wrap the fully-escaped password in single quotes, since the transporter expects a escaped password string (which must be single-quoted for the shell's benefit)
        password = "'" + password + "'"
      end
      return password
    end
  end

  # Generates commands and executes the iTMSTransporter by invoking its Java app directly, to avoid the crazy parameter
  # escaping problems in its accompanying shell script.
  class JavaTransporterExecutor < TransporterExecutor
    def build_upload_command(username, password, source = "/tmp", provider_short_name = "", jwt = nil)
      use_jwt = !jwt.to_s.empty?
      if !Helper.user_defined_itms_path? && Helper.mac? && Helper.xcode_at_least?(11)
        [
          ("ITMS_TRANSPORTER_PASSWORD=#{password.shellescape}" unless use_jwt),
          'xcrun iTMSTransporter',
          '-m upload',
          ("-u #{username.shellescape}" unless use_jwt),
          ("-p @env:ITMS_TRANSPORTER_PASSWORD" unless use_jwt),
          ("-jwt #{jwt}" if use_jwt),
          "-f #{source.shellescape}",
          additional_upload_parameters, # that's here, because the user might overwrite the -t option
          '-k 100000',
          ("-itc_provider #{provider_short_name}" if jwt.nil? && !provider_short_name.to_s.empty?),
          '2>&1' # cause stderr to be written to stdout
        ].compact.join(' ') # compact gets rid of the possibly nil ENV value
      else
        [
          Helper.transporter_java_executable_path.shellescape,
          "-Djava.ext.dirs=#{Helper.transporter_java_ext_dir.shellescape}",
          '-XX:NewSize=2m',
          '-Xms32m',
          '-Xmx1024m',
          '-Xms1024m',
          '-Djava.awt.headless=true',
          '-Dsun.net.http.retryPost=false',
          java_code_option,
          '-m upload',
          ("-u #{username.shellescape}" unless use_jwt),
          ("-p #{password.shellescape}" unless use_jwt),
          ("-jwt #{jwt}" if use_jwt),
          "-f #{source.shellescape}",
          additional_upload_parameters, # that's here, because the user might overwrite the -t option
          '-k 100000',
          ("-itc_provider #{provider_short_name}" if jwt.nil? && !provider_short_name.to_s.empty?),
          '2>&1' # cause stderr to be written to stdout
        ].compact.join(' ') # compact gets rid of the possibly nil ENV value
      end
    end

    def build_download_command(username, password, apple_id, destination = "/tmp", provider_short_name = "", jwt = nil)
      use_jwt = !jwt.to_s.empty?
      if !Helper.user_defined_itms_path? && Helper.mac? && Helper.xcode_at_least?(11)
        [
          ("ITMS_TRANSPORTER_PASSWORD=#{password.shellescape}" unless use_jwt),
          'xcrun iTMSTransporter',
          '-m lookupMetadata',
          ("-u #{username.shellescape}" unless use_jwt),
          ("-p @env:ITMS_TRANSPORTER_PASSWORD" unless use_jwt),
          ("-jwt #{jwt}" if use_jwt),
          "-apple_id #{apple_id.shellescape}",
          "-destination #{destination.shellescape}",
          ("-itc_provider #{provider_short_name}" if jwt.nil? && !provider_short_name.to_s.empty?),
          '2>&1' # cause stderr to be written to stdout
        ].compact.join(' ')
      else
        [
          Helper.transporter_java_executable_path.shellescape,
          "-Djava.ext.dirs=#{Helper.transporter_java_ext_dir.shellescape}",
          '-XX:NewSize=2m',
          '-Xms32m',
          '-Xmx1024m',
          '-Xms1024m',
          '-Djava.awt.headless=true',
          '-Dsun.net.http.retryPost=false',
          java_code_option,
          '-m lookupMetadata',
          ("-u #{username.shellescape}" unless use_jwt),
          ("-p #{password.shellescape}" unless use_jwt),
          ("-jwt #{jwt}" if use_jwt),
          "-apple_id #{apple_id.shellescape}",
          "-destination #{destination.shellescape}",
          ("-itc_provider #{provider_short_name}" if jwt.nil? && !provider_short_name.to_s.empty?),
          '2>&1' # cause stderr to be written to stdout
        ].compact.join(' ')
      end
    end

    def build_provider_ids_command(username, password, jwt = nil)
      use_jwt = !jwt.to_s.empty?
      if !Helper.user_defined_itms_path? && Helper.mac? && Helper.xcode_at_least?(11)
        [
          ("ITMS_TRANSPORTER_PASSWORD=#{password.shellescape}" unless use_jwt),
          'xcrun iTMSTransporter',
          '-m provider',
          ("-u #{username.shellescape}" unless use_jwt),
          ("-p @env:ITMS_TRANSPORTER_PASSWORD" unless use_jwt),
          ("-jwt #{jwt}" if use_jwt),
          '2>&1' # cause stderr to be written to stdout
        ].compact.join(' ')
      else
        [
          Helper.transporter_java_executable_path.shellescape,
          "-Djava.ext.dirs=#{Helper.transporter_java_ext_dir.shellescape}",
          '-XX:NewSize=2m',
          '-Xms32m',
          '-Xmx1024m',
          '-Xms1024m',
          '-Djava.awt.headless=true',
          '-Dsun.net.http.retryPost=false',
          java_code_option,
          '-m provider',
          ("-u #{username.shellescape}" unless use_jwt),
          ("-p #{password.shellescape}" unless use_jwt),
          ("-jwt #{jwt}" if use_jwt),
          '2>&1' # cause stderr to be written to stdout
        ].compact.join(' ')
      end
    end

    def java_code_option
      if Helper.mac? && Helper.xcode_at_least?(9)
        return "-jar #{Helper.transporter_java_jar_path.shellescape}"
      else
        return "-classpath #{Helper.transporter_java_jar_path.shellescape} com.apple.transporter.Application"
      end
    end

    def handle_error(password)
      unless File.exist?(Helper.transporter_java_jar_path)
        UI.error("The iTMSTransporter Java app was not found at '#{Helper.transporter_java_jar_path}'.")
        UI.error("If you're using Xcode 6, please select the shell script executor by setting the environment variable "\
          "FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT=1")
      end
    end

    def execute(command, hide_output)
      # The Java command needs to be run starting in a working directory in the iTMSTransporter
      # file area. The shell script takes care of changing directories over to there, but we'll
      # handle it manually here for this strategy.
      FileUtils.cd(Helper.itms_path) do
        return super(command, hide_output)
      end
    end
  end

  class ItunesTransporter
    # Matches a line in the provider table: "12  Initech Systems Inc     LG89CQY559"
    PROVIDER_REGEX = /^\d+\s{2,}.+\s{2,}[^\s]+$/
    TWO_STEP_HOST_PREFIX = "deliver.appspecific"

    # This will be called from the Deliverfile, and disables the logging of the transporter output
    def self.hide_transporter_output
      @hide_transporter_output = !FastlaneCore::Globals.verbose?
    end

    def self.hide_transporter_output?
      @hide_transporter_output
    end

    # Returns a new instance of the iTunesTransporter.
    # If no username or password given, it will be taken from
    # the #{CredentialsManager::AccountManager}
    # @param use_shell_script if true, forces use of the iTMSTransporter shell script.
    #                         if false, allows a direct call to the iTMSTransporter Java app (preferred).
    #                         see: https://github.com/fastlane/fastlane/pull/4003
    # @param provider_short_name The provider short name to be given to the iTMSTransporter to identify the
    #                            correct team for this work. The provider short name is usually your Developer
    #                            Portal team ID, but in certain cases it is different!
    #                            see: https://github.com/fastlane/fastlane/issues/1524#issuecomment-196370628
    #                            for more information about how to use the iTMSTransporter to list your provider
    #                            short names
    def initialize(user = nil, password = nil, use_shell_script = false, provider_short_name = nil, jwt = nil)
      # Xcode 6.x doesn't have the same iTMSTransporter Java setup as later Xcode versions, so
      # we can't default to using the newer direct Java invocation strategy for those versions.
      use_shell_script ||= Helper.is_mac? && Helper.xcode_version.start_with?('6.')
      use_shell_script ||= Helper.windows?
      use_shell_script ||= Feature.enabled?('FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT')

      if jwt.to_s.empty?
        @user = user
        @password = password || load_password_for_transporter
      end

      @jwt = jwt

      @transporter_executor = use_shell_script ? ShellScriptTransporterExecutor.new : JavaTransporterExecutor.new
      @provider_short_name = provider_short_name
    end

    # Downloads the latest version of the app metadata package from iTC.
    # @param app_id [Integer] The unique App ID
    # @param dir [String] the path in which the package file should be stored
    # @return (Bool) True if everything worked fine
    # @raise [Deliver::TransporterTransferError] when something went wrong
    #   when transferring
    def download(app_id, dir = nil)
      dir ||= "/tmp"

      password_placeholder = @jwt.nil? ? 'YourPassword' : nil
      jwt_placeholder = @jwt.nil? ? nil : 'YourJWT'

      UI.message("Going to download app metadata from App Store Connect")
      command = @transporter_executor.build_download_command(@user, @password, app_id, dir, @provider_short_name, @jwt)
      UI.verbose(@transporter_executor.build_download_command(@user, password_placeholder, app_id, dir, @provider_short_name, jwt_placeholder))

      begin
        result = @transporter_executor.execute(command, ItunesTransporter.hide_transporter_output?)
      rescue TransporterRequiresApplicationSpecificPasswordError => ex
        handle_two_step_failure(ex)
        return download(app_id, dir)
      end

      return result if Helper.test?

      itmsp_path = File.join(dir, "#{app_id}.itmsp")
      successful = result && File.directory?(itmsp_path)

      if successful
        UI.success("✅ Successfully downloaded the latest package from App Store Connect to #{itmsp_path}")
      else
        handle_error(@password)
      end

      successful
    end

    # Uploads the modified package back to App Store Connect
    # @param app_id [Integer] The unique App ID
    # @param dir [String] the path in which the package file is located
    # @param package_path [String] the path to the package file (used instead of app_id and dir)
    # @return (Bool) True if everything worked fine
    # @raise [Deliver::TransporterTransferError] when something went wrong
    #   when transferring
    def upload(app_id = nil, dir = nil, package_path: nil)
      raise "app_id and dir are required or package_path is required" if (app_id.nil? || dir.nil?) && package_path.nil?
      actual_dir = package_path || File.join(dir, "#{app_id}.itmsp")

      UI.message("Going to upload updated app to App Store Connect")
      UI.success("This might take a few minutes. Please don't interrupt the script.")

      password_placeholder = @jwt.nil? ? 'YourPassword' : nil
      jwt_placeholder = @jwt.nil? ? nil : 'YourJWT'

      command = @transporter_executor.build_upload_command(@user, @password, actual_dir, @provider_short_name, @jwt)
      UI.verbose(@transporter_executor.build_upload_command(@user, password_placeholder, actual_dir, @provider_short_name, jwt_placeholder))

      begin
        result = @transporter_executor.execute(command, ItunesTransporter.hide_transporter_output?)
      rescue TransporterRequiresApplicationSpecificPasswordError => ex
        handle_two_step_failure(ex)
        return upload(app_id, dir, package_path: package_path)
      end

      if result
        UI.header("Successfully uploaded package to App Store Connect. It might take a few minutes until it's visible online.")

        FileUtils.rm_rf(actual_dir) unless Helper.test? # we don't need the package any more, since the upload was successful
      else
        handle_error(@password)
      end

      return result
    end

    def displayable_errors
      @transporter_executor.displayable_errors
    end

    def provider_ids
      password_placeholder = @jwt.nil? ? 'YourPassword' : nil
      jwt_placeholder = @jwt.nil? ? nil : 'YourJWT'

      command = @transporter_executor.build_provider_ids_command(@user, @password, @jwt)
      UI.verbose(@transporter_executor.build_provider_ids_command(@user, password_placeholder, jwt_placeholder))

      lines = []
      begin
        result = @transporter_executor.execute(command, ItunesTransporter.hide_transporter_output?) { |xs| lines = xs }
        return result if Helper.test?
      rescue TransporterRequiresApplicationSpecificPasswordError => ex
        handle_two_step_failure(ex)
        return provider_ids
      end

      lines.map { |line| provider_pair(line) }.compact.to_h
    end

    private

    TWO_FACTOR_ENV_VARIABLE = "FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD"

    # Returns the password to be used with the transporter
    def load_password_for_transporter
      # 3 different sources for the password
      #   1) ENV variable for application specific password
      if ENV[TWO_FACTOR_ENV_VARIABLE].to_s.length > 0
        UI.message("Fetching password for transporter from environment variable named `#{TWO_FACTOR_ENV_VARIABLE}`")
        return ENV[TWO_FACTOR_ENV_VARIABLE]
      end
      #   2) TWO_STEP_HOST_PREFIX from keychain
      account_manager = CredentialsManager::AccountManager.new(user: @user,
                                                             prefix: TWO_STEP_HOST_PREFIX,
                                                               note: "application-specific")
      password = account_manager.password(ask_if_missing: false)
      return password if password.to_s.length > 0
      #   3) standard iTC password
      account_manager = CredentialsManager::AccountManager.new(user: @user)
      return account_manager.password(ask_if_missing: true)
    end

    # Tells the user how to get an application specific password
    def handle_two_step_failure(ex)
      if ENV[TWO_FACTOR_ENV_VARIABLE].to_s.length > 0
        # Password provided, however we already used it
        UI.error("")
        UI.error("Application specific password you provided using")
        UI.error("environment variable #{TWO_FACTOR_ENV_VARIABLE}")
        UI.error("is invalid, please make sure it's correct")
        UI.error("")
        UI.user_error!("Invalid application specific password provided")
      end

      a = CredentialsManager::AccountManager.new(user: @user,
                                               prefix: TWO_STEP_HOST_PREFIX,
                                                 note: "application-specific")
      if a.password(ask_if_missing: false).to_s.length > 0
        # user already entered one.. delete the old one
        UI.error("Application specific password seems wrong")
        UI.error("Please make sure to follow the instructions")
        a.remove_from_keychain
      end
      UI.error("")
      UI.error("Your account has 2 step verification enabled")
      UI.error("Please go to https://appleid.apple.com/account/manage")
      UI.error("and generate an application specific password for")
      UI.error("the iTunes Transporter, which is used to upload builds")
      UI.error("")
      UI.error("To set the application specific password on a CI machine using")
      UI.error("an environment variable, you can set the")
      UI.error("#{TWO_FACTOR_ENV_VARIABLE} variable")
      @password = a.password(ask_if_missing: true) # to ask the user for the missing value

      return true
    end

    def handle_error(password)
      @transporter_executor.handle_error(password)
    end

    def provider_pair(line)
      line = line.strip
      return nil unless line =~ PROVIDER_REGEX
      line.split(/\s{2,}/).drop(1)
    end
  end
end
