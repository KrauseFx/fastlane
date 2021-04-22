describe Spaceship::ConnectAPI::BetaTesterMetric do
  before { Spaceship::ConnectAPI.login }

  describe '#Spaceship::ConnectAPI' do
    it '#get_beta_tester_metrics' do
      response = Spaceship::ConnectAPI.get_beta_tester_metrics
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(3)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::BetaTesterMetric)
      end

      model = response.first
      expect(model.id).to eq("123456789")
      expect(model.install_count).to eq(13)
      expect(model.crash_count).to eq(0)
      expect(model.session_count).to eq(319)
      expect(model.beta_tester_state).to eq("INSTALLED")
      expect(model.last_modified_date).to eq("2018-11-20T10:06:55-08:00")
      expect(model.installed_cf_bundle_short_version_string).to eq("2.6.1")
      expect(model.installed_cf_bundle_version).to eq("1542691006")
    end
  end
end
