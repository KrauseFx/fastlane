describe Spaceship::ConnectAPI::Tunes::Client do
  let(:mock_tunes_client) { double('tunes_client') }
  let(:client) { Spaceship::ConnectAPI::Tunes::Client.new(another_client: mock_tunes_client) }
  let(:hostname) { Spaceship::ConnectAPI::Tunes::Client.hostname }
  let(:username) { 'spaceship@krausefx.com' }
  let(:password) { 'so_secret' }

  before do
    allow(mock_tunes_client).to receive(:team_id).and_return("123")
    allow(mock_tunes_client).to receive(:select_team)
    allow(mock_tunes_client).to receive(:csrf_tokens)
    allow(Spaceship::TunesClient).to receive(:login).and_return(mock_tunes_client)
    Spaceship::ConnectAPI.login(username, password, use_portal: false, use_tunes: true)
  end

  context 'sends api request' do
    before(:each) do
      allow(client).to receive(:handle_response)
    end

    def test_request_params(url, params)
      req_mock = double
      options_mock = double

      allow(req_mock).to receive(:headers).and_return({})

      expect(req_mock).to receive(:url).with(url)
      expect(req_mock).to receive(:params=).with(params)
      expect(req_mock).to receive(:options).and_return(options_mock)
      expect(options_mock).to receive(:params_encoder=).with(Faraday::NestedParamsEncoder)
      allow(req_mock).to receive(:status)

      return req_mock
    end

    def test_request_body(url, body)
      req_mock = double
      header_mock = double
      expect(req_mock).to receive(:url).with(url)
      expect(req_mock).to receive(:body=).with(JSON.generate(body))
      expect(req_mock).to receive(:headers).and_return(header_mock)
      expect(header_mock).to receive(:[]=).with("Content-Type", "application/json")
      allow(req_mock).to receive(:status)

      return req_mock
    end

    describe "appAvailabilities" do
      context 'get_app_availabilities' do
        let(:path) { "v2/appAvailabilities" }
        let(:app_id) { "123" }

        it 'succeeds' do
          url = "#{path}/#{app_id}"
          params = {
            include: "territoryAvailabilities",
            limit: { "territoryAvailabilities": 200 }
          }
          req_mock = test_request_params(url, params)
          expect(client).to receive(:request).with(:get).and_yield(req_mock).and_return(req_mock)
          client.get_app_availabilities(app_id: app_id, includes: "territoryAvailabilities", limit: { "territoryAvailabilities": 200 })
        end
      end
    end

    describe "appStoreVersionReleaseRequests" do
      context 'post_app_store_version_release_request' do
        let(:path) { "v1/appStoreVersionReleaseRequests" }
        let(:app_store_version_id) { "123" }
        let(:body) do
          {
            data: {
              type: "appStoreVersionReleaseRequests",
              relationships: {
                appStoreVersion: {
                  data: {
                    type: "appStoreVersions",
                    id: app_store_version_id
                  }
                }
              }
            }
          }
        end

        it 'succeeds' do
          url = path
          req_mock = test_request_body(url, body)

          expect(client).to receive(:request).with(:post).and_yield(req_mock).and_return(req_mock)
          client.post_app_store_version_release_request(app_store_version_id: app_store_version_id)
        end
      end
    end

    describe "territories" do
      context 'get_territories' do
        let(:path) { "v1/territories" }

        it 'succeeds' do
          params = {}
          req_mock = test_request_params(path, params)
          expect(client).to receive(:request).with(:get).and_yield(req_mock).and_return(req_mock)
          client.get_territories
        end
      end
    end

    describe "reviewSubmissions" do
      context 'get_review_submissions' do
        let(:app_id) { "123456789-app" }
        let(:path) { "v1/apps/#{app_id}/reviewSubmissions" }

        it 'succeeds' do
          params = {}
          req_mock = test_request_params(path, params)
          expect(client).to receive(:request).with(:get).and_yield(req_mock).and_return(req_mock)
          client.get_review_submissions(app_id: app_id)
        end
      end

      context 'get_review_submission' do
        let(:review_submission_id) { "123456789" }
        let(:path) { "v1/reviewSubmissions/#{review_submission_id}" }

        it 'succeeds' do
          params = {}
          req_mock = test_request_params(path, params)
          expect(client).to receive(:request).with(:get).and_yield(req_mock).and_return(req_mock)
          client.get_review_submission(review_submission_id: review_submission_id)
        end
      end

      context 'post_review_submission' do
        let(:app_id) { "123456789-app" }
        let(:platform) { Spaceship::ConnectAPI::Platform::IOS }
        let(:path) { "v1/reviewSubmissions" }
        let(:body) do
          {
            data: {
              type: "reviewSubmissions",
              attributes: {
                platform: platform
              },
              relationships: {
                app: {
                  data: {
                    type: "apps",
                    id: app_id
                  }
                }
              }
            }
          }
        end

        it 'succeeds' do
          url = path
          req_mock = test_request_body(url, body)

          expect(client).to receive(:request).with(:post).and_yield(req_mock).and_return(req_mock)
          client.post_review_submission(app_id: app_id, platform: platform)
        end
      end

      context 'patch_review_submission' do
        let(:review_submission_id) { "123456789" }
        let(:attributes) { { submitted: true } }
        let(:path) { "v1/reviewSubmissions/#{review_submission_id}" }
        let(:body) do
          {
            data: {
              type: "reviewSubmissions",
              id: review_submission_id,
              attributes: attributes
            }
          }
        end

        it 'succeeds' do
          url = path
          req_mock = test_request_body(url, body)

          expect(client).to receive(:request).with(:patch).and_yield(req_mock).and_return(req_mock)
          client.patch_review_submission(review_submission_id: review_submission_id, attributes: attributes)
        end
      end
    end

    describe "reviewSubmissionItems" do
      context 'get_review_submission_items' do
        let(:review_submission_id) { "123456789" }
        let(:path) { "v1/reviewSubmissions/#{review_submission_id}/items" }

        it 'succeeds' do
          params = {}
          req_mock = test_request_params(path, params)
          expect(client).to receive(:request).with(:get).and_yield(req_mock).and_return(req_mock)
          client.get_review_submission_items(review_submission_id: review_submission_id)
        end
      end

      context 'post_review_submission_item' do
        let(:review_submission_id) { "123456789" }
        let(:app_store_version_id) { "123456789-app-store-version" }
        let(:path) { "v1/reviewSubmissionItems" }
        let(:body) do
          {
            data: {
              type: "reviewSubmissionItems",
              relationships: {
                reviewSubmission: {
                  data: {
                    type: "reviewSubmissions",
                    id: review_submission_id
                  }
                },
                appStoreVersion: {
                  data: {
                    type: "appStoreVersions",
                    id: app_store_version_id
                  }
                }
              }
            }
          }
        end

        it 'succeeds' do
          url = path
          req_mock = test_request_body(url, body)

          expect(client).to receive(:request).with(:post).and_yield(req_mock).and_return(req_mock)
          client.post_review_submission_item(review_submission_id: review_submission_id, app_store_version_id: app_store_version_id)
        end
      end
    end
  end
end
