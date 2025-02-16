require 'sigh/commands_generator'
require 'sigh/repair'

describe Sigh::CommandsGenerator do
  describe "resign option handling" do
    let(:resign) do
      resign = Sigh::Resign.new
      expect(Sigh::Resign).to receive(:new).and_return(resign)
      resign
    end

    def expect_resign_run(options)
      expect(resign).to receive(:run) do |actual_options, actual_args|
        expect(actual_options).to match_commander_options(options)
        expect(actual_args).to eq([])
      end
    end

    it "signing_identity short flag is not shadowed by cert_id short flag from tool options" do
      stub_commander_runner_args(['resign', '-i', 'abcd'])

      options = Commander::Command::Options.new
      options.signing_identity = 'abcd'

      expect_resign_run(options)

      Sigh::CommandsGenerator.start
    end

    it "provisioning_profile short flag is not shadowed by platform short flag from tool options" do
      stub_commander_runner_args(['resign', '-p', 'abcd'])

      options = Commander::Command::Options.new
      options.provisioning_profile = [['abcd']]

      expect_resign_run(options)

      Sigh::CommandsGenerator.start
    end
  end

  describe "renew option handling" do
    it "cert_id short flag from tool options can be used" do
      # leaving out the command name defaults to 'renew'
      stub_commander_runner_args(['-i', 'abcd'])

      # start takes no params, but we want to expect the call and prevent
      # actual execution of the method
      expect(Sigh::Manager).to receive(:start)

      Sigh::CommandsGenerator.start

      expect(Sigh.config[:cert_id]).to eq('abcd')
    end

    it "platform short flag is not shadowed by cert_id short flag from tool options" do
      # leaving out the command name defaults to 'renew'
      stub_commander_runner_args(['-p', 'tvos'])

      # start takes no params, but we want to expect the call and prevent
      # actual execution of the method
      expect(Sigh::Manager).to receive(:start)

      Sigh::CommandsGenerator.start

      expect(Sigh.config[:platform]).to eq('tvos')
    end
  end

  describe "download_all option handling" do
    it "cert_id short flag from tool options can be used" do
      # leaving out the command name defaults to 'renew'
      stub_commander_runner_args(['download_all', '-i', 'abcd'])

      # download_all takes no params, but we want to expect the call and prevent
      # actual execution of the method
      expect(Sigh::Manager).to receive(:download_all)

      Sigh::CommandsGenerator.start

      expect(Sigh.config[:cert_id]).to eq('abcd')
    end

    it "username short flag from tool options can be used" do
      # leaving out the command name defaults to 'renew'
      stub_commander_runner_args(['download_all', '-u', 'me@it.com'])

      # download_all takes no params, but we want to expect the call and prevent
      # actual execution of the method
      expect(Sigh::Manager).to receive(:download_all)

      Sigh::CommandsGenerator.start

      expect(Sigh.config[:username]).to eq('me@it.com')
    end

    it "custom keychain can be used" do
      # Assuming on regular machine
      test_file = "key.keychain-db"
      File.write(test_file, "")

      stub_commander_runner_args(['download_all', '-k', test_file])

      # download_all takes no params, but we want to expect the call and prevent
      # actual execution of the method
      expect(Sigh::Manager).to receive(:download_all)
      Sigh::CommandsGenerator.start

      expect(Sigh.config[:keychain_path]).to eq(test_file)
      File.unlink(test_file)
    end
  end

  describe "repair option handling" do
    let(:repair) do
      repair = Sigh::Repair.new
      expect(Sigh::Repair).to receive(:new).and_return(repair)
      repair
    end

    it "username short flag from tool options can be used" do
      # leaving out the command name defaults to 'renew'
      stub_commander_runner_args(['repair', '-u', 'me@it.com'])

      # repair_all takes no params, but we want to expect the call and prevent
      # actual execution of the method
      expect(repair).to receive(:repair_all)

      Sigh::CommandsGenerator.start

      expect(Sigh.config[:username]).to eq('me@it.com')
    end
  end
end
