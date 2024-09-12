describe FastlaneCore do
  describe FastlaneCore::FastlanePty do
    describe "spawn" do
      it 'executes a simple command successfully' do
        @all_lines = []

        exit_status = FastlaneCore::FastlanePty.spawn("echo 'foo'") do |command_stdout, command_stdin, pid|
          command_stdout.each do |line|
            @all_lines << line.chomp
          end
        end
        expect(exit_status).to eq(0)
        expect(@all_lines).to eq(["foo"])
      end

      it 'doesn t return -1 if an exception was raised in the block in PTY.spawn' do
        exception = StandardError.new
        expect {
          exit_status = FastlaneCore::FastlanePty.spawn("echo 'foo'") do |command_stdout, command_stdin, pid|
            raise exception
          end
        }.to raise_error(FastlaneCore::FastlanePtyError) { |error|
          expect(error.exit_status).to eq(0) # command was success but output handling failed
        }
      end

      it 'doesn t return -1 if an exception was raised in the block in Open3.popen2e' do
        expect(FastlaneCore::FastlanePty).to receive(:require).with("pty").and_raise(LoadError)
        allow(FastlaneCore::FastlanePty).to receive(:require).with("open3").and_call_original
        allow(FastlaneCore::FastlanePty).to receive(:open3)

        exception = StandardError.new
        expect {
          exit_status = FastlaneCore::FastlanePty.spawn("echo 'foo'") do |command_stdout, command_stdin, pid|
            raise exception
          end
        }.to raise_error(FastlaneCore::FastlanePtyError) { |error|
          expect(error.exit_status).to eq(0) # command was success but output handling failed
        }
      end

      # could be used to test
      # let(:crasher_path) { File.expand_path("./fastlane_core/spec/crasher/crasher") }

      it 'raises an error if the program crashes through PTY.spawn' do
        status = double("ProcessStatus")
        allow(status).to receive(:exitstatus) { nil }
        allow(status).to receive(:signaled?) { true }

        expect(FastlaneCore::FastlanePty).to receive(:require).with("pty").and_return(nil)
        allow(FastlaneCore::FastlanePty).to receive(:process_status).and_return(status)

        expect {
          exit_status = FastlaneCore::FastlanePty.spawn("a path of a crasher exec") do |command_stdout, command_stdin, pid|
          end
        }.to raise_error(FastlaneCore::FastlanePtyError) { |error|
          expect(error.exit_status).to eq(-1) # command was forced to -1
        }
      end

      it 'raises an error if the program crashes through PTY.popen' do
        stdin = double("stdin")
        allow(stdin).to receive(:close)
        stdout = double("stdout")
        allow(stdout).to receive(:close)

        status = double("ProcessStatus")
        allow(status).to receive(:exitstatus) { nil }
        allow(status).to receive(:signaled?) { true }
        allow(status).to receive(:pid) { 12_345 }

        process = double("process")
        allow(process).to receive(:value) { status }

        expect(FastlaneCore::FastlanePty).to receive(:require).with("pty").and_raise(LoadError)
        allow(FastlaneCore::FastlanePty).to receive(:require).with("open3").and_return(nil)
        allow(Open3).to receive(:popen2e).and_yield(stdin, stdout, process)

        expect {
          exit_status = FastlaneCore::FastlanePty.spawn("a path of a crasher exec") do |command_stdout, command_stdin, pid|
          end
        }.to raise_error(FastlaneCore::FastlanePtyError) { |error|
          expect(error.exit_status).to eq(-1) # command was forced to -1
        }
      end
    end
  end
end
