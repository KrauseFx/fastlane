require 'fastlane/cli_tools_distributor'

describe Fastlane::CLIToolsDistributor do
  after do
    # Commander owns singleton instance which causes unexpected results in unit testing
    # Reset the singleton on each example runs.
    Commander::Runner.remove_instance_variable(:@singleton) if Commander::Runner.instance_variable_defined?(:@singleton)
  end

  around do |example|
    FastlaneSpec::Env.with_env_values(FASTLANE_DISABLE_ANIMATION: 'true') { example.run }
  end

  describe "command handling" do
    it "runs the lane instead of the tool when there is a conflict" do
      FastlaneSpec::Env.with_ARGV(["sigh"]) do
        require 'fastlane/commands_generator'
        expect(FastlaneCore::FastlaneFolder).to receive(:fastfile_path).and_return("./fastlane/spec/fixtures/fastfiles/FastfileUseToolNameAsLane").at_least(:once)
        expect(Fastlane::CommandsGenerator).to receive(:start).and_return(nil)
        Fastlane::CLIToolsDistributor.take_off
      end
    end

    it "runs a separate tool when the tool is available and the name is not used in a lane" do
      FastlaneSpec::Env.with_ARGV(["gym"]) do
        require 'gym/options'
        require 'gym/commands_generator'
        expect(FastlaneCore::FastlaneFolder).to receive(:fastfile_path).and_return("./fastlane/spec/fixtures/fastfiles/FastfileUseToolNameAsLane").at_least(:once)
        expect(Gym::CommandsGenerator).to receive(:start).and_return(nil)
        Fastlane::CLIToolsDistributor.take_off
      end
    end
  end

  describe "update checking" do
    it "checks for updates when running a lane" do
      FastlaneSpec::Env.with_ARGV(["sigh"]) do
        require 'fastlane/commands_generator'
        expect(FastlaneCore::FastlaneFolder).to receive(:fastfile_path).and_return("./fastlane/spec/fixtures/fastfiles/FastfileUseToolNameAsLane").at_least(:once)
        expect(FastlaneCore::UpdateChecker).to receive(:start_looking_for_update).with('fastlane')
        expect(Fastlane::CommandsGenerator).to receive(:start).and_return(nil)
        expect(FastlaneCore::UpdateChecker).to receive(:show_update_status).with('fastlane', Fastlane::VERSION)
        Fastlane::CLIToolsDistributor.take_off
      end
    end

    it "checks for updates when running a tool" do
      FastlaneSpec::Env.with_ARGV(["gym"]) do
        require 'gym/options'
        require 'gym/commands_generator'
        expect(FastlaneCore::FastlaneFolder).to receive(:fastfile_path).and_return("./fastlane/spec/fixtures/fastfiles/FastfileUseToolNameAsLane").at_least(:once)
        expect(FastlaneCore::UpdateChecker).to receive(:start_looking_for_update).with('fastlane')
        expect(Gym::CommandsGenerator).to receive(:start).and_return(nil)
        expect(FastlaneCore::UpdateChecker).to receive(:show_update_status).with('fastlane', Fastlane::VERSION)
        Fastlane::CLIToolsDistributor.take_off
      end
    end

    it "checks for updates even if the lane has an error" do
      FastlaneSpec::Env.with_ARGV(["beta"]) do
        expect(FastlaneCore::FastlaneFolder).to receive(:fastfile_path).and_return("./fastlane/spec/fixtures/fastfiles/FastfileErrorInError").at_least(:once)
        expect(FastlaneCore::UpdateChecker).to receive(:start_looking_for_update).with('fastlane')
        expect(FastlaneCore::UpdateChecker).to receive(:show_update_status).with('fastlane', Fastlane::VERSION)
        expect_any_instance_of(Commander::Runner).to receive(:abort).with("\n[!] Original error".red).and_raise(SystemExit) # mute console output from `abort`
        expect do
          Fastlane::CLIToolsDistributor.take_off
        end.to raise_error(SystemExit)
      end
    end
  end

  describe "dotenv loading" do
    require 'fastlane/helper/dotenv_helper'

    it "passes --env option into DotenvHelper" do
      FastlaneSpec::Env.with_ARGV(["lanes", "--env", "one"]) do
        expect(Fastlane::Helper::DotenvHelper).to receive(:load_dot_env).with('one')
        Fastlane::CLIToolsDistributor.take_off
      end
    end

    it "strips --env option" do
      FastlaneSpec::Env.with_ARGV(["lanes", "--env", "one,two"]) do
        expect(Fastlane::Helper::DotenvHelper).to receive(:load_dot_env).with('one,two')
        Fastlane::CLIToolsDistributor.take_off
        expect(ARGV).to eq(["lanes"])
      end
    end

    it "ignores --env missing a value" do
      FastlaneSpec::Env.with_ARGV(["lanes", "--env"]) do
        expect(Fastlane::Helper::DotenvHelper).to receive(:load_dot_env).with(nil)
        Fastlane::CLIToolsDistributor.take_off
      end
    end

    it "passes nil when --env is not specified" do
      FastlaneSpec::Env.with_ARGV(["lanes"]) do
        expect(Fastlane::Helper::DotenvHelper).to receive(:load_dot_env).with(nil)
        Fastlane::CLIToolsDistributor.take_off
      end
    end
  end
end
