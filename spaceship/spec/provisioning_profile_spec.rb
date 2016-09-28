require 'spec_helper'

describe Spaceship::ProvisioningProfile do
  before { Spaceship.login }
  let(:client) { Spaceship::ProvisioningProfile.client }
  let(:cert_id) { "C8DL7464RQ" }

  describe '#all' do
    let(:provisioning_profiles) { Spaceship::ProvisioningProfile.all }

    it "properly retrieves and filters the provisioning profiles" do
      expect(provisioning_profiles.count).to eq(3) # ignore the Xcode generated profiles

      profile = provisioning_profiles.last
      expect(profile.name).to eq('net.sunapps.7 AdHoc')
      expect(profile.type).to eq('iOS Distribution')
      expect(profile.app.app_id).to eq('572XTN75U2')
      expect(profile.status).to eq('Active')
      expect(profile.expires.to_s).to eq('2015-11-25T22:45:50+00:00')
      expect(profile.uuid).to eq('a8b1563e-7559-41f7-854b-6cd09f950d11')
      expect(profile.managed_by_xcode?).to eq(false)
      expect(profile.distribution_method).to eq('store')
      expect(profile.class.type).to eq('store')
      expect(profile.class.pretty_type).to eq('AppStore')
      expect(profile.type).to eq('iOS Distribution')
    end

    it 'should filter by the correct types' do
      expect(Spaceship::ProvisioningProfile::Development.all.count).to eq(1)
      expect(Spaceship::ProvisioningProfile::AdHoc.all.count).to eq(2)
      expect(Spaceship::ProvisioningProfile::AppStore.all.count).to eq(2)
    end

    it "AppStore and AdHoc are the same" do
      Spaceship::ProvisioningProfile::AdHoc.all.each do |adhoc|
        expect(Spaceship::ProvisioningProfile::AppStore.all.find_all { |a| a.id == adhoc.id }.count).to eq(1)
      end
    end

    it 'should have an app' do
      profile = provisioning_profiles.first
      expect(profile.app).to be_instance_of(Spaceship::App)
    end
  end

  describe '#find_by_bundle_id' do
    it "returns [] if there are no profiles" do
      profiles = Spaceship::ProvisioningProfile.find_by_bundle_id("notExistent")
      expect(profiles).to eq([])
    end

    it "returns the profile in an array if matching" do
      profiles = Spaceship::ProvisioningProfile.find_by_bundle_id("net.sunapps.7")
      expect(profiles.count).to eq(3)

      expect(profiles.first.app.bundle_id).to eq('net.sunapps.7')
      expect(profiles.first.distribution_method).to eq('store')
    end
  end

  describe '#class.type' do
    it "Returns only valid profile types" do
      valid = %w(limited adhoc store direct)
      Spaceship::ProvisioningProfile.all.each do |profile|
        expect(valid).to include(profile.class.type)
      end
    end
  end

  it "distribution_method stays app store, even though it's an AdHoc profile which contains devices" do
    adhoc = Spaceship::ProvisioningProfile::AdHoc.all.find(&:is_adhoc?)

    expect(adhoc.distribution_method).to eq('store')
    expect(adhoc.devices.count).to eq(2)

    device = adhoc.devices.first
    expect(device.id).to eq('FVRY7XH22J')
    expect(device.name).to eq('Felix Krause\'s iPhone 6s')
    expect(device.udid).to eq('aaabbbccccddddaaabbb')
    expect(device.platform).to eq('ios')
    expect(device.status).to eq('c')
  end

  describe '#download' do
    it "downloads an existing provisioning profile" do
      file = Spaceship::ProvisioningProfile.all.first.download
      xml = Plist.parse_xml(file)
      expect(xml['AppIDName']).to eq("SunApp Setup")
      expect(xml['TeamName']).to eq("SunApps GmbH")
    end

    it "handles failed download request" do
      adp_stub_download_provisioning_profile_failure
      profile = Spaceship::ProvisioningProfile.all.first

      error_text = /^Couldn't download provisioning profile, got this instead:/
      expect do
        profile.download
      end.to raise_error(Spaceship::Client::UnexpectedResponse, error_text)
    end
  end

  describe '#valid?' do
    it "Valid profile" do
      p = Spaceship::ProvisioningProfile.all.first
      expect(p.valid?).to eq(true)
    end

    it "Invalid profile" do
      profile = Spaceship::ProvisioningProfile.all.first
      profile.status = 'Expired'
      expect(profile.valid?).to eq(false)
    end
  end

  describe '#factory' do
    it 'creates a Direct profile type for distributionMethod "direct"' do
      fake_app_info = {}
      expected_profile = "expected_profile"
      expect(Spaceship::ProvisioningProfile::Direct).to receive(:new).and_return(expected_profile)
      profile = Spaceship::ProvisioningProfile.factory({ 'appId' => fake_app_info, 'proProPlatform' => 'mac', 'distributionMethod' => 'direct' })
      expect(profile).to eq(expected_profile)
    end
  end

  describe '#create!' do
    let(:certificate) { Spaceship::Certificate.all.first }

    it 'creates a new development provisioning profile' do
      expect(Spaceship::Device).to receive(:all).and_return([])
      expect(client).to receive(:create_provisioning_profile!).with('Delete Me', 'limited', '2UMR2S6PAA', "XC5PH8DAAA", [], mac: false, sub_platform: nil).and_return({})
      Spaceship::ProvisioningProfile::Development.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate)
    end

    it 'creates a new appstore provisioning profile' do
      expect(client).to receive(:create_provisioning_profile!).with('Delete Me', 'store', '2UMR2S6PAA', "XC5PH8DAAA", [], mac: false, sub_platform: nil).and_return({})
      Spaceship::ProvisioningProfile::AppStore.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate)
    end

    it 'creates a provisioning profile with only the required parameters and auto fills all available devices' do
      expect(client).to receive(:create_provisioning_profile!).with('net.sunapps.1 AppStore',
                                                                    'store',
                                                                    '2UMR2S6PAA',
                                                                    "XC5PH8DAAA",
                                                                    [],
                                                                    mac: false,
                                                                    sub_platform: nil).
        and_return({})
      Spaceship::ProvisioningProfile::AppStore.create!(bundle_id: 'net.sunapps.1', certificate: certificate)
    end

    it 'raises an error if the user wants to create a profile for a non-existing app' do
      expect do
        Spaceship::ProvisioningProfile::AppStore.create!(bundle_id: 'notExisting', certificate: certificate)
      end.to raise_error "Could not find app with bundle id 'notExisting'"
    end

    describe 'modify devices to prevent having devices on profile types where it does not make sense' do
      it 'Direct (Mac) profile types have no devices' do
        fake_devices = Spaceship::Device.all
        expected_devices = []
        expect(Spaceship::ProvisioningProfile::Direct.client).to receive(:create_provisioning_profile!).with('Delete Me', 'direct', '2UMR2S6PAA', "XC5PH8DAAA", expected_devices, mac: true, sub_platform: nil).and_return({})
        Spaceship::ProvisioningProfile::Direct.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate, mac: true, devices: fake_devices)
      end

      it 'Development profile types have devices' do
        fake_devices = Spaceship::Device.all
        expected_devices = fake_devices.collect(&:id)
        expect(Spaceship::ProvisioningProfile::Development.client).to receive(:create_provisioning_profile!).with('Delete Me', 'limited', '2UMR2S6PAA', "XC5PH8DAAA", expected_devices, mac: false, sub_platform: nil).and_return({})
        Spaceship::ProvisioningProfile::Development.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate, devices: fake_devices)
      end

      it 'AdHoc profile types have no devices' do
        fake_devices = Spaceship::Device.all
        expected_devices = fake_devices.collect(&:id)
        expect(Spaceship::ProvisioningProfile::AdHoc.client).to receive(:create_provisioning_profile!).with('Delete Me', 'adhoc', '2UMR2S6PAA', "XC5PH8DAAA", expected_devices, mac: false, sub_platform: nil).and_return({})
        Spaceship::ProvisioningProfile::AdHoc.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate, devices: fake_devices)
      end

      it 'AppStore profile types have no devices' do
        fake_devices = Spaceship::Device.all
        expected_devices = []
        expect(Spaceship::ProvisioningProfile::AppStore.client).to receive(:create_provisioning_profile!).with('Delete Me', 'store', '2UMR2S6PAA', "XC5PH8DAAA", expected_devices, mac: false, sub_platform: nil).and_return({})
        Spaceship::ProvisioningProfile::AppStore.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate, devices: fake_devices)
      end
    end
  end

  describe "#delete" do
    let(:profile) { Spaceship::ProvisioningProfile.all.first }
    it "deletes an existing profile" do
      expect(client).to receive(:delete_provisioning_profile!).with(profile.id, mac: false).and_return({})
      profile.delete!
    end
  end

  describe "#repair" do
    let(:profile) { Spaceship::ProvisioningProfile.all.first }

    it "repairs an existing profile with added devices" do
      profile.devices = Spaceship::Device.all_for_profile_type(profile.type)
      expect(client).to receive(:repair_provisioning_profile!).with('2MAY7NPHRU', 'net.sunapps.7 AppStore', 'store', '572XTN75U2', [cert_id], ["AAAAAAAAAA", "BBBBBBBBBB", "CCCCCCCCCC", "DDDDDDDDDD"], mac: false).and_return({})
      profile.repair!
    end

    it "update the certificate if the current one doesn't exist" do
      profile.certificates = []
      expect(client).to receive(:repair_provisioning_profile!).with('2MAY7NPHRU', 'net.sunapps.7 AppStore', 'store', '572XTN75U2', [cert_id], [], mac: false).and_return({})
      profile.repair!
    end

    it "update the certificate if the current one is invalid" do
      expect(profile.certificates.first.id).to eq("3BH4JJSWM4")
      expect(client).to receive(:repair_provisioning_profile!).with('2MAY7NPHRU', 'net.sunapps.7 AppStore', 'store', '572XTN75U2', [cert_id], [], mac: false).and_return({})
      profile.repair! # repair will replace the old certificate with the new one
    end

    it "repairs an existing profile with no devices" do
      expect(client).to receive(:repair_provisioning_profile!).with('2MAY7NPHRU', 'net.sunapps.7 AppStore', 'store', '572XTN75U2', [cert_id], [], mac: false).and_return({})
      profile.repair!
    end

    describe "Different Environments" do
      it "Development" do
        profile = Spaceship::ProvisioningProfile::Development.all.first
        devices = ["FVRY7XH22J", "4ZE252U553"]
        expect(client).to receive(:repair_provisioning_profile!).with('475ESRP5F3', 'net.sunapps.7 Development', 'limited', '572XTN75U2', [cert_id], devices, mac: false).and_return({})
        profile.repair!
      end
    end
  end

  describe "#update!" do
    let(:profile) { Spaceship::ProvisioningProfile.all.first }

    it "updates an existing profile" do
      expect(client).to receive(:repair_provisioning_profile!).with('2MAY7NPHRU', 'net.sunapps.7 AppStore', 'store', '572XTN75U2', [cert_id], [], mac: false).and_return({})
      profile.update!
    end
  end

  describe "#is_adhoc?" do
    it "returns true when the profile is adhoc" do
      profile = Spaceship::ProvisioningProfile::AdHoc.new
      expect(profile).to receive(:devices).and_return(["device"])
      expect(profile.is_adhoc?).to eq(true)
    end

    it "returns true when the profile is appstore with devices" do
      profile = Spaceship::ProvisioningProfile::AppStore.new
      expect(profile).to receive(:devices).and_return(["device"])
      expect(profile.is_adhoc?).to eq(true)
    end

    it "returns false when the profile is appstore with no devices" do
      profile = Spaceship::ProvisioningProfile::AppStore.new
      expect(profile).to receive(:devices).and_return([])
      expect(profile.is_adhoc?).to eq(false)
    end

    it "returns false when the profile is development" do
      profile = Spaceship::ProvisioningProfile::Development.new
      expect(profile.is_adhoc?).to eq(false)
    end

    it "returns false when the profile is inhouse" do
      profile = Spaceship::ProvisioningProfile::InHouse.new
      expect(profile.is_adhoc?).to eq(false)
    end
  end
end
