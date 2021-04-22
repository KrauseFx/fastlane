describe Spaceship::ConnectAPI::BuildDelivery do
  before { Spaceship::ConnectAPI.login }

  describe '#Spaceship::ConnectAPI' do
    it '#get_build_deliveries' do
      response = Spaceship::ConnectAPI.get_build_deliveries
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(1)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::BuildDelivery)
      end

      model = response.first
      expect(model.id).to eq("123456789")
      expect(model.cf_build_version).to eq("225")
      expect(model.cf_build_short_version_string).to eq("1.1")
      expect(model.platform).to eq("IOS")
      expect(model.uploaded_date).to eq("2019-05-06T20:14:37-07:00")
    end
  end
end
