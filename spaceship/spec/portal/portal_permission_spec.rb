describe Spaceship::Portal do
  describe "InsufficientPermissions" do
    let(:username) { 'spaceship@krausefx.com' }
    let(:password) { 'so_secret' }
    before { Spaceship::Portal.login(username, password) }

    let(:certificate) { Spaceship::Certificate.all.first }

    it "raises an appropriate Developer Portal error when user doesn't have enough permission to do something" do
      stub_request(:get, "https://developer.apple.com/services-account/QH65B2/account/ios/certificate/downloadCertificateContent.action?certificateId=XC5PH8DAAA&teamId=XXXXXXXXXX&type=R58UK2EAAA").
        to_return(status: 200, body: '{
          "responseId": "d069deba-8d07-4aab-844f-72523bcb71a5",
          "resultCode": 1200,
          "resultString": "webservice.certificate.downloadNotAllowed",
          "userString": "You are not permitted to download this certificate.",
          "creationTimestamp": "2017-01-26T23:13:00Z",
          "requestUrl": "https://developer.apple.com/services-account/QH65B2/account/ios/certificate/downloadCertificateContent.action",
          "httpCode": 200
        }', headers: { 'Content-Type' => 'application/json' })

      expected_error_message = "User spaceship@krausefx.com (Team ID XXXXXXXXXX) doesn't have enough permission for the following action: download_certificate (You are not permitted to download this certificate.)"

      cert = Spaceship::Certificate.all.first
      expect do
        cert.download
      end.to raise_exception(Spaceship::Client::InsufficientPermissions, expected_error_message)
    end
  end
end
