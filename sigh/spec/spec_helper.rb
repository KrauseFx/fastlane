def sigh_stub_spaceship_connect(inhouse: false, create_profile_app_identifier: nil, all_app_identifiers: [], app_identifier_and_profile_names: {}, valid_profiles: true, expect_delete: false)
  allow(Spaceship::ConnectAPI).to receive(:login).and_return(nil)
  allow(Spaceship::ConnectAPI).to receive(:client).and_return("client")
  allow(Spaceship::ConnectAPI).to receive(:select_team).and_return(nil)

  allow(Spaceship::ConnectAPI.client).to receive(:in_house?).and_return(inhouse)

  # Mock cert
  certificate = "certificate"
  allow(certificate).to receive(:id).and_return("123456789")
  allow(certificate).to receive(:display_name).and_return("Roger Oba")
  allow(certificate).to receive(:expiration_date).and_return("2021-07-22T00:27:42.000+0000")
  allow(certificate).to receive(:certificate_content).and_return(Base64.encode64("cert content"))
  allow(Spaceship::ConnectAPI::Certificate).to receive(:all).and_return([certificate, certificate])

  device = "device"
  allow(device).to receive(:id).and_return(1)
  allow(Spaceship::ConnectAPI::Device).to receive(:devices_for_platform).and_return([device])

  bundle_ids = all_app_identifiers.map do |id|
    Spaceship::ConnectAPI::BundleId.new("123", {
      identifier: id,
      name: id,
      seedId: "seed",
      platform: "IOS"
    })
  end

  allow(Spaceship::ConnectAPI::BundleId).to receive(:find).with(anything).and_return(nil)
  bundle_ids.each do |bundle_id|
    allow(Spaceship::ConnectAPI::BundleId).to receive(:find).with(bundle_id.identifier).and_return(bundle_id)
  end

  if create_profile_app_identifier
    bundle_id = bundle_ids.find { |b| b.identifier.to_s == create_profile_app_identifier }
    expect(Spaceship::ConnectAPI::Profile).to receive(:create).with(anything) do |value|
      profile = Spaceship::ConnectAPI::Profile.new("123", {
        name: value[:name],
        platform: "IOS",
        profileState: Spaceship::ConnectAPI::Profile::ProfileState::ACTIVE,
        profileContent: Base64.encode64("profile content")
      })
      allow(profile).to receive(:bundle_id).and_return(bundle_id)
      allow(profile).to receive(:expiration_date).and_return(Date.today.next_year.to_time.utc.strftime("%Y-%m-%dT%H:%M:%S%:z"))

      profile
    end
  end

  profiles = []
  app_identifier_and_profile_names.each do |app_identifier, profile_names|
    profiles += profile_names.map do |name|
      bundle_id = bundle_ids.find { |b| b.identifier.to_s == app_identifier.to_s }
      raise "Could not find BundleId for #{app_identifier} in #{bundle_ids.map(&:identifier)}" unless bundle_id
      profile = Spaceship::ConnectAPI::Profile.new("123", {
        name: name,
        platform: "IOS",
        profileState: valid_profiles ? Spaceship::ConnectAPI::Profile::ProfileState::ACTIVE : Spaceship::ConnectAPI::Profile::ProfileState::INVALID,
        profileContent: Base64.encode64("profile content")
      })
      allow(profile).to receive(:bundle_id).and_return(bundle_id)
      allow(profile).to receive(:certificates).and_return([certificate])

      expect(profile).to receive(:delete!) if expect_delete

      if valid_profiles
        allow(profile).to receive(:expiration_date).and_return(Date.today.next_year.to_time.utc.strftime("%Y-%m-%dT%H:%M:%S%:z"))
      else
        allow(profile).to receive(:expiration_date).and_return(Date.today.prev_year.to_time.utc.strftime("%Y-%m-%dT%H:%M:%S%:z"))
      end

      profile
    end
  end
  allow(Spaceship::ConnectAPI::Profile).to receive(:all).and_return(profiles)
  profiles.each do |profile|
    allow(Spaceship::ConnectAPI::Profile).to receive(:all).with(filter: { name: profile.name }).and_return([profile])
  end

  # Stubs production to only receive certs
  certs = [Spaceship.certificate.production]
  certs.each do |current|
    allow(current).to receive(:all).and_return([certificate])
  end

  # apple_distribution also gets called for Xcode 11 profiles
  # so need to stub and empty array return
  certs = [Spaceship.certificate.apple_distribution]
  certs.each do |current|
    allow(current).to receive(:all).and_return([])
  end
end

def sigh_stub_spaceship(valid_profile = true, expect_create = false, expect_delete = false, fail_delete = false)
  profile = "profile"
  certificate = "certificate"

  profiles_after_delete = expect_delete && !fail_delete ? [] : [profile]

  expect(Spaceship).to receive(:login).and_return(nil)
  allow(Spaceship).to receive(:client).and_return("client")
  expect(Spaceship).to receive(:select_team).and_return(nil)
  expect(Spaceship.client).to receive(:in_house?).and_return(false)
  allow(Spaceship.app).to receive(:find).and_return(true)
  allow(Spaceship.provisioning_profile).to receive(:all).and_return(profiles_after_delete)

  allow(profile).to receive(:valid?).and_return(valid_profile)
  allow(profile.class).to receive(:pretty_type).and_return("pretty")
  allow(profile).to receive(:download).and_return("FileContent")
  allow(profile).to receive(:name).and_return("com.krausefx.app AppStore")

  if expect_delete
    expect(profile).to receive(:delete!)
  else
    expect(profile).to_not(receive(:delete!))
  end

  profile_type = Spaceship.provisioning_profile.app_store
  allow(profile_type).to receive(:find_by_bundle_id).and_return([profile])

  if expect_create
    expect(profile_type).to receive(:create!).and_return(profile)
  else
    expect(profile_type).to_not(receive(:create!))
  end

  # Stubs production to only receive certs
  certs = [Spaceship.certificate.production]
  certs.each do |current|
    allow(current).to receive(:all).and_return([certificate])
  end

  # apple_distribution also gets called for Xcode 11 profiles
  # so need to stub and empty array return
  certs = [Spaceship.certificate.apple_distribution]
  certs.each do |current|
    allow(current).to receive(:all).and_return([])
  end
end

def stub_request_valid_identities(resign, value)
  expect(resign).to receive(:request_valid_identities).and_return(value)
end

def generate_devices_list(total)
  devices = []
  (0..total).each do |i|
    device_name = "device#{i + 1}"
    device = { "id" => device_name, "udid" => device_name }
    allow(device).to receive(:udid).and_return(device_name)
    allow(device).to receive(:id).and_return(device_name)
    devices << device
  end
  return devices
end

# Commander::Command::Options does not define sane equals behavior,
# so we need this to make testing easier
RSpec::Matchers.define(:match_commander_options) do |expected|
  match { |actual| actual.__hash__ == expected.__hash__ }
end
