describe Spaceship::ConnectAPI::Build do
  before { Spaceship::ConnectAPI.login }

  describe '#Spaceship::ConnectAPI' do
    it '#get_builds' do
      response = Spaceship::ConnectAPI.get_builds
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(2)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::Build)
      end

      model = response.first
      expect(model.id).to eq("123456789")
      expect(model.version).to eq("225")
      expect(model.uploaded_date).to eq("2019-04-30T17:16:21-07:00")
      expect(model.expiration_date).to eq("2019-07-29T17:16:21-07:00")
      expect(model.expired).to eq(false)
      expect(model.min_os_version).to eq("10.3")
      expect(model.icon_asset_token).to eq({
        "templateUrl" => "https://is3-ssl.mzstatic.com/image/thumb/Purple/v4/97/f3/8a/97f38a96-38df-b4a0-8e93-cbb7c1f5ecd8/Icon-83.5@2x.png.png/{w}x{h}bb.{f}",
        "width" => 167,
        "height" => 167
      })
      expect(model.processing_state).to eq("VALID")
      expect(model.uses_non_exempt_encryption).to eq(false)
    end
  end
end
