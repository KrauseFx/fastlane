describe Spaceship::ConnectAPI::App do
  let(:mock_tunes_client) { double('tunes_client') }
  let(:username) { 'spaceship@krausefx.com' }
  let(:password) { 'so_secret' }

  before do
    allow(mock_tunes_client).to receive(:team_id).and_return("123")
    allow(mock_tunes_client).to receive(:select_team)
    allow(mock_tunes_client).to receive(:csrf_tokens)
    allow(Spaceship::TunesClient).to receive(:login).and_return(mock_tunes_client)
    Spaceship::ConnectAPI.login(username, password, use_portal: false, use_tunes: true)
  end

  describe '#Spaceship::ConnectAPI' do
    it '#get_apps' do
      response = Spaceship::ConnectAPI.get_apps
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(5)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::App)
      end

      model = response.first
      expect(model.id).to eq("123456789")
      expect(model.name).to eq("FastlaneTest")
      expect(model.bundle_id).to eq("com.joshholtz.FastlaneTest")
      expect(model.sku).to eq("SKU_SKU_SKU_SKU")
      expect(model.primary_locale).to eq("en-US")
      expect(model.removed).to eq(false)
      expect(model.is_aag).to eq(false)
    end

    it 'gets by app id' do
      response = Spaceship::ConnectAPI.get_app(app_id: "123456789")
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(1)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::App)
      end

      model = response.first
      expect(model.id).to eq("123456789")
      expect(model.bundle_id).to eq("com.joshholtz.FastlaneTest")
    end

    it '#get_review_submissions' do
      ConnectAPIStubbing::Tunes.stub_get_review_submissions

      response = Spaceship::ConnectAPI.get_review_submissions(app_id: "123456789-app")
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(2)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::ReviewSubmission)
      end

      model = response.first
      expect(model).to be_an_instance_of(Spaceship::ConnectAPI::ReviewSubmission)

      expect(model.id).to eq("123456789")
      expect(model.platform).to eq(Spaceship::ConnectAPI::Platform::IOS)
      expect(model.state).to eq(Spaceship::ConnectAPI::ReviewSubmission::ReviewSubmissionState::READY_FOR_REVIEW)
      expect(model.submitted_date).to be_nil
    end

    it '#post_review_submission' do
      ConnectAPIStubbing::Tunes.stub_create_review_submission

      response = Spaceship::ConnectAPI.post_review_submission(app_id: "123456789-app", platform: Spaceship::ConnectAPI::Platform::IOS)
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      model = response.first
      expect(model).to be_an_instance_of(Spaceship::ConnectAPI::ReviewSubmission)

      expect(model.id).to eq("123456789")
      expect(model.platform).to eq(Spaceship::ConnectAPI::Platform::IOS)
      expect(model.state).to eq(Spaceship::ConnectAPI::ReviewSubmission::ReviewSubmissionState::READY_FOR_REVIEW)
    end
  end

  describe "App object" do
    it 'finds app by bundle id' do
      model = Spaceship::ConnectAPI::App.find("com.joshholtz.FastlaneTest")
      expect(model.bundle_id).to eq("com.joshholtz.FastlaneTest")
    end

    it('fetches live app info') do
      ConnectAPIStubbing::Tunes.stub_get_app_infos
      app = Spaceship::ConnectAPI::App.new("123456789", [])

      info = app.fetch_live_app_info(includes: nil)
      expect(info.id).to eq("1111-11111")
      expect(info.app_store_age_rating).to eq("FOUR_PLUS")
      expect(info.app_store_state).to eq("READY_FOR_SALE")
      expect(info.state).to eq("READY_FOR_DISTRIBUTION")
    end

    it('fetches edit app info') do
      ConnectAPIStubbing::Tunes.stub_get_app_infos
      app = Spaceship::ConnectAPI::App.new("123456789", [])

      info = app.fetch_edit_app_info(includes: nil)
      expect(info.id).to eq("1111-2222")
      expect(info.app_store_age_rating).to eq("FOUR_PLUS")
      expect(info.app_store_state).to eq("PREPARE_FOR_SUBMISSION")
      expect(info.state).to eq("PREPARE_FOR_SUBMISSION")
    end

    it 'creates beta group' do
      app = Spaceship::ConnectAPI::App.find("com.joshholtz.FastlaneTest")

      model = app.create_beta_group(group_name: "Brand New Group", public_link_enabled: false, public_link_limit: 10_000, public_link_limit_enabled: false)
      expect(model.id).to eq("123456789")
      expect(model.is_internal_group).to eq(false)
      expect(model.has_access_to_all_builds).to be_nil

      # `has_access_to_all_builds` is ignored for external groups
      model = app.create_beta_group(group_name: "Brand New Group", public_link_enabled: false, public_link_limit: 10_000, public_link_limit_enabled: false, has_access_to_all_builds: true)
      expect(model.id).to eq("123456789")
      expect(model.is_internal_group).to eq(false)
      expect(model.has_access_to_all_builds).to be_nil

      # `has_access_to_all_builds` is set to `true` by default for internal groups
      model = app.create_beta_group(group_name: "Brand New Group", is_internal_group: true, public_link_enabled: false, public_link_limit: 10_000, public_link_limit_enabled: false)
      expect(model.id).to eq("123456789")
      expect(model.is_internal_group).to eq(true)
      expect(model.has_access_to_all_builds).to eq(true)

      # `has_access_to_all_builds` can be set to `false` for internal groups
      model = app.create_beta_group(group_name: "Brand New Group", is_internal_group: true, public_link_enabled: false, public_link_limit: 10_000, public_link_limit_enabled: false, has_access_to_all_builds: false)
      expect(model.id).to eq("123456789")
      expect(model.is_internal_group).to eq(true)
      expect(model.has_access_to_all_builds).to eq(false)
    end

    it '#get_review_submissions' do
      ConnectAPIStubbing::Tunes.stub_get_review_submissions

      app = Spaceship::ConnectAPI::App.new("123456789-app", [])

      review_submissions = app.get_review_submissions
      expect(review_submissions.count).to eq(2)
      expect(review_submissions.first.id).to eq("123456789")
    end

    it '#create_review_submission' do
      ConnectAPIStubbing::Tunes.stub_create_review_submission

      app = Spaceship::ConnectAPI::App.new("123456789-app", [])

      review_submission = app.create_review_submission(platform: Spaceship::ConnectAPI::Platform::IOS)

      expect(review_submission.id).to eq("123456789")
      expect(review_submission.platform).to eq(Spaceship::ConnectAPI::Platform::IOS)
      expect(review_submission.state).to eq(Spaceship::ConnectAPI::ReviewSubmission::ReviewSubmissionState::READY_FOR_REVIEW)
    end
  end

  describe("#get_app_availabilities") do
    it('gets app availabilities when app is ready for distribution') do
      ConnectAPIStubbing::Tunes.stub_get_app_availabilities_ready_for_distribution
      app = Spaceship::ConnectAPI::App.new("123456789", [])

      availabilities = app.get_app_availabilities

      expect(availabilities.availableInNewTerritories).to be(false)
      expect(availabilities.territory_availabilities.count).to eq(2)
      expect(availabilities.territory_availabilities[0].available).to be(true)
      expect(availabilities.territory_availabilities[1].available).to be(true)
      expect(availabilities.territory_availabilities[0].contentStatuses).to eq(["AVAILABLE"])
      expect(availabilities.territory_availabilities[1].contentStatuses).to eq(["AVAILABLE"])
    end

    it('gets app availabilities when app is removed from sale') do
      ConnectAPIStubbing::Tunes.stub_get_app_availabilities_removed_from_sale
      app = Spaceship::ConnectAPI::App.new("123456789", [])

      availabilities = app.get_app_availabilities

      expect(availabilities.availableInNewTerritories).to be(false)
      expect(availabilities.territory_availabilities.count).to eq(2)
      expect(availabilities.territory_availabilities[0].available).to be(false)
      expect(availabilities.territory_availabilities[1].available).to be(false)
      expect(availabilities.territory_availabilities[0].contentStatuses).to eq(["CANNOT_SELL"])
      expect(availabilities.territory_availabilities[1].contentStatuses).to eq(["CANNOT_SELL"])
    end
  end

  describe("Checks if app removed_from_sale?") do
    it('gets true when app has not been released (no READY_FOR_DISTRIBUTION app store versions)') do
      ConnectAPIStubbing::Tunes.stub_get_app_availabilities_removed_from_sale
      ConnectAPIStubbing::Tunes.stub_get_app_store_version_not_ready_for_distribution

      app = Spaceship::ConnectAPI::App.new("123456789", [])
      app_store_version = app.get_ready_for_distribution_app_store_version(includes: nil)

      expect(app_store_version).to be(nil)
      expect(app.removed_from_sale?).to be(true)
    end

    it('gets true when app is removed from sale') do
      ConnectAPIStubbing::Tunes.stub_get_app_availabilities_removed_from_sale
      ConnectAPIStubbing::Tunes.stub_get_app_store_version_ready_for_distribution

      app = Spaceship::ConnectAPI::App.new("123456789", [])
      app_store_version = app.get_ready_for_distribution_app_store_version(includes: nil)
      availabilities = app.get_app_availabilities

      expect(app_store_version.app_version_state).to eq("READY_FOR_DISTRIBUTION")

      expect(availabilities.territory_availabilities.count).to eq(2)
      expect(availabilities.territory_availabilities[0].available).to be(false)
      expect(availabilities.territory_availabilities[1].available).to be(false)

      expect(app.removed_from_sale?).to be(true)
    end

    it('gets false when app is ready for distribution in one territory') do
      ConnectAPIStubbing::Tunes.stub_get_app_availabilities_ready_for_distribution_one_territory
      ConnectAPIStubbing::Tunes.stub_get_app_store_version_ready_for_distribution

      app = Spaceship::ConnectAPI::App.new("123456789", [])
      app_store_version = app.get_ready_for_distribution_app_store_version(includes: nil)
      availabilities = app.get_app_availabilities

      expect(app_store_version.app_version_state).to eq("READY_FOR_DISTRIBUTION")

      expect(availabilities.territory_availabilities.count).to eq(2)
      expect(availabilities.territory_availabilities[0].available).to be(true)
      expect(availabilities.territory_availabilities[1].available).to be(false)

      expect(app.removed_from_sale?).to be(false)
    end

    it('gets false when app is ready for distribution in many territories') do
      ConnectAPIStubbing::Tunes.stub_get_app_availabilities_ready_for_distribution
      ConnectAPIStubbing::Tunes.stub_get_app_store_version_ready_for_distribution

      app = Spaceship::ConnectAPI::App.new("123456789", [])
      app_store_version = app.get_ready_for_distribution_app_store_version(includes: nil)
      availabilities = app.get_app_availabilities

      expect(app_store_version.app_version_state).to eq("READY_FOR_DISTRIBUTION")

      expect(availabilities.territory_availabilities.count).to eq(2)
      expect(availabilities.territory_availabilities[0].available).to be(true)
      expect(availabilities.territory_availabilities[1].available).to be(true)

      expect(app.removed_from_sale?).to be(false)
    end
  end
end
