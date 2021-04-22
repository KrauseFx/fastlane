describe Spaceship::ConnectAPI::Device do
  before { Spaceship::ConnectAPI.login }

  describe '#client' do
    it '#get_devices' do
      response = Spaceship::ConnectAPI.get_devices
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(3)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::Device)
      end

      model = response.first
      expect(model.id).to eq("123456789")
      expect(model.device_class).to eq("IPHONE")
      expect(model.model).to eq("iPhone 8")
      expect(model.name).to eq("Josh's iPhone")
      expect(model.platform).to eq("IOS")
      expect(model.status).to eq("ENABLED")
      expect(model.udid).to eq("184098239048390489012849018")
      expect(model.added_date).to eq("2018-10-10T01:43:27.000+0000")

      expect(model.enabled?).to eq(true)

      model.status = "DISABLED"
      expect(model.enabled?).to eq(false)
    end

    it '#find_by_udid with an existing enabled udid' do
      udid = "184098239048390489012849018"
      existing_device = Spaceship::ConnectAPI::Device.find_by_udid(udid)
      expect(existing_device.udid).to eq(udid)
    end

    it '#find_by_udid with missing udid because it is a disabled udid' do
      disabled_udid = "5233342324433534345354534"
      non_existing_device = Spaceship::ConnectAPI::Device.find_by_udid(disabled_udid, include_disabled: false)
      expect(non_existing_device).to eq(nil)
    end

    it '#find_by_udid with non-existing udid' do
      udid = "424242"
      non_existing_device = Spaceship::ConnectAPI::Device.find_by_udid(udid)
      expect(non_existing_device).to eq(nil)
    end

    it '#find_by_udid with an existing disabled udid with include_disabled parameter set to true' do
      udid = "5233342324433534345354534"
      existing_device = Spaceship::ConnectAPI::Device.find_by_udid(udid, include_disabled: true)
      expect(existing_device.enabled?).to eq(false)
      expect(existing_device.udid).to eq(udid)
    end
  end
end
