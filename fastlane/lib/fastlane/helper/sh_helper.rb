require "open3"

module Fastlane
  module Actions
    # Execute a shell command
    # This method will output the string and execute it
    # Just an alias for sh_no_action
    # When running this in tests, it will return the actual command instead of executing it
    # @param log [Boolean] should fastlane print out the executed command
    # @param error_callback [Block] a callback invoked with the command output if there is a non-zero exit status
    def self.sh(*command, log: true, error_callback: nil, &b)
      sh_control_output(*command, print_command: log, print_command_output: log, error_callback: error_callback, &b)
    end

    def self.sh_no_action(*command, log: true, error_callback: nil, &b)
      sh_control_output(*command, print_command: log, print_command_output: log, error_callback: error_callback, &b)
    end

    # @param command The command to be executed (variadic)
    # @param print_command [Boolean] Should we print the command that's being executed
    # @param print_command_output [Boolean] Should we print the command output during execution
    # @param error_callback [Block] A block that's called if the command exits with a non-zero status
    # @yield [status, result, cmd] The return status of the command, all output from the command and an equivalent shell command
    # @yieldparam [Process::Status] status A Process::Status indicating the status of the completed command
    # @yieldparam [String] result The complete output to stdout and stderr of the completed command
    # @yieldparam [String] cmd A shell command equivalent to the arguments passed
    # rubocop: disable Metrics/PerceivedComplexity
    def self.sh_control_output(*command, print_command: true, print_command_output: true, error_callback: nil)
      print_command = print_command_output = true if $troubleshoot
      # Set the encoding first, the user might have set it wrong
      previous_encoding = [Encoding.default_external, Encoding.default_internal]
      Encoding.default_external = Encoding::UTF_8
      Encoding.default_internal = Encoding::UTF_8

      # Workaround to support previous Fastlane syntax.
      # This has some limitations. For example, it requires the caller to shell escape
      # everything because of usages like ["ls -la", "/tmp"] instead of ["ls", "-la", "/tmp"].
      command = [command.first.join(" ")] if command.length == 1 && command.first.kind_of?(Array)

      shell_command = shell_command_from_args(*command)
      UI.command(shell_command) if print_command

      result = ''
      exit_status = nil
      if FastlaneCore::Helper.sh_enabled?
        # The argument list is passed directly to Open3.popen2e, which
        # handles the variadic argument list in the same way as Kernel#spawn.
        # (http://ruby-doc.org/core-2.4.2/Kernel.html#method-i-spawn) or
        # Process.spawn (http://ruby-doc.org/core-2.4.2/Process.html#method-c-spawn).
        #
        # sh "ls -la /Applications/Xcode\ 7.3.1.app"
        # sh "ls", "-la", "/Applications/Xcode 7.3.1.app"
        # sh({ "FOO" => "Hello" }, "echo $FOO")
        Open3.popen2e(*command) do |stdin, io, thread|
          io.sync = true
          io.each do |line|
            UI.command_output(line.strip) if print_command_output
            result << line
          end
          exit_status = thread.value
        end

        # Checking Process::Status#exitstatus instead of #success? makes for more
        # testable code. (Tests mock exitstatus only.) This is also consistent
        # with previous implementations of sh and... probably portable to all
        # relevant platforms.
        if exit_status.exitstatus != 0
          message = if print_command
                      "Exit status of command '#{shell_command}' was #{exit_status.exitstatus} instead of 0."
                    else
                      "Shell command exited with exit status #{exit_status.exitstatus} instead of 0."
                    end
          message += "\n#{result[-500..-1]}" if print_command_output

          if error_callback || block_given?
            UI.error(message)
            # block notified below, on success or failure
            error_callback && error_callback.call(result)
          else
            UI.shell_error!(message)
          end
        end
      else
        result << shell_command # only for the tests
      end

      if block_given?
        # Avoid yielding nil in tests. $? will be meaningless, but calls to
        # it will not crash. There is no Process::Status.new. The alternative
        # is to move this inside the sh_enabled? check and not yield in tests.
        return yield(exit_status || $?, result, shell_command)
      end
      result
    rescue => ex
      raise ex
    ensure
      Encoding.default_external = previous_encoding.first
      Encoding.default_internal = previous_encoding.last
    end
    # rubocop: enable Metrics/PerceivedComplexity

    # Used to produce a shell command string from a list of arguments that may
    # be passed to methods such as Kernel#system, Kernel#spawn and Open3.popen2e
    # in order to print the command to the terminal. The same *args are passed
    # directly to a system call (Open3.popen2e). This interpretation is not
    # used when executing a command.
    #
    # @param args Any number of arguments used to construct a command
    # @raise [ArgumentError] If no arguments passed
    # @return [String] A shell command representing the arguments passed in
    def self.shell_command_from_args(*args)
      raise ArgumentError, "sh requires at least one argument" unless args.count > 0

      command = ""

      # Optional initial environment Hash
      if args.first.kind_of?(Hash)
        command = args.shift.map { |k, v| "#{k}=#{v.shellescape}" }.join(" ") + " "
      end

      # Support [ "/usr/local/bin/foo", "foo" ], "-x", ...
      if args.first.kind_of?(Array)
        command += args.shift.first.shellescape + " " + args.shelljoin
        command.chomp!(" ")
      elsif args.count == 1 && args.first.kind_of?(String)
        command += args.first
      else
        command += args.shelljoin
      end

      command
    end
  end
end
