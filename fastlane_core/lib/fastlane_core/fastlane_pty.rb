# Source: Mix of https://github.com/fastlane/fastlane/pull/7202/files,
# https://github.com/fastlane/fastlane/pull/11384#issuecomment-356084518 and
# https://github.com/DragonBox/u3d/blob/59e471ad78ac00cb629f479dbe386c5ad2dc5075/lib/u3d_core/command_runner.rb#L88-L96

class StandardError
  def exit_status
    return -1
  end
end

module FastlaneCore
  class FastlanePtyError < StandardError
    attr_reader :exit_status

    def initialize(e, exit_status)
      super(e)
      set_backtrace(e.backtrace) if e
      @exit_status = exit_status
    end
  end

  class FastlanePty
    def self.spawn(command)
      require 'pty'
      PTY.spawn(command) do |command_stdout, command_stdin, pid|
        begin
          yield(command_stdout, command_stdin, pid)
        rescue Errno::EIO
          # Exception ignored intentionally.
          # https://stackoverflow.com/questions/10238298/ruby-on-linux-pty-goes-away-without-eof-raises-errnoeio
          # This is expected on some linux systems, that indicates that the subcommand finished
          # and we kept trying to read, ignore it
        ensure
          begin
            Process.wait(pid)
          rescue Errno::ECHILD, PTY::ChildExited
            # The process might have exited.
          end
        end
      end
      $?.exitstatus
    rescue LoadError
      require 'open3'
      Open3.popen2e(command) do |command_stdin, command_stdout, p| # NOTE: the inversion
        yield(command_stdout, command_stdin, p.value.pid)

        command_stdin.close
        command_stdout.close
        p.value.exitstatus
      end
    rescue StandardError => e
      # Wrapping any error in FastlanePtyError to allow
      # callers to see and use $?.exitstatus that
      # would usually get returned
      raise FastlanePtyError.new(e, $?.exitstatus)
    end
  end
end
