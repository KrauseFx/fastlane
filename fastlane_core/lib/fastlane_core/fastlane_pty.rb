# Source: Mix of https://github.com/fastlane/fastlane/pull/7202/files, 
# https://github.com/fastlane/fastlane/pull/11384#issuecomment-356084518 and 
# https://github.com/DragonBox/u3d/blob/59e471ad78ac00cb629f479dbe386c5ad2dc5075/lib/u3d_core/command_runner.rb#L88-L96 
module FastlaneCore
  class FastlanePty
    def self.spawn(*command, &block)
      begin
        require 'pty'
        PTY.spawn(command) do |stdout, stdin, pid|
          block.call(stdin, stdout, pid)
        end
      rescue LoadError
        require 'open3'
        Open3.popen2e(command) do |r, w, p|
          yield w, r, p.value.pid # note the inversion

          r.close
          w.close
          p.value.exitstatus
        end
      end
    end
  end
end