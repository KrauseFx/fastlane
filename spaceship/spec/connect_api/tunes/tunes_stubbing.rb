class ConnectAPIStubbing
  class Tunes
    class << self
      def read_fixture_file(filename)
        File.read(File.join('spaceship', 'spec', 'connect_api', 'fixtures', 'tunes', filename))
      end

      def read_binary_fixture_file(filename)
        File.binread(File.join('spaceship', 'spec', 'connect_api', 'fixtures', 'tunes', filename))
      end

      # Necessary, as we're now running this in a different context
      def stub_request(*args)
        WebMock::API.stub_request(*args)
      end

      def stub_get_app_availabilities_ready_for_distribution
        stub_request(:get, "https://appstoreconnect.apple.com/iris/v2/appAvailabilities/123456789?include=territoryAvailabilities&limit%5BterritoryAvailabilities%5D=200").
          to_return(status: 200, body: read_fixture_file('app_availabilities_ready_for_distribution.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_get_app_availabilities_ready_for_distribution_one_territory
        stub_request(:get, "https://appstoreconnect.apple.com/iris/v2/appAvailabilities/123456789?include=territoryAvailabilities&limit%5BterritoryAvailabilities%5D=200").
          to_return(status: 200, body: read_fixture_file('app_availabilities_ready_for_distribution_one_territory.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_get_app_availabilities_removed_from_sale
        stub_request(:get, "https://appstoreconnect.apple.com/iris/v2/appAvailabilities/123456789?include=territoryAvailabilities&limit%5BterritoryAvailabilities%5D=200").
          to_return(status: 200, body: read_fixture_file('app_availabilities_removed_app.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_get_app_store_version_ready_for_distribution
        stub_request(:get, "https://appstoreconnect.apple.com/iris/v1/apps/123456789/appStoreVersions?filter%5BappVersionState%5D=READY_FOR_DISTRIBUTION&filter%5Bplatform%5D=IOS").
          to_return(status: 200, body: read_fixture_file('app_store_versions_ready_for_distribution.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_get_app_store_version_not_ready_for_distribution
        stub_request(:get, "https://appstoreconnect.apple.com/iris/v1/apps/123456789/appStoreVersions?filter%5BappVersionState%5D=READY_FOR_DISTRIBUTION&filter%5Bplatform%5D=IOS").
          to_return(status: 200, body: read_fixture_file('app_store_versions_not_ready.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_get_app_infos
        stub_request(:get, "https://appstoreconnect.apple.com/iris/v1/apps/123456789/appInfos").
          to_return(status: 200, body: read_fixture_file('app_infos.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_app_store_version_release_request
        stub_request(:post, "https://appstoreconnect.apple.com/iris/v1/appStoreVersionReleaseRequests").
          to_return(status: 200, body: read_fixture_file('app_store_version_release_request.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_create_review_submission
        stub_request(:post, "https://appstoreconnect.apple.com/iris/v1/reviewSubmissions").
          to_return(status: 200, body: read_fixture_file('review_submission_created.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_cancel_review_submission
        stub_request(:patch, "https://appstoreconnect.apple.com/iris/v1/reviewSubmissions/123456789").
          with(body: { data: WebMock::API.hash_including({ attributes: { canceled: true } }) }).
          to_return(status: 200, body: read_fixture_file('review_submission_cancelled.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_get_review_submission
        stub_request(:get, "https://appstoreconnect.apple.com/iris/v1/reviewSubmissions/123456789").
          to_return(status: 200, body: read_fixture_file('review_submission.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_get_review_submissions
        stub_request(:get, "https://appstoreconnect.apple.com/iris/v1/apps/123456789-app/reviewSubmissions").
          to_return(status: 200, body: read_fixture_file('review_submissions.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_submit_review_submission
        stub_request(:patch, "https://appstoreconnect.apple.com/iris/v1/reviewSubmissions/123456789").
          with(body: { data: WebMock::API.hash_including({ attributes: { submitted: true } }) }).
          to_return(status: 200, body: read_fixture_file('review_submission_submitted.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_create_review_submission_item
        stub_request(:post, "https://appstoreconnect.apple.com/iris/v1/reviewSubmissionItems").
          to_return(status: 200, body: read_fixture_file('review_submission_item_created.json'), headers: { 'Content-Type' => 'application/json' })
      end

      def stub_get_review_submission_items
        stub_request(:get, "https://appstoreconnect.apple.com/iris/v1/reviewSubmissions/123456789/items").
          to_return(status: 200, body: read_fixture_file('review_submission_items.json'), headers: { 'Content-Type' => 'application/json' })
      end
    end
  end
end
