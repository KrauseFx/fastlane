describe Spaceship::ConnectAPI::BetaBuildMetric do
  before { Spaceship::ConnectAPI.login }

  describe '#Spaceship::ConnectAPI' do
    it '#get_beta_build_metrics' do
      response = Spaceship::ConnectAPI.get_beta_build_metrics
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(1)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::BetaBuildMetric)
      end

      model = response.first
      expect(model.id).to eq("123456789")
      expect(model.install_count).to eq(1)
      expect(model.crash_count).to eq(2)
      expect(model.invite_count).to eq(3)
      expect(model.seven_day_tester_count).to eq(4)
    end
  end
end
