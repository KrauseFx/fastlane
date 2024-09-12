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
    attr_reader :exit_status, :process_status
    def initialize(e, exit_status, process_status)
      super(e)
      set_backtrace(e.backtrace) if e
      @exit_status = exit_status
      @process_status = process_status
    end
  end

  class FastlanePty
    def self.spawn(command, &block)
      spawn_with_pty(command, &block)
    rescue LoadError
      spawn_with_popen(command, &block)
    end

    def self.spawn_with_pty(command, &block)
      require 'pty'
      PTY.spawn(command) do |command_stdout, command_stdin, pid|
        begin
          yield(command_stdout, command_stdin, pid)
        rescue Errno::EIO
          # Exception ignored intentionally.
          # https://stackoverflow.com/questions/10238298/ruby-on-linux-pty-goes-away-without-eof-raises-errnoeio
          # This is expected on some linux systems, that indicates that the subcommand finished
          # and we kept trying to read, ignore it
        rescue => _
          block_failed = true
          raise
        ensure
          # When an exception is thrown from the block command, we let the ecosystem a bit of time to complete
          # nicely, flush buffers and terminate processes so that we don't abruptly stop the process
          # and the process status ends in -1. This is far from a perfect solution.
          sleep(0.05) if block_failed
          command_stdin.close
          command_stdout.close
          begin
            Process.wait(pid)
          rescue Errno::ECHILD, PTY::ChildExited
            # The process might have exited.
          end
        end
      end
      status = self.process_status
      raise StandardError, "Process crashed" if status.signaled?
      status.exitstatus
    rescue StandardError => e
      # Wrapping any error in FastlanePtyError to allow callers to see and use
      # $?.exitstatus that would usually get returned
      status = self.process_status
      raise FastlanePtyError.new(e, status.exitstatus || e.exit_status, status)
    end

    def self.spawn_with_popen(command, &block)
      status = nil
      require 'open3'
      Open3.popen2e(command) do |command_stdin, command_stdout, p| # note the inversion
        status = p.value
        yield(command_stdout, command_stdin, status.pid)
        command_stdin.close
        command_stdout.close
        raise StandardError, "Process crashed" if status.signaled?
        status.exitstatus
      end
    rescue StandardError => e
      # Wrapping any error in FastlanePtyError to allow callers to see and use
      # $?.exitstatus that would usually get returned
      raise FastlanePtyError.new(e, status.exitstatus || e.exit_status, status)
    end

    # to ease mocking
    def self.process_status
      $?
    end
  end
end
