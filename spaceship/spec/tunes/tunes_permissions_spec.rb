describe Spaceship::Tunes do
  describe "InsufficientPermissions" do
    include_examples "common spaceship login"
    let(:app) { Spaceship::Application.all.find { |a| a.apple_id == "898536088" } }

    it "raises an appropriate App Store Connect error when user doesn't have enough permission to do something" do
      stub_request(:post, "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/898536088/platforms/ios/versions/812106519").
        to_return(status: 200, body: '{
            "data": null,
            "messages": {
              "warn": null,
              "error": ["Forbidden"],
              "info": null
            },
            "statusCode": "ERROR"
          }', headers: { 'Content-Type' => 'application/json' })

      expected_error_message = if Gem::Version.create('3.4.0') <= Gem::Version.create(RUBY_VERSION)
                                 "User spaceship@krausefx.com doesn't have enough permission for the following action: Spaceship::TunesClient#update_app_version"
                               else
                                 "User spaceship@krausefx.com doesn't have enough permission for the following action: update_app_version"
                               end

      e = app.edit_version
      expect(e.description["German"]).to eq("My title")
      e.description["German"] = "Something new"

      begin
        e.save!
      rescue Spaceship::Client::InsufficientPermissions => ex
        expect(ex.to_s).to include(expected_error_message)
      end
    end
  end
end
