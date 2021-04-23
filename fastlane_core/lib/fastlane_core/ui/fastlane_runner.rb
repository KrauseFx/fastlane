unless Object.const_defined?("Faraday")
  # We create these empty error classes if we didn't require Faraday
  # so that we can use it in the rescue block below even if we didn't
  # require Faraday or didn't use it
  module Faraday
    class Error < StandardError; end

    class ClientError < Error; end

    class SSLError < ClientError; end

    class ConnectionFailed < ClientError; end
  end
end

unless Object.const_defined?("OpenSSL")
  module OpenSSL
    module SSL
      class SSLError < StandardError; end
    end
  end
end

require 'commander'

require_relative '../env'
require_relative '../globals'
require_relative '../analytics/action_completion_context'
require_relative '../analytics/action_launch_context'
require_relative 'errors'

module Commander
  # This class override the run method with our custom stack trace handling
  # In particular we want to distinguish between user_error! and crash! (one with, one without stack trace)
  class Runner
    # Code taken from https://github.com/commander-rb/commander/blob/master/lib/commander/runner.rb#L50

    attr_accessor :collector

    def run!
      require_program(:version, :description)
      trap('INT') { abort(program(:int_message)) } if program(:int_message)
      trap('INT') { program(:int_block).call } if program(:int_block)
      global_option('-h', '--help', 'Display help documentation') do
        args = @args - %w(-h --help)
        command(:help).run(*args)
        return
      end
      global_option('-v', '--version', 'Display version information') do
        say(version)
        return
      end
      parse_global_options
      remove_global_options(options, @args)

      xcode_outdated = false
      begin
        unless FastlaneCore::Helper.xcode_at_least?(Fastlane::MINIMUM_XCODE_RELEASE)
          xcode_outdated = true
        end
      rescue
        # We don't care about exceptions here
        # We'll land here if the user doesn't have Xcode at all for example
        # which is fine for someone who uses fastlane just for Android project
        # What we *do* care about is when someone links an old version of Xcode
      end

      begin
        if xcode_outdated
          # We have to raise that error within this `begin` block to show a nice user error without a stack trace
          FastlaneCore::UI.user_error!("fastlane requires a minimum version of Xcode #{Fastlane::MINIMUM_XCODE_RELEASE}, please upgrade and make sure to use `sudo xcode-select -s /Applications/Xcode.app`")
        end

        is_swift = FastlaneCore::FastlaneFolder.swift?
        fastlane_client_language = is_swift ? :swift : :ruby
        action_launch_context = FastlaneCore::ActionLaunchContext.context_for_action_name(@program[:name], fastlane_client_language: fastlane_client_language, args: ARGV)
        FastlaneCore.session.action_launched(launch_context: action_launch_context)

        return_value = run_active_command

        action_completed(@program[:name], status: FastlaneCore::ActionCompletionStatus::SUCCESS)
        return return_value
      rescue Commander::Runner::InvalidCommandError => e
        # calling `abort` makes it likely that tests stop without failing, so
        # we'll disable that during tests.
        if FastlaneCore::Helper.test?
          raise e
        else
          abort("#{e}. Use --help for more information")
        end
      rescue Interrupt => e
        # We catch it so that the stack trace is hidden by default when using ctrl + c
        if FastlaneCore::Globals.verbose?
          raise e
        else
          action_completed(@program[:name], status: FastlaneCore::ActionCompletionStatus::INTERRUPTED, exception: e)
          abort("\nCancelled... use --verbose to show the stack trace")
        end
      rescue \
        OptionParser::InvalidOption,
        OptionParser::InvalidArgument,
        OptionParser::MissingArgument => e
        # calling `abort` makes it likely that tests stop without failing, so
        # we'll disable that during tests.
        if FastlaneCore::Helper.test?
          raise e
        else
          if self.active_command.name == "help" && @default_command == :help # need to access directly via @
            # This is a special case, for example for pilot
            # when the user runs `fastlane pilot -u user@google.com`
            # This would be confusing, as the user probably wanted to use `pilot list`
            # or some other command. Because `-u` isn't available for the `pilot --help`
            # command it would show this very confusing error message otherwise
            abort("Please ensure to use one of the available commands (#{self.commands.keys.join(', ')})".red)
          else
            # This would print something like
            #
            #   invalid option: -u
            #
            abort(e.to_s)
          end
        end
      rescue FastlaneCore::Interface::FastlaneCommonException => e # these are exceptions that we don't count as crashes
        display_user_error!(e, e.to_s)
      rescue FastlaneCore::Interface::FastlaneError => e # user_error!
        rescue_fastlane_error(e)
      rescue Errno::ENOENT => e
        rescue_file_error(e)
      rescue Faraday::SSLError, OpenSSL::SSL::SSLError => e # SSL issues are very common
        handle_ssl_error!(e)
      rescue Faraday::ConnectionFailed => e
        rescue_connection_failed_error(e)
      rescue => e # high chance this is actually FastlaneCore::Interface::FastlaneCrash, but can be anything else
        rescue_unknown_error(e)
      ensure
        FastlaneCore.session.finalize_session
      end
    end

    def action_completed(action_name, status: nil, exception: nil)
      # https://github.com/fastlane/fastlane/issues/11913
      # if exception.nil? || exception.fastlane_should_report_metrics?
      #   action_completion_context = FastlaneCore::ActionCompletionContext.context_for_action_name(action_name, args: ARGV, status: status)
      #   FastlaneCore.session.action_completed(completion_context: action_completion_context)
      # end
    end

    def rescue_file_error(e)
      # We're also printing the new-lines, as otherwise the message is not very visible in-between the error and the stack trace
      puts("")
      FastlaneCore::UI.important("Error accessing file, this might be due to fastlane's directory handling")
      FastlaneCore::UI.important("Check out https://docs.fastlane.tools/advanced/#directory-behavior for more details")
      puts("")
      raise e
    end

    def rescue_connection_failed_error(e)
      if e.message.include?('Connection reset by peer - SSL_connect')
        handle_tls_error!(e)
      else
        handle_unknown_error!(e)
      end
    end

    def rescue_unknown_error(e)
      action_completed(@program[:name], status: FastlaneCore::ActionCompletionStatus::FAILED, exception: e)

      handle_unknown_error!(e)
    end

    def rescue_fastlane_error(e)
      action_completed(@program[:name], status: FastlaneCore::ActionCompletionStatus::USER_ERROR, exception: e)

      show_github_issues(e.message) if e.show_github_issues
      display_user_error!(e, e.message)
    end

    def handle_tls_error!(e)
      # Apple has upgraded its App Store Connect servers to require TLS 1.2, but
      # system Ruby 2.0 does not support it. We want to suggest that users upgrade
      # their Ruby version
      suggest_ruby_reinstall(e)
      display_user_error!(e, e.to_s)
    end

    def handle_ssl_error!(e)
      # SSL errors are very common when the Ruby or OpenSSL installation is somehow broken
      # We want to show a nice error message to the user here
      # We have over 20 GitHub issues just for this one error:
      #   https://github.com/fastlane/fastlane/search?q=errno%3D0+state%3DSSLv3+read+server&type=Issues
      suggest_ruby_reinstall(e)
      display_user_error!(e, e.to_s)
    end

    def suggest_ruby_reinstall(e)
      ui = FastlaneCore::UI
      ui.error("-----------------------------------------------------------------------")
      ui.error(e.to_s)
      ui.error("")
      ui.error("SSL errors can be caused by various components on your local machine.")
      if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.1')
        ui.error("Apple has recently changed their servers to require TLS 1.2, which may")
        ui.error("not be available to your system installed Ruby (#{RUBY_VERSION})")
      end
      ui.error("")
      ui.error("The best solution is to use the self-contained fastlane version.")
      ui.error("Which ships with a bundled OpenSSL,ruby and all gems - so you don't depend on system libraries")
      ui.error(" - Use Homebrew")
      ui.error("    - update brew with `brew update`")
      ui.error("    - install fastlane using:")
      ui.error("      - `brew install fastlane`")
      ui.error(" - Use One-Click-Installer:")
      ui.error("    - download fastlane at https://download.fastlane.tools")
      ui.error("    - extract the archive and double click the `install`")
      ui.error("-----------------------------------------------------------")
      ui.error("for more details on ways to install fastlane please refer the documentation:")
      ui.error("-----------------------------------------------------------")
      ui.error("        🚀       https://docs.fastlane.tools          🚀   ")
      ui.error("-----------------------------------------------------------")
      ui.error("")
      ui.error("You can also install a new version of Ruby")
      ui.error("")
      ui.error("- Make sure OpenSSL is installed with Homebrew: `brew update && brew upgrade openssl`")
      ui.error("- If you use system Ruby:")
      ui.error("  - Run `brew update && brew install ruby`")
      ui.error("- If you use rbenv with ruby-build:")
      ui.error("  - Run `brew update && brew upgrade ruby-build && rbenv install 2.3.1`")
      ui.error("  - Run `rbenv global 2.3.1` to make it the new global default Ruby version")
      ui.error("- If you use rvm:")
      ui.error("  - First run `rvm osx-ssl-certs update all`")
      ui.error("  - Then run `rvm reinstall ruby-2.3.1 --with-openssl-dir=/usr/local`")
      ui.error("")
      ui.error("If that doesn't fix your issue, please google for the following error message:")
      ui.error("  '#{e}'")
      ui.error("-----------------------------------------------------------------------")
    end

    def handle_unknown_error!(e)
      # Some spaceship exception classes implement #preferred_error_info in order to share error info
      # that we'd rather display instead of crashing with a stack trace. However, fastlane_core and
      # spaceship can not know about each other's classes! To make this information passing work, we
      # use a bit of Ruby duck-typing to check whether the unknown exception type implements the right
      # method. If so, we'll present any returned error info in the manner of a user_error!
      error_info = e.respond_to?(:preferred_error_info) ? e.preferred_error_info : nil
      should_show_github_issues = e.respond_to?(:show_github_issues) ? e.show_github_issues : true

      if error_info
        error_info = error_info.join("\n\t") if error_info.kind_of?(Array)

        show_github_issues(error_info) if should_show_github_issues

        display_user_error!(e, error_info)
      else
        # Pass the error instead of a message so that the inspector can do extra work to simplify the query
        show_github_issues(e) if should_show_github_issues

        # From https://stackoverflow.com/a/4789702/445598
        # We do this to make the actual error message red and therefore more visible
        reraise_formatted!(e, e.message)
      end
    end

    def display_user_error!(e, message)
      if FastlaneCore::Globals.verbose?
        # with stack trace
        reraise_formatted!(e, message)
      else
        # without stack trace
        action_completed(@program[:name], status: FastlaneCore::ActionCompletionStatus::USER_ERROR, exception: e)
        abort("\n[!] #{message}".red)
      end
    end

    def reraise_formatted!(e, message)
      backtrace = FastlaneCore::Env.truthy?("FASTLANE_HIDE_BACKTRACE") ? [] : e.backtrace
      raise e, "[!] #{message}".red, backtrace
    end

    def show_github_issues(message_or_error)
      return if FastlaneCore::Env.truthy?("FASTLANE_HIDE_GITHUB_ISSUES")
      return if FastlaneCore::Helper.test?

      require 'gh_inspector'
      require 'fastlane_core/ui/github_issue_inspector_reporter'

      inspector = GhInspector::Inspector.new("fastlane", "fastlane", verbose: FastlaneCore::Globals.verbose?)
      delegate = Fastlane::InspectorReporter.new
      if message_or_error.kind_of?(String)
        inspector.search_query(message_or_error, delegate)
      else
        inspector.search_exception(message_or_error, delegate)
      end
    rescue => ex
      FastlaneCore::UI.error("Error finding relevant GitHub issues: #{ex}") if FastlaneCore::Globals.verbose?
    end
  end
end
