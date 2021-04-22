describe Spaceship::ConnectAPI::AppStoreVersionReleaseRequest do
  before { Spaceship::ConnectAPI.login }

  describe '#Spaceship::ConnectAPI' do
    it '#post_app_store_version_release_request' do
      response = Spaceship::ConnectAPI.post_app_store_version_release_request
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(1)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::AppStoreVersionReleaseRequest)
      end

      model = response.first
      expect(model.id).to eq("123456789")
    end
  end
end
