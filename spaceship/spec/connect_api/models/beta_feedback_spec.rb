describe Spaceship::ConnectAPI::BetaFeedback do
  before { Spaceship::ConnectAPI.login }

  describe '#Spaceship::ConnectAPI' do
    it '#get_beta_feedback' do
      response = Spaceship::ConnectAPI.get_beta_feedback
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(1)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::BetaFeedback)
      end

      model = response.first
      expect(model.id).to eq("987654321")
      expect(model.timestamp).to eq("2019-12-11T02:03:27.661Z")
      expect(model.comment).to eq("Oohhhhh feedback!!!!")
      expect(model.email_address).to eq("email@email.com")
      expect(model.device_model).to eq("iPhone11_2")
      expect(model.os_version).to eq("13.2.3")
      expect(model.bookmarked).to eq(false)
      expect(model.locale).to eq("en-US")
      expect(model.carrier).to eq("T-Mobile")
      expect(model.timezone).to eq("America/Chicago")
      expect(model.architecture).to eq("arm64e")
      expect(model.connection_status).to eq("WIFI")
      expect(model.paired_apple_watch).to eq(nil)
      expect(model.app_up_time_millis).to eq(nil)
      expect(model.available_disk_bytes).to eq("13388951552")
      expect(model.total_disk_bytes).to eq("63937040384")
      expect(model.network_type).to eq("LTE")
      expect(model.battery_percentage).to eq(83)
      expect(model.screen_width).to eq(375)
      expect(model.screen_height).to eq(812)

      expect(model.build).to_not(eq(nil))
      expect(model.build.version).to eq("1571678363")

      expect(model.tester).to_not(eq(nil))
      expect(model.tester.first_name).to eq("Josh")

      expect(model.screenshots.size).to eq(1)
      expect(model.screenshots.first.image_assets.size).to eq(4)
      expect(model.screenshots.first.image_assets.first["url"]).to eq("https://tf-feedback.itunes.apple.com/eimg/D_g/HQ8/C4k/CPY/Ezw/ultR3bzSGG0/original.jpg?i_for=974055077&AWSAccessKeyId=MKIA9C0TVRX1ZL0VZ1YK&Expires=1576454400&Signature=NtYpXsRVKPeQNpg7eLh2xKFnmF4%3D&p_sig=8DAxqgHRlxMlhbl_LKW5EDAIAwo")
      expect(model.screenshots.first.image_assets.first["width"]).to eq(3024)
      expect(model.screenshots.first.image_assets.first["height"]).to eq(4032)
    end
  end

  it "deletes a feedback" do
    response = Spaceship::ConnectAPI.get_beta_feedback
    feedback = response.first
    expect(Spaceship::ConnectAPI).to receive(:delete_beta_feedback).with(feedback_id: feedback.id)
    feedback.delete!
  end
end
