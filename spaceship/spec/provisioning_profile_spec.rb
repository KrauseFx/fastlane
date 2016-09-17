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
      expect(profile.distribution_method).to eq('adhoc')
      expect(profile.class.type).to eq('adhoc')
      expect(profile.class.pretty_type).to eq('AdHoc')
      expect(profile.type).to eq('iOS Distribution')
    end

    it 'should filter by the correct types' do
      expect(Spaceship::ProvisioningProfile::Development.all.count).to eq(1)
      expect(Spaceship::ProvisioningProfile::AdHoc.all.count).to eq(1)
      expect(Spaceship::ProvisioningProfile::AppStore.all.count).to eq(1)
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
      expect(profiles.last.distribution_method).to eq('adhoc')
    end
  end

  describe '#class.type' do
    it "Returns only valid profile types" do
      valid = %w(limited adhoc store)
      Spaceship::ProvisioningProfile.all.each do |profile|
        expect(valid).to include(profile.class.type)
      end
    end
  end

  it "updates the distribution method to adhoc if devices are enabled" do
    adhoc = Spaceship::ProvisioningProfile::AdHoc.all.first

    expect(adhoc.distribution_method).to eq('adhoc')
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
      p = Spaceship::ProvisioningProfile.all.last
      expect(p).to receive(:certificate_valid?).and_return(true)
      expect(p.valid?).to eq(true)
    end

    it "Invalid profile" do
      profile = Spaceship::ProvisioningProfile.all.first
      profile.status = 'Expired'
      expect(profile.valid?).to eq(false)
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
end
