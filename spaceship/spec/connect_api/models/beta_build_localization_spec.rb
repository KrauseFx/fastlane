describe Spaceship::ConnectAPI::BetaBuildLocalization do
  before { Spaceship::ConnectAPI.login }

  describe '#Spaceship::ConnectAPI' do
    it '#get_beta_build_localizations' do
      response = Spaceship::ConnectAPI.get_beta_build_localizations
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(2)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::BetaBuildLocalization)
      end

      model = response.first
      expect(model.id).to eq("123456789")
      expect(model.whats_new).to eq("so many en-us things2")
      expect(model.locale).to eq("en-US")
    end
  end
end
