describe Spaceship::ConnectAPI::BetaTester do
  before { Spaceship::ConnectAPI.login }

  describe '#Spaceship::ConnectAPI' do
    it '#get_beta_testers' do
      response = Spaceship::ConnectAPI.get_beta_testers
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(2)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::BetaTester)
      end

      model = response.first
      expect(model.id).to eq("123456789")
      expect(model.first_name).to eq("Cats")
      expect(model.last_name).to eq("AreCute")
      expect(model.email).to eq("email@email.com")
      expect(model.invite_type).to eq("EMAIL")
      expect(model.invitation).to eq(nil)
    end
  end
end
