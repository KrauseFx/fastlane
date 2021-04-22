describe Spaceship::ConnectAPI::BetaGroup do
  before { Spaceship::ConnectAPI.login }

  describe '#Spaceship::ConnectAPI' do
    it '#get_beta_groups' do
      response = Spaceship::ConnectAPI.get_beta_groups
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(3)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::BetaGroup)
      end

      model = response.first
      expect(model.id).to eq("123456789")
      expect(model.name).to eq("App Store Connect Users")
      expect(model.created_date).to eq("2018-04-15T18:13:40Z")
      expect(model.is_internal_group).to eq(false)
      expect(model.public_link_enabled).to eq(true)
      expect(model.public_link_id).to eq("abcd1234")
      expect(model.public_link_limit_enabled).to eq(true)
      expect(model.public_link_limit).to eq(10)
      expect(model.public_link).to eq("https://testflight.apple.com/join/abcd1234")
    end

    it '#delete!' do
      response = Spaceship::ConnectAPI.get_beta_groups
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(3)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::BetaGroup)
      end

      model = response.first
      expect(model.id).to eq("123456789")
      model.delete!
    end
  end
end
