require_relative '../mock_servers'
require 'fastlane-sirp'

describe Spaceship::Client do
  # Skip tunes login and login with portal
  include_examples "common spaceship login", true
  before {
    Spaceship.login
  }
  subject { Spaceship.client }

  describe '#login' do
    it 'sets the session cookies' do
      response = subject.login(username, password)
      expect(subject.cookie).to eq("myacinfo=abcdef")
    end

    it 'raises an exception if authentication failed' do
      expect do
        subject.login('bad-username', 'bad-password')
      end.to raise_exception(Spaceship::Client::InvalidUserCredentialsError)
    end
  end

  context 'authenticated' do
    before { subject.login(username, password) }
    describe '#teams' do
      let(:teams) { subject.teams }
      it 'returns the list of available teams' do
        expect(teams).to be_instance_of(Array)
        expect(teams.first.keys).to eq(["status", "teamId", "type", "extendedTeamAttributes", "teamAgent", "memberships", "currentTeamMember", "name"])
      end
    end

    describe '#team_id' do
      it 'returns the default team_id' do
        expect(subject.team_id).to eq('XXXXXXXXXX')
      end

      it "set custom Team ID" do
        allow_any_instance_of(Spaceship::PortalClient).to receive(:teams).and_return([
                                                                                       { 'teamId' => 'XXXXXXXXXX', 'currentTeamMember' => { 'teamMemberId' => '' } },
                                                                                       { 'teamId' => 'ABCDEF', 'currentTeamMember' => { 'teamMemberId' => '' } }
                                                                                     ])

        team_id = "ABCDEF"
        subject.select_team(team_id: team_id)
        expect(subject.team_id).to eq(team_id)
      end

      it "shows a warning when user is in multiple teams and didn't call select_team" do
        PortalStubbing.adp_stub_multiple_teams
        expect(subject.team_id).to eq("InvalidTeamNameOnlySpaces") # the last team
      end
    end

    describe '#team_name' do
      it 'returns the default team_name' do
        expect(subject.team_name).to eq('SpaceShip')
      end

      it "returns team_name from selected team_id" do
        allow_any_instance_of(Spaceship::PortalClient).to receive(:teams).and_return([
                                                                                       { 'teamId' => 'XXXXXXXXXX', 'name' => 'SpaceShip', 'currentTeamMember' => { 'teamMemberId' => '' } },
                                                                                       { 'teamId' => 'ABCDEF', 'name' => 'PirateShip', 'currentTeamMember' => { 'teamMemberId' => '' } }
                                                                                     ])

        team_id = "ABCDEF"
        subject.select_team(team_id: team_id)
        expect(subject.team_id).to eq(team_id)
        expect(subject.team_name).to eq('PirateShip')
      end

      it "return nil if no teams" do
        allow_any_instance_of(Spaceship::PortalClient).to receive(:teams).and_return([])
        expect(subject.team_name).to eq(nil)
      end
    end

    describe "csrf_tokens" do
      it "uses the stored token for all upcoming requests" do
        # Temporary stub a request to require the csrf_tokens
        stub_request(:post, 'https://developer.apple.com/services-account/QH65B2/account/ios/device/listDevices.action').
          with(body: { teamId: 'XXXXXXXXXX', pageSize: "10", pageNumber: "1", sort: 'name=asc', includeRemovedDevices: "false" }, headers: { 'csrf' => 'top_secret', 'csrf_ts' => '123123' }).
          to_return(status: 200, body: PortalStubbing.adp_read_fixture_file('listDevices.action.json'), headers: { 'Content-Type' => 'application/json' })

        # Hard code the tokens
        allow(subject).to receive(:csrf_tokens).and_return({ csrf: 'top_secret', csrf_ts: '123123' })
        allow(subject).to receive(:page_size).and_return(10) # to have a separate stubbing

        expect(subject.devices.count).to eq(4)
      end
    end

    describe '#apps' do
      let(:apps) { subject.apps }
      it 'returns a list of apps' do
        expect(apps).to be_instance_of(Array)
        expect(apps.first.keys).to eq(["appIdId", "name", "appIdPlatform", "prefix", "identifier", "isWildCard", "isDuplicate", "features", "enabledFeatures", "isDevPushEnabled", "isProdPushEnabled", "associatedApplicationGroupsCount", "associatedCloudContainersCount", "associatedIdentifiersCount"])
      end
    end

    describe '#app_groups' do
      let(:app_groups) { subject.app_groups }
      it 'returns a list of apps' do
        expect(app_groups).to be_instance_of(Array)
        expect(app_groups.first.keys).to eq(["name", "prefix", "identifier", "status", "applicationGroup"])
      end
    end

    describe "#team_information" do
      it 'returns all available information' do
        s = subject.team_information
        expect(s['status']).to eq('active')
        expect(s['type']).to eq('Company/Organization')
        expect(s['name']).to eq('SpaceShip')
      end
    end

    describe "#in_house?" do
      it 'returns false for normal accounts' do
        expect(subject.in_house?).to eq(false)
      end

      it 'returns true for enterprise accounts' do
        PortalStubbing.adp_stub_multiple_teams

        subject.team_id = 'SecondTeam'
        expect(subject.in_house?).to eq(true)
      end
    end

    describe '#create_app' do
      it 'should make a request create an explicit app id' do
        response = subject.create_app!(:explicit, 'Production App', 'tools.fastlane.spaceship.some-explicit-app')
        expect(response['isWildCard']).to eq(false)
        expect(response['name']).to eq('Production App')
        expect(response['identifier']).to eq('tools.fastlane.spaceship.some-explicit-app')
      end

      it 'should make a request create a wildcard app id' do
        response = subject.create_app!(:wildcard, 'Development App', 'tools.fastlane.spaceship.*')
        expect(response['isWildCard']).to eq(true)
        expect(response['name']).to eq('Development App')
        expect(response['identifier']).to eq('tools.fastlane.spaceship.*')
      end

      it 'should strip non ASCII characters' do
        response = subject.create_app!(:explicit, 'pp Test 1ed9e25c93ac7142ff9df53e7f80e84c', 'tools.fastlane.spaceship.some-explicit-app')
        expect(response['isWildCard']).to eq(false)
        expect(response['name']).to eq('pp Test 1ed9e25c93ac7142ff9df53e7f80e84c')
        expect(response['identifier']).to eq('tools.fastlane.spaceship.some-explicit-app')
      end

      it 'should make a request create an explicit app id with push feature' do
        payload = {}
        payload[Spaceship.app_service.push_notification.on.service_id] = Spaceship.app_service.push_notification.on
        response = subject.create_app!(:explicit, 'Production App', 'tools.fastlane.spaceship.some-explicit-app', enable_services: payload)
        expect(response['enabledFeatures']).to(include("push"))
        expect(response['identifier']).to eq('tools.fastlane.spaceship.some-explicit-app')
      end
    end

    describe '#delete_app!' do
      it 'should make a request to delete the app' do
        response = subject.delete_app!('LXD24VUE49')
        expect(response['resultCode']).to eq(0)
      end
    end

    describe '#create_app_group' do
      it 'should make a request create an app group' do
        response = subject.create_app_group!('Production App Group', 'group.tools.fastlane.spaceship')
        expect(response['name']).to eq('Production App Group')
        expect(response['identifier']).to eq('group.tools.fastlane')
      end
    end

    describe '#delete_app_group' do
      it 'should make a request to delete the app group' do
        response = subject.delete_app_group!('2GKKV64NUG')
        expect(response['resultCode']).to eq(0)
      end
    end

    describe "#paging" do
      it "default page size is correct" do
        expect(subject.page_size).to eq(500)
      end

      it "Properly pages if required with support for a custom page size" do
        allow(subject).to receive(:page_size).and_return(8)

        expect(subject.devices.count).to eq(9)
        expect(subject.devices.last['name']).to eq("The last phone")
      end
    end

    describe '#devices' do
      let(:devices) { subject.devices }
      it 'returns a list of device hashes' do
        expect(devices).to be_instance_of(Array)
        expect(devices.first.keys).to eq(["deviceId", "name", "deviceNumber", "devicePlatform", "status", "model", "deviceClass"])
      end
    end

    describe '#certificates' do
      let(:certificates) { subject.certificates(["5QPB9NHCEI"]) }
      it 'returns a list of certificates hashes' do
        expect(certificates).to be_instance_of(Array)
        expect(certificates.first.keys).to eq(
          %w(certRequestId name statusString dateRequestedString dateRequested
             dateCreated expirationDate expirationDateString ownerType ownerName
             ownerId canDownload canRevoke certificateId certificateStatusCode
             certRequestStatusCode certificateTypeDisplayId serialNum typeString)
        )
      end
    end

    describe "#create_device" do
      it "works as expected when the name is free" do
        device = subject.create_device!("Demo Device", "7f6c8dc83d77134b5a3a1c53f1202b395b04482b")
        expect(device['name']).to eq("Demo Device")
        expect(device['deviceNumber']).to eq("7f6c8dc83d77134b5a3a1c53f1202b395b04482b")
        expect(device['devicePlatform']).to eq('ios')
        expect(device['status']).to eq('c')
      end
    end

    describe '#provisioning_profiles' do
      it 'makes a call to the developer portal API' do
        profiles = subject.provisioning_profiles
        expect(profiles).to be_instance_of(Array)
        expect(profiles.sample.keys).to include("provisioningProfileId",
                                                "name",
                                                "status",
                                                "type",
                                                "distributionMethod",
                                                "proProPlatform",
                                                "version",
                                                "dateExpire",
                                                "managingApp",
                                                "deviceIds",
                                                "certificateIds")
        expect(a_request(:post, 'https://developer.apple.com/services-account/QH65B2/account/ios/profile/listProvisioningProfiles.action')).to have_been_made
      end
    end

    describe '#provisioning_profiles_via_xcode_api' do
      it 'makes a call to the developer portal API' do
        profiles = subject.provisioning_profiles_via_xcode_api
        expect(profiles).to be_instance_of(Array)
        expect(profiles.sample.keys).to include("provisioningProfileId",
                                                "name",
                                                "status",
                                                "type",
                                                "distributionMethod",
                                                "proProPlatform",
                                                "version",
                                                "dateExpire",
                                                # "managingApp", not all profiles have it
                                                "deviceIds",
                                                "appId",
                                                "certificateIds")
        expect(a_request(:post, /developerservices2\.apple\.com/)).to have_been_made
      end
    end

    describe "#create_provisioning_profile" do
      it "works when the name is free" do
        response = subject.create_provisioning_profile!("net.sunapps.106 limited", "limited", 'R9YNDTPLJX', ['C8DL7464RQ'], ['C8DLAAAARQ'])
        expect(response.keys).to include('name', 'status', 'type', 'appId', 'deviceIds')
        expect(response['distributionMethod']).to eq('limited')
      end

      it "works when the name is already taken" do
        error_text = 'Multiple profiles found with the name &#x27;Test Name 3&#x27;.  Please remove the duplicate profiles and try again.\nThere are no current certificates on this team matching the provided certificate IDs.' # not ", as this would convert the \n
        expect do
          response = subject.create_provisioning_profile!("taken", "limited", 'R9YNDTPLJX', ['C8DL7464RQ'], ['C8DLAAAARQ'])
        end.to raise_error(Spaceship::Client::UnexpectedResponse, error_text)
      end

      it "works when subplatform is null and mac is false" do
        response = subject.create_provisioning_profile!("net.sunapps.106 limited", "limited", 'R9YNDTPLJX', ['C8DL7464RQ'], ['C8DLAAAARQ'], mac: false, sub_platform: nil)
        expect(response.keys).to include('name', 'status', 'type', 'appId', 'deviceIds')
        expect(response['distributionMethod']).to eq('limited')
      end

      it "works when template name is specified" do
        template_name = 'Subscription Service iOS (dist)'
        response = subject.create_provisioning_profile!("net.sunapps.106 limited", "limited", 'R9YNDTPLJX', ['C8DL7464RQ'], [], mac: false, sub_platform: nil, template_name: template_name)
        expect(response.keys).to include('name', 'status', 'type', 'appId', 'deviceIds', 'template')
        expect(response['template']['purposeDisplayName']).to eq(template_name)
      end
    end

    describe '#delete_provisioning_profile!' do
      it 'makes a request to delete a provisioning profile' do
        response = subject.delete_provisioning_profile!('2MAY7NPHRU')
        expect(response['resultCode']).to eq(0)
      end
    end

    describe '#create_certificate' do
      let(:csr) { PortalStubbing.adp_read_fixture_file('certificateSigningRequest.certSigningRequest') }
      it 'makes a request to create a certificate' do
        response = subject.create_certificate!('BKLRAVXMGM', csr, '2HNR359G63')
        expect(response.keys).to include('certificateId', 'certificateType', 'statusString', 'expirationDate', 'certificate')
      end
    end

    describe '#revoke_certificate' do
      it 'makes a revoke request and returns the revoked certificate' do
        response = subject.revoke_certificate!('XC5PH8DAAA', 'R58UK2EAAA')
        expect(response.first.keys).to include('certificateId', 'certificateType', 'certificate')
      end
    end

    describe '#fetch_program_license_agreement_messages' do
      it 'makes a request to fetch all Program License Agreement warnings from Olympus' do
        # Stub the GET request that the method will make
        PortalStubbing.adp_stub_fetch_program_license_agreement_messages

        response = subject.fetch_program_license_agreement_messages

        # The method should make a GET request to this URL:
        expect(a_request(:get, 'https://appstoreconnect.apple.com/olympus/v1/contractMessages')).to have_been_made

        # The method should just return the "message" key's value(s) in an array.

        expected_first_message = "<b>Review the updated Paid Applications \
Schedule.</b><br />In order to update your existing apps, create \
new in-app purchases, and submit new apps to the App Store, the \
user with the Legal role (Team Agent) must review and accept the \
Paid Applications Schedule (Schedule 2 to the Apple Developer \
Program License Agreement) in the Agreements, Tax, and Banking \
module.<br /><br /> To accept this agreement, they must have \
already accepted the latest version of the Apple Developer \
Program License Agreement in their <a href=\"\
http://developer.apple.com/membercenter/index.action\">account on \
the developer website<a/>.<br />"

        expect(response.first).to eq(expected_first_message)
      end
    end
  end

  describe 'keys api' do
    let(:api_root) { 'https://developer.apple.com/services-account/QH65B2/account/auth/key' }
    before do
      MockAPI::DeveloperPortalServer.post('/services-account/QH65B2/account/auth/key/:action') do
        {
          keys: []
        }
      end
    end

    describe '#list_keys' do
      it 'lists keys' do
        subject.list_keys
        expect(WebMock).to have_requested(:post, api_root + '/list')
      end
    end

    describe '#get_key' do
      it 'gets a key' do
        subject.get_key(id: '123')
        expect(WebMock).to have_requested(:post, api_root + '/get')
      end
    end

    describe '#download_key' do
      it 'downloads a key' do
        MockAPI::DeveloperPortalServer.get('/services-account/QH65B2/account/auth/key/download') do
          '----- BEGIN PRIVATE KEY -----'
        end
        subject.download_key(id: '123')
        expect(WebMock).to have_requested(:get, api_root + '/download?keyId=123&teamId=XXXXXXXXXX')
      end
    end

    describe '#create_key!' do
      it 'creates a key' do
        subject.create_key!(name: 'some name', service_configs: [])
        expect(WebMock).to have_requested(:post, api_root + '/create')
      end
    end

    describe 'revoke_key!' do
      it 'revokes a key' do
        subject.revoke_key!(id: '123')
        expect(WebMock).to have_requested(:post, api_root + '/revoke')
      end
    end
  end

  describe 'merchant api' do
    let(:api_root) { 'https://developer.apple.com/services-account/QH65B2/account/ios/identifiers/' }
    before do
      MockAPI::DeveloperPortalServer.post('/services-account/QH65B2/account/ios/identifiers/:action') do
        {
          identifierList: [],
          omcId: []
        }
      end
    end

    describe '#merchants' do
      it 'lists merchants' do
        subject.merchants
        expect(WebMock).to have_requested(:post, api_root + 'listOMCs.action')
      end
    end

    describe '#create_merchant!' do
      it 'creates a merchant' do
        subject.create_merchant!('ExampleApp Production', 'merchant.com.example.app.production')
        expect(WebMock).to have_requested(:post, api_root + 'addOMC.action').with(body: { name: 'ExampleApp Production', identifier: 'merchant.com.example.app.production', teamId: 'XXXXXXXXXX' })
      end
    end

    describe '#delete_merchant!' do
      it 'deletes a merchant' do
        subject.delete_merchant!('LM3IY56BXC')
        expect(WebMock).to have_requested(:post, api_root + 'deleteOMC.action').with(body: { omcId: 'LM3IY56BXC', teamId: 'XXXXXXXXXX' })
      end
    end
  end
end
