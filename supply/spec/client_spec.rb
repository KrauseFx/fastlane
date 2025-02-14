describe Supply do
  describe Supply::Client do
    let(:service_account_file) { File.read(fixture_file("sample-service-account.json")) }
    before do
      stub_request(:post, "https://www.googleapis.com/oauth2/v4/token").
        to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/test-app/edits").
        to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    end

    describe "displays error messages from the API" do
      it "with no retries" do
        stub_request(:post, "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/test-app/edits/1/listings/en-US/icon").
          to_return(status: 403, body: '{"error":{"message":"Ensure project settings are enabled."}}', headers: { 'Content-Type' => 'application/json' })

        current_edit = double
        allow(current_edit).to receive(:id).and_return(1)

        client = Supply::Client.new(service_account_json: StringIO.new(service_account_file), params: { timeout: 1 })
        allow(client).to receive(:ensure_active_edit!)
        allow(client).to receive(:current_edit).and_return(current_edit)

        client.begin_edit(package_name: 'test-app')
        expect {
          client.upload_image(image_path: fixture_file("playstore-icon.png"),
                              image_type: "icon",
                                language: "en-US")
        }.to raise_error(FastlaneCore::Interface::FastlaneError, "Google Api Error: Invalid request - Ensure project settings are enabled.")
      end

      it "with 5 retries" do
        stub_const("ENV", { 'SUPPLY_UPLOAD_MAX_RETRIES' => 5 })

        stub_request(:post, "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/test-app/edits/1/listings/en-US/icon").
          to_return(status: 403, body: '{"error":{"message":"Ensure project settings are enabled."}}', headers: { 'Content-Type' => 'application/json' })

        expect(UI).to receive(:error).with("Google Api Error: Invalid request - Ensure project settings are enabled. - Retrying...").exactly(5).times

        current_edit = double
        allow(current_edit).to receive(:id).and_return(1)

        client = Supply::Client.new(service_account_json: StringIO.new(service_account_file), params: { timeout: 1 })
        allow(client).to receive(:ensure_active_edit!)
        allow(client).to receive(:current_edit).and_return(current_edit)

        client.begin_edit(package_name: 'test-app')
        expect {
          client.upload_image(image_path: fixture_file("playstore-icon.png"),
                              image_type: "icon",
                                language: "en-US")
        }.to raise_error(FastlaneCore::Interface::FastlaneError, "Google Api Error: Invalid request - Ensure project settings are enabled.")
      end
    end

    describe "AndroidPublisher" do
      let(:subject) { AndroidPublisher::AndroidPublisherService.new }

      # Verify that the Google API client has all the expected methods we use.
      it "has all the expected Google API methods" do
        expect(subject.class.method_defined?(:insert_edit)).to eq(true)
        expect(subject.class.method_defined?(:delete_edit)).to eq(true)
        expect(subject.class.method_defined?(:validate_edit)).to eq(true)
        expect(subject.class.method_defined?(:commit_edit)).to eq(true)
        expect(subject.class.method_defined?(:list_edit_listings)).to eq(true)
        expect(subject.class.method_defined?(:get_edit_listing)).to eq(true)
        expect(subject.class.method_defined?(:list_edit_apks)).to eq(true)
        expect(subject.class.method_defined?(:list_edit_bundles)).to eq(true)
        expect(subject.class.method_defined?(:list_generatedapks)).to eq(true)
        expect(subject.class.method_defined?(:download_generatedapk)).to eq(true)
        expect(subject.class.method_defined?(:update_edit_listing)).to eq(true)
        expect(subject.class.method_defined?(:upload_edit_apk)).to eq(true)
        expect(subject.class.method_defined?(:upload_edit_deobfuscationfile)).to eq(true)
        expect(subject.class.method_defined?(:upload_edit_bundle)).to eq(true)
        expect(subject.class.method_defined?(:list_edit_tracks)).to eq(true)
        expect(subject.class.method_defined?(:update_edit_track)).to eq(true)
        expect(subject.class.method_defined?(:get_edit_track)).to eq(true)
        expect(subject.class.method_defined?(:update_edit_track)).to eq(true)
        expect(subject.class.method_defined?(:update_edit_expansionfile)).to eq(true)
        expect(subject.class.method_defined?(:list_edit_images)).to eq(true)
        expect(subject.class.method_defined?(:upload_edit_image)).to eq(true)
        expect(subject.class.method_defined?(:deleteall_edit_image)).to eq(true)
        expect(subject.class.method_defined?(:delete_edit_image)).to eq(true)
        expect(subject.class.method_defined?(:upload_edit_expansionfile)).to eq(true)
        expect(subject.class.method_defined?(:uploadapk_internalappsharingartifact)).to eq(true)
        expect(subject.class.method_defined?(:uploadbundle_internalappsharingartifact)).to eq(true)
      end
    end

    describe 'uses external account' do
      let(:service_account_json) { File.open(fixture_file('sample-external-account.json')) }
      let(:fake_credential) { double("tester credential") }
      before do
        allow(Google::Auth::ExternalAccount::Credentials).to receive(:make_creds).and_return(fake_credential)
        allow(fake_credential).to receive(:fetch_access_token!)
      end

      context 'json_key is used' do
        it 'should use Google::Auth::ExternalAccount::Credentials' do
          client = Supply::Client.new(service_account_json: service_account_json, params: { timeout: 1 })

          expect(Google::Auth::ExternalAccount::Credentials).to have_received(:make_creds) do |arg|
            expect(arg[:json_key_io].string).to eq(File.read(fixture_file('sample-external-account.json')))
            expect(arg[:scope]).to eq('https://www.googleapis.com/auth/androidpublisher')
          end

          expect(fake_credential).to have_received(:fetch_access_token!).once
        end
      end

      context 'json_key_data is used' do
        it 'should use Google::Auth::ExternalAccount::Credentials' do
          client = Supply::Client.new(service_account_json: StringIO.new(File.read(fixture_file('sample-external-account.json'))), params: { timeout: 1 })

          expect(Google::Auth::ExternalAccount::Credentials).to have_received(:make_creds) do |arg|
            expect(arg[:json_key_io].string).to eq(File.read(fixture_file('sample-external-account.json')))
            expect(arg[:scope]).to eq('https://www.googleapis.com/auth/androidpublisher')
          end

          expect(fake_credential).to have_received(:fetch_access_token!).once
        end
      end
    end
  end
end
