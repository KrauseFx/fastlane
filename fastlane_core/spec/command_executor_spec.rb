describe FastlaneCore do
  describe FastlaneCore::CommandExecutor do
    describe "execute" do
      it 'executes a simple command successfully' do
        unless FastlaneCore::Helper.windows?
          expect(Process).to receive(:wait)
        end

        result = FastlaneCore::CommandExecutor.execute(command: 'echo foo')

        expect(result).to eq('foo')
      end

      it 'handles reading which throws a EIO exception', requires_pty: true do
        fake_std_in = [
          "a_filename\n"
        ]
        expect(fake_std_in).to receive(:each).and_yield(*fake_std_in).and_raise(Errno::EIO)

        fake_std_out = 'not_really_std_out'

        expect(fake_std_in).to receive(:close)
        expect(fake_std_out).to receive(:close)

        # Make a fake child process so we have a valid PID and $? is set correctly
        expect(PTY).to receive(:spawn) do |command, &block|
          expect(command).to eq('ls')

          # PTY uses "$?" to get exitcode, which is filled in by Process.wait(),
          # so we have to spawn a real process unless we want to mock methods
          # on nil.
          child_process_id = Process.spawn('echo foo', out: File::NULL)
          expect(Process).to receive(:wait).with(child_process_id)

          block.yield(fake_std_in, fake_std_out, child_process_id)
        end

        result = FastlaneCore::CommandExecutor.execute(command: 'ls')

        # We are implicitly also checking that the error was not rethrown because that would
        # have crashed the test
        expect(result).to eq('a_filename')
      end

      it 'chomps but does not strip output lines', requires_pty: true do
        fake_std_in = [
          "Shopping list:\n",
          "  - Milk\n",
          "\r  - Bread\n",
          "  - Muffins\n"
        ]

        fake_std_out = 'not_really_std_out'

        expect(fake_std_in).to receive(:close)
        expect(fake_std_out).to receive(:close)

        expect(PTY).to receive(:spawn) do |command, &block|
          expect(command).to eq('echo foo')

          # PTY uses "$?" to get exitcode, which is filled in by Process.wait(),
          # so we have to spawn a real process unless we want to mock methods
          # on nil.
          child_process_id = Process.spawn('echo foo', out: File::NULL)
          expect(Process).to receive(:wait).with(child_process_id)

          block.yield(fake_std_in, fake_std_out, child_process_id)
        end

        result = FastlaneCore::CommandExecutor.execute(command: 'echo foo')

        # We are implicitly also checking that the error was not rethrown because that would
        # have crashed the test
        expect(result).to eq(<<-LIST.chomp)
Shopping list:
  - Milk
  - Bread
  - Muffins
        LIST
      end
    end

    describe "which" do
      require 'tempfile'

      it "does not find commands which are not on the PATH" do
        expect(FastlaneCore::CommandExecutor.which('not_a_real_command')).to be_nil
      end

      it "finds commands without extensions which are on the PATH" do
        allow(FastlaneCore::Helper).to receive(:windows?).and_return(false)

        Tempfile.open('foobarbaz') do |f|
          File.chmod(0777, f)

          temp_dir = File.dirname(f)
          temp_cmd = File.basename(f)

          FastlaneSpec::Env.with_env_values('PATH' => temp_dir) do
            expect(FastlaneCore::CommandExecutor.which(temp_cmd)).to eq(f.path)
          end
        end
      end

      it "finds commands without extensions which are on the PATH on Windows", if: FastlaneCore::Helper.windows? do
        Tempfile.open('foobarbaz') do |f|
          File.chmod(0777, f)

          temp_dir = File.dirname(f)
          temp_cmd = File.basename(f)

          FastlaneSpec::Env.with_env_values('PATH' => temp_dir) do
            expect(FastlaneCore::CommandExecutor.which(temp_cmd)).to eq(f.path.gsub('/', '\\'))
          end
        end
      end

      it "finds commands with known extensions which are on the PATH", if: FastlaneCore::Helper.windows? do
        allow(FastlaneCore::Helper).to receive(:windows?).and_return(true)

        Tempfile.open(['foobarbaz', '.exe']) do |f|
          File.chmod(0777, f)

          temp_dir = File.dirname(f)
          temp_cmd = File.basename(f, '.exe')

          FastlaneCore::CommandExecutor.which(temp_cmd)

          FastlaneSpec::Env.with_env_values('PATH' => temp_dir, 'PATHEXT' => '.exe') do
            expect(FastlaneCore::CommandExecutor.which(temp_cmd)).to eq(f.path.gsub('/', '\\'))
          end
        end
      end

      it "does not find commands with unknown extensions which are on the PATH" do
        allow(FastlaneCore::Helper).to receive(:windows?).and_return(true)

        Tempfile.open(['foobarbaz', '.exe']) do |f|
          File.chmod(0777, f)

          temp_dir = File.dirname(f)
          temp_cmd = File.basename(f, '.exe')

          FastlaneSpec::Env.with_env_values('PATH' => temp_dir, 'PATHEXT' => '') do
            expect(FastlaneCore::CommandExecutor.which(temp_cmd)).to be_nil
          end
        end
      end
    end
  end
end
