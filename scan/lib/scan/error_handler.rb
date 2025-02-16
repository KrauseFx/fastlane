require_relative 'module'

module Scan
  # This classes methods are called when something goes wrong in the building process
  class ErrorHandler
    class << self
      # @param [String] The output of the errored build
      # This method should raise an exception in any case, as the return code indicated a failed build
      def handle_build_error(output, log_path)
        # The order of the handling below is important

        instruction = 'See the log'
        location = Scan.config[:suppress_xcode_output] ? "here: '#{log_path}'" : "above"
        details = "#{instruction} #{location}."

        case output
        when /US\-ASCII/
          print("Your shell environment is not correctly configured")
          print("Instead of UTF-8 your shell uses US-ASCII")
          print("Please add the following to your '~/.bashrc':")
          print("")
          print("       export LANG=en_US.UTF-8")
          print("       export LANGUAGE=en_US.UTF-8")
          print("       export LC_ALL=en_US.UTF-8")
          print("")
          print("You'll have to restart your shell session after updating the file.")
          print("If you are using zshell or another shell, make sure to edit the correct bash file.")
          print("For more information visit this stackoverflow answer:")
          print("https://stackoverflow.com/a/17031697/445598")
        when /Testing failed on/
          # This is important because xcbeautify and raw output will print:
          # Testing failed on 'iPhone 13 Pro Max'
          # when multiple devices are use.
          # xcpretty hides this output so its not an issue with xcpretty.
          # We need to catch "Testing failed on" before "Test failed"
          # so that an error isn't raised.
          # Raising an error prevents trainer from processing the xcresult
          return
        when /Executed/, /Failing tests:/
          # this is *really* important:
          # we don't want to raise an exception here
          # as we handle this in runner.rb at a later point
          # after parsing the actual test results
          # ------------------------------------------------
          # For the "Failing tests:" case, this covers Xcode
          # 10 parallel testing failure, which doesn't
          # print out the "Executed" line that would show
          # test summary (number of tests passed, etc.).
          # Instead, it just prints "Failing tests:"
          # followed by a list of tests that failed.
          return
        when /Testing failed/, /\*\* TEST BUILD FAILED \*\*/
          UI.build_failure!("Error building the application. #{details}")
        end
        UI.build_failure!("Error building/testing the application. #{details}")
      end

      private

      # Just to make things easier
      def print(text)
        UI.error(text)
      end
    end
  end
end
