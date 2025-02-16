require 'spec_helper'

describe Spaceship::Portal::Key do
  let(:mock_client) { double('MockClient') }

  before do
    Spaceship::Portal::Key.client = mock_client
  end

  describe '.all' do
    it 'uses the client to fetch all keys' do
      mock_client_response(:list_keys, with: no_args) do
        [
          {
            canDownload: false,
            canRevoke: true,
            keyId: "some-key-id",
            keyName: "Test Key via fastlane",
            servicesCount: 2
          },
          {
            canDownload: true,
            canRevoke: true,
            keyId: "B92NE4F7RG",
            keyName: "Test Key via browser",
            servicesCount: 2
          }
        ]
      end

      keys = Spaceship::Portal::Key.all
      expect(keys.size).to eq(2)
      expect(keys.sample).to be_instance_of(Spaceship::Portal::Key)
    end
  end

  describe '.find' do
    it 'uses the client to get a single key' do
      mock_client_response(:get_key) do
        {
          keyId: 'some-key-id'
        }
      end

      key = Spaceship::Portal::Key.find('some-key-id')
      expect(key).to be_instance_of(Spaceship::Portal::Key)
      expect(key.id).to eq('some-key-id')
    end
  end

  describe '.create' do
    it 'creates a key with the client' do
      expected_service_configs = {
        "U27F4V844T" => [],
        "DQ8HTZ7739" => [],
        "6A7HVUVQ3M" => ["some-music-id"],
        "APPLE_ID_AUTH_KEY_CONFIGURATION" => ["some-app-id"]
      }
      mock_client_response(:create_key!, with: { name: 'New Key', service_configs: expected_service_configs }) do
        {
          keyId: 'a-new-key-id'
        }
      end

      key = Spaceship::Portal::Key.create(name: 'New Key', apns: true, device_check: true, music_id: 'some-music-id', app_id: 'some-app-id')
      expect(key).to be_instance_of(Spaceship::Portal::Key)
      expect(key.id).to eq('a-new-key-id')
    end
  end

  describe 'instance methods' do
    let(:key_attributes) do # these keys are intentionally strings.
      {
        'canDownload' => false,
        'canRevoke' => true,
        'keyId' => 'some-key-id',
        'keyName' => 'fastlane',
        'servicesCount' => 3,
        'services' => [
          {
            'name' => 'APNS',
            'id' => 'U27F4V844T',
            'configurations' => []
          },
          {
            'name' => 'MusicKit',
            'id' => '6A7HVUVQ3M',
            'configurations' => [
              {
                'name' => 'music id test',
                'identifier' => 'music.com.snatchev.test',
                'type' => 'music',
                'prefix' => 'some-prefix-id',
                'id' => 'some-music-kit-id'
              }
            ]
          },
          {
            'name' => 'DeviceCheck',
            'id' => 'DQ8HTZ7739',
            'configurations' => []
          },
          {
            'name' => 'Sign In with Apple',
            'id' => 'APPLE_ID_AUTH_KEY_CONFIGURATION',
            'configurations' => [
              {
                'name' => 'Sign In with Apple test',
                'identifier' => 'sign.in.with.apple.test',
                'type' => 'bundle',
                'id' => 'some-auth-key-id'
              }
            ]
          }
        ]
      }
    end

    let(:key) { Spaceship::Portal::Key.new(key_attributes) }

    it 'should map attributes to methods' do
      expect(key.name).to eq('fastlane')
      expect(key.id).to eq('some-key-id')
    end

    it 'should have all of the services' do
      expect(key).to have_apns
      expect(key).to have_music_kit
      expect(key).to have_device_check
      expect(key).to have_apple_id_auth_key
    end

    it 'should have a way of getting the service configurations' do
      configs = key.service_configs_for(Spaceship::Portal::Key::MUSIC_KIT_ID)
      expect(configs).to be_instance_of(Array)
      expect(configs.sample).to be_instance_of(Hash)
      expect(configs.first['identifier']).to eq('music.com.snatchev.test')

      configs = key.service_configs_for(Spaceship::Portal::Key::APPLE_ID_AUTH_KEY)
      expect(configs).to be_instance_of(Array)
      expect(configs.sample).to be_instance_of(Hash)
      expect(configs.first['identifier']).to eq('sign.in.with.apple.test')
    end

    describe '#download' do
      it 'returns the p8 file' do
        mock_client_response(:download_key) do
          %{
-----BEGIN PRIVATE KEY-----
this is the encoded private key contents
-----END PRIVATE KEY-----
          }
        end
        p8_string = key.download
        expect(p8_string).to include('PRIVATE KEY')
      end
    end

    describe '#revoke!' do
      it 'revokes the key with the client' do
        mock_client_response(:revoke_key!)

        key.revoke!
      end
    end
  end
end
