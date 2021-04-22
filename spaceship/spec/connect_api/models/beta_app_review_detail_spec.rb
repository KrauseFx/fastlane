describe Spaceship::ConnectAPI::BetaAppReviewDetail do
  before { Spaceship::ConnectAPI.login }

  describe '#Spaceship::ConnectAPI' do
    it '#get_beta_app_review_detail' do
      response = Spaceship::ConnectAPI.get_beta_app_review_detail
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(1)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::BetaAppReviewDetail)
      end

      model = response.first
      expect(model.id).to eq("123456789")
      expect(model.contact_first_name).to eq("Connect")
      expect(model.contact_last_name).to eq("API")
      expect(model.contact_phone).to eq("5558674309")
      expect(model.contact_email).to eq("email@email.com")
      expect(model.demo_account_name).to eq("username")
      expect(model.demo_account_password).to eq("password")
      expect(model.demo_account_required).to eq(true)
      expect(model.notes).to eq("this is review notes")
    end
  end
end
