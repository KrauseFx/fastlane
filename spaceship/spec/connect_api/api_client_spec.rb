describe Spaceship::ConnectAPI::APIClient do
  describe "#build_params" do
    let(:mock_token) { double('token') }
    let(:client) { Spaceship::ConnectAPI::APIClient.new(token: mock_token) }

    before(:each) do
      allow(mock_token).to receive(:text).and_return("ewfawef")
    end

    context 'build_params' do
      let(:path) { "betaAppReviewDetails" }
      let(:nil_filter) { { build: nil } }
      let(:one_filter) { { build: "123" } }
      let(:two_filters) { { build: "123", app: "321" } }
      let(:includes) { "model.attribute" }
      let(:limit) { "30" }
      let(:sort) { "asc" }

      it 'builds params with nothing' do
        params = client.build_params
        expect(params).to eq({})
      end

      it 'builds params with nil filter' do
        params = client.build_params(filter: nil_filter)
        expect(params).to eq({})
      end

      it 'builds params with one filter' do
        params = client.build_params(filter: one_filter)
        expect(params).to eq({
          filter: one_filter
        })
      end

      it 'builds params with two filters' do
        params = client.build_params(filter: two_filters)
        expect(params).to eq({
          filter: two_filters
        })
      end

      it 'builds params with includes' do
        params = client.build_params(includes: includes)
        expect(params).to eq({
          include: includes
        })
      end

      it 'builds params with limit' do
        params = client.build_params(limit: limit)
        expect(params).to eq({
          limit: limit
        })
      end

      it 'builds params with sort' do
        params = client.build_params(sort: sort)
        expect(params).to eq({
          sort: sort
        })
      end

      it 'builds params with one filter, includes, limit, and sort' do
        params = client.build_params(filter: one_filter, includes: includes, limit: limit, sort: sort)
        expect(params).to eq({
          filter: one_filter,
          include: includes,
          limit: limit,
          sort: sort
        })
      end
    end
  end

  describe "#request" do
    let(:mock_token) { double('token') }
    let(:client) { Spaceship::ConnectAPI::APIClient.new(token: mock_token) }

    let(:unauth_error) { Spaceship::Client::UnauthorizedAccessError.new }

    let(:default_body) { '{foo: "bar"}' }

    def stub_client_request(uri, status, body)
      stub_request(:get, uri).
        to_return(status: status, body: body, headers: { "Content-Type": "application/json" })
    end

    before(:each) do
      allow(mock_token).to receive(:text).and_return("ewfawef")
      allow(mock_token).to receive(:expired?).and_return(false)
    end

    it 'not raise on 200' do
      body = JSON.generate({ data: { hello: "world" } })
      stub_client_request(client.hostname, 200, body)

      client.get('')
    end

    it 'raise on 401' do
      body = JSON.generate({ errors: [] })
      stub_client_request(client.hostname, 401, body)

      expect do
        client.get('')
      end.to raise_error(Spaceship::UnauthorizedAccessError)
    end

    it 'raise on 403 with program license agreement updated' do
      body = JSON.generate({ errors: [{ code: "FORBIDDEN.REQUIRED_AGREEMENTS_MISSING_OR_EXPIRED" }] })
      stub_client_request(client.hostname, 403, body)

      expect do
        client.get('')
      end.to raise_error(Spaceship::ProgramLicenseAgreementUpdated)
    end

    it 'raise on 403' do
      body = JSON.generate({ errors: [] })
      stub_client_request(client.hostname, 403, body)

      expect do
        client.get('')
      end.to raise_error(Spaceship::AccessForbiddenError)
    end
  end
end
