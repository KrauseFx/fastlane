describe Spaceship::ProvisioningProfile do
  before { Spaceship.login }
  let(:client) { Spaceship::ProvisioningProfile.client }
  let(:cert_id) { "C8DL7464RQ" }

  describe '#all' do
    let(:provisioning_profiles) { Spaceship::ProvisioningProfile.all }

    it "properly retrieves and filters the provisioning profiles" do
      expect(provisioning_profiles.count).to eq(7)

      profile = provisioning_profiles[5]
      expect(profile.name).to eq('delete.me.please AppStore')
      expect(profile.type).to eq('iOS Distribution')
      expect(profile.app.app_id).to eq('2UMR2S6P4L')
      expect(profile.status).to eq('Active')
      expect(profile.expires.class).to eq(Time)
      expect(profile.expires.to_s).to eq('2016-02-10 00:00:00 UTC')
      expect(profile.uuid).to eq('58ce5b78-15f8-4ceb-83f1-a29f6c4d066f')
      expect(profile.managed_by_xcode?).to eq(false)
      expect(profile.distribution_method).to eq('store')
      expect(profile.class.type).to eq('store')
      expect(profile.class.pretty_type).to eq('AppStore')
      expect(profile.type).to eq('iOS Distribution')
    end

    it 'should filter by the correct types' do
      expect(Spaceship::ProvisioningProfile::Development.all.count).to eq(1)
      expect(Spaceship::ProvisioningProfile::AdHoc.all.count).to eq(1)
      expect(Spaceship::ProvisioningProfile::AppStore.all.count).to eq(5)
    end

    it "AppStore and AdHoc are not the same" do
      Spaceship::ProvisioningProfile::AdHoc.all.each do |adhoc|
        expect(Spaceship::ProvisioningProfile::AppStore.all.find_all { |a| a.id == adhoc.id }.count).to eq(0)
      end
    end

    it 'should have an app' do
      profile = provisioning_profiles.first
      expect(profile.app).to be_instance_of(Spaceship::App)
    end

    describe "include managed by Xcode" do
      it 'filters Xcode managed profiles' do
        provisioning_profiles = Spaceship::ProvisioningProfile.all(xcode: false)
        expect(provisioning_profiles.count).to eq(7) # ignore the Xcode generated profiles
      end

      it 'includes Xcode managed profiles' do
        provisioning_profiles = Spaceship::ProvisioningProfile.all(xcode: true)
        expect(provisioning_profiles.count).to eq(7) # include the Xcode generated profiles
      end
    end
  end

  describe '#all via xcode api' do
    it 'should use the Xcode api to get provisioning profiles and their appIds' do
      FastlaneSpec::Env.with_env_values(SPACESHIP_AVOID_XCODE_API: nil) do
        expect(client).to receive(:provisioning_profiles_via_xcode_api).and_call_original
        expect(client).not_to(receive(:provisioning_profiles))
        expect(client).not_to(receive(:provisioning_profile_details))
        Spaceship::ProvisioningProfile.find_by_bundle_id(bundle_id: 'some-fake-id')
      end
    end

    it 'should use the developer portal api to get provisioning profiles and their appIds' do
      FastlaneSpec::Env.with_env_values(SPACESHIP_AVOID_XCODE_API: 'true') do
        expect(client).not_to(receive(:provisioning_profiles_via_xcode_api))
        expect(client).to receive(:provisioning_profiles).and_call_original
        expect(client).to receive(:provisioning_profile_details).and_call_original.exactly(7).times
        Spaceship::ProvisioningProfile.find_by_bundle_id(bundle_id: 'some-fake-id')
      end
    end
  end

  describe '#find_by_bundle_id' do
    it "returns [] if there are no profiles" do
      profiles = Spaceship::ProvisioningProfile.find_by_bundle_id(bundle_id: "notExistent")
      expect(profiles).to eq([])
    end

    it "returns the profile in an array if matching for ios" do
      profiles = Spaceship::ProvisioningProfile.find_by_bundle_id(bundle_id: "net.sunapps.1")
      expect(profiles.count).to eq(6)

      expect(profiles.first.app.bundle_id).to eq('net.sunapps.1')
      expect(profiles.first.distribution_method).to eq('adhoc')
    end

    it "returns the profile in an array if matching for tvos" do
      profiles = Spaceship::ProvisioningProfile.find_by_bundle_id(bundle_id: "net.sunapps.1", sub_platform: 'tvOS')
      expect(profiles.count).to eq(1)

      expect(profiles.first.app.bundle_id).to eq('net.sunapps.1')
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

  it "distribution_method says `adhoc` for AdHoc profile" do
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
      PortalStubbing.adp_stub_download_provisioning_profile_failure
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
    let(:fake_app_info) { {} }

    describe 'accepted distribution methods' do
      let(:accepted_distribution_methods) do
        {
          'limited' => 'Development',
          'store' => 'AppStore',
          'adhoc' => 'AdHoc',
          'inhouse' => 'InHouse',
          'direct' => 'Direct'
        }
      end

      let(:expected_profile) { "expected_profile" }

      it 'creates proper profile types' do
        accepted_distribution_methods.each do |k, v|
          expect(Kernel.const_get("Spaceship::ProvisioningProfile::#{v}")).to receive(:new).and_return(expected_profile)
          profile = Spaceship::ProvisioningProfile.factory({ 'appId' => fake_app_info, 'proProPlatform' => 'mac', 'distributionMethod' => k })
          expect(profile).to eq(expected_profile)
        end
      end
    end

    describe 'unrecognized distribution method' do
      subject do
        Spaceship::ProvisioningProfile.factory({ 'appId' => fake_app_info, 'proProPlatform' => 'mac', 'distributionMethod' => 'hamsandwich' })
      end

      it 'raises error' do
        expect { subject }.to raise_error("Can't find class 'hamsandwich'")
      end
    end
  end

  describe '#create!' do
    let(:certificate) { Spaceship::Certificate.all.first }

    it 'creates a new development provisioning profile' do
      expect(Spaceship::Device).to receive(:all).and_return([])
      expect(client).to receive(:create_provisioning_profile!).with('Delete Me', 'limited', '2UMR2S6PAA', "XC5PH8DAAA", [], mac: false, sub_platform: nil, template_name: nil).and_return({})
      Spaceship::ProvisioningProfile::Development.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate)
    end

    it 'creates a new appstore provisioning profile' do
      expect(client).to receive(:create_provisioning_profile!).with('Delete Me', 'store', '2UMR2S6PAA', "XC5PH8DAAA", [], mac: false, sub_platform: nil, template_name: nil).and_return({})
      Spaceship::ProvisioningProfile::AppStore.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate)
    end

    it 'creates a provisioning profile with only the required parameters and auto fills all available devices' do
      expect(client).to receive(:create_provisioning_profile!).with('net.sunapps.1 AppStore',
                                                                    'store',
                                                                    '2UMR2S6PAA',
                                                                    "XC5PH8DAAA",
                                                                    [],
                                                                    mac: false,
                                                                    sub_platform: nil,
                                                                    template_name: nil).
        and_return({})
      Spaceship::ProvisioningProfile::AppStore.create!(bundle_id: 'net.sunapps.1', certificate: certificate)
    end

    it 'creates a new appstore provisioning profile with template' do
      template_name = 'Test Template'
      expect(client).to receive(:create_provisioning_profile!).with('Delete Me', 'store', '2UMR2S6PAA', "XC5PH8DAAA", [], mac: false, sub_platform: nil, template_name: template_name).and_return({})
      Spaceship::ProvisioningProfile::AppStore.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate, template_name: template_name)
    end

    it 'raises an error if the user wants to create a profile for a non-existing app' do
      expect do
        Spaceship::ProvisioningProfile::AppStore.create!(bundle_id: 'notExisting', certificate: certificate)
      end.to raise_error("Could not find app with bundle id 'notExisting'")
    end

    describe 'modify devices to prevent having devices on profile types where it does not make sense' do
      it 'Direct (Mac) profile types have no devices' do
        fake_devices = Spaceship::Device.all
        expected_devices = []
        expect(Spaceship::ProvisioningProfile::Direct.client).to receive(:create_provisioning_profile!).with('Delete Me', 'direct', '2UMR2S6PAA', "XC5PH8DAAA", expected_devices, mac: true, sub_platform: nil, template_name: nil).and_return({})
        Spaceship::ProvisioningProfile::Direct.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate, mac: true, devices: fake_devices)
      end

      it 'Development profile types have devices' do
        fake_devices = Spaceship::Device.all
        expected_devices = fake_devices.collect(&:id)
        expect(Spaceship::ProvisioningProfile::Development.client).to receive(:create_provisioning_profile!).with('Delete Me', 'limited', '2UMR2S6PAA', "XC5PH8DAAA", expected_devices, mac: false, sub_platform: nil, template_name: nil).and_return({})
        Spaceship::ProvisioningProfile::Development.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate, devices: fake_devices)
      end

      it 'AdHoc profile types have no devices' do
        fake_devices = Spaceship::Device.all
        expected_devices = fake_devices.collect(&:id)
        expect(Spaceship::ProvisioningProfile::AdHoc.client).to receive(:create_provisioning_profile!).with('Delete Me', 'adhoc', '2UMR2S6PAA', "XC5PH8DAAA", expected_devices, mac: false, sub_platform: nil, template_name: nil).and_return({})
        Spaceship::ProvisioningProfile::AdHoc.create!(name: 'Delete Me', bundle_id: 'net.sunapps.1', certificate: certificate, devices: fake_devices)
      end

      it 'AppStore profile types have no devices' do
        fake_devices = Spaceship::Device.all
        expected_devices = []
        expect(Spaceship::ProvisioningProfile::AppStore.client).to receive(:create_provisioning_profile!).with('Delete Me', 'store', '2UMR2S6PAA', "XC5PH8DAAA", expected_devices, mac: false, sub_platform: nil, template_name: nil).and_return({})
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
    let(:profile) { Spaceship::ProvisioningProfile.all.detect { |pp| pp.id == 'PP00000006' } }

    it "repairs an existing profile with added devices" do
      profile.devices = Spaceship::Device.all_for_profile_type(profile.type)
      expect(client).to receive(:repair_provisioning_profile!).with('PP00000006', 'delete.me.please AppStore', 'store', '2UMR2S6P4L', [cert_id], ["AAAAAAAAAA", "BBBBBBBBBB", "CCCCCCCCCC", "DDDDDDDDDD"], mac: false, sub_platform: nil, template_name: nil).and_return({})
      profile.repair!
    end

    it "update the certificate if the current one doesn't exist" do
      profile.certificates = []
      expect(client).to receive(:repair_provisioning_profile!).with('PP00000006', 'delete.me.please AppStore', 'store', '2UMR2S6P4L', [cert_id], [], mac: false, sub_platform: nil, template_name: nil).and_return({})

      # expect(client).to receive(:repair_provisioning_profile!).with('PP00000002', '1 Gut Altentann Ad Hoc', 'store', '2UMR2S6P4L', [cert_id], [], mac: false, sub_platform: nil).and_return({})
      profile.repair!
    end

    it "update the certificate if the current one is invalid" do
      expect(profile.certificates.first.id).to eq("3BH4JJSWM4")
      expect(client).to receive(:repair_provisioning_profile!).with('PP00000006', 'delete.me.please AppStore', 'store', '2UMR2S6P4L', [cert_id], [], mac: false, sub_platform: nil, template_name: nil).and_return({})
      profile.repair! # repair will replace the old certificate with the new one
    end

    it "repairs an existing profile with no devices" do
      expect(client).to receive(:repair_provisioning_profile!).with('PP00000006', 'delete.me.please AppStore', 'store', '2UMR2S6P4L', [cert_id], [], mac: false, sub_platform: nil, template_name: nil).and_return({})
      profile.repair!
    end

    describe "Different Environments" do
      it "Development" do
        profile = Spaceship::ProvisioningProfile::Development.all.first
        devices = ["FVRY7XH22J", "4ZE252U553"]
        expect(client).to receive(:repair_provisioning_profile!).with('PP00000005', '112 Wombats RC Development', 'limited', '2UMR2S6P4L', [cert_id], devices, mac: false, sub_platform: nil, template_name: nil).and_return({})
        profile.repair!
      end
    end

    context "if the profile was created with a template" do
      let(:profile) { Spaceship::ProvisioningProfile.all.detect { |pp| pp.id == 'PP00000007' } }

      it "repairs an existing profile with template" do
        expect(client).to receive(:repair_provisioning_profile!).with('PP00000007', 'Profile with Template App Store', 'store', '2UMR2S6P4L', [cert_id], [], mac: false, sub_platform: nil, template_name: "Subscription Service (dist)").and_return({})

        profile.repair!
      end
    end
  end

  describe "#update!" do
    let(:profile) { Spaceship::ProvisioningProfile.all.detect { |pp| pp.id == 'PP00000006' } }
    let(:tvOSProfile) { Spaceship::ProvisioningProfile.all_tvos.first }

    it "updates an existing iOS profile" do
      expect(client).to receive(:repair_provisioning_profile!).with('PP00000006', 'delete.me.please AppStore', 'store', '2UMR2S6P4L', [cert_id], [], mac: false, sub_platform: nil, template_name: nil).and_return({})
      profile.update!
    end

    it "updates an existing tvOS profile" do
      expect(client).to receive(:repair_provisioning_profile!).with('PP00000004', '107 GC Lorenzen AppStore tvOS', 'store', '2UMR2S6P4L', [cert_id], [], mac: false, sub_platform: 'tvOS', template_name: nil).and_return({})
      tvOSProfile.update!
    end

    context "if the profile was created with a template" do
      let(:profile) { Spaceship::ProvisioningProfile.all.detect { |pp| pp.id == 'PP00000007' } }

      it "updates an existing profile with template" do
        expect(client).to receive(:repair_provisioning_profile!).with('PP00000007', 'Profile with Template App Store', 'store', '2UMR2S6P4L', [cert_id], [], mac: false, sub_platform: nil, template_name: "Subscription Service (dist)").and_return({})

        profile.update!
      end
    end
  end
end
