describe Spaceship::DUClient, :du do
  before { Spaceship::Tunes.login }

  let(:client) { Spaceship::AppVersion.client }
  let(:app) { Spaceship::Application.all.find { |a| a.apple_id == "898536088" } }
  let(:contentProviderId) { "4321" }
  let(:ssoTokenForImage) { "sso token for image" }
  let(:version) { app.edit_version }

  subject { Spaceship::DUClient.new }

  before do
    allow(Spaceship::Utilities).to receive(:md5digest).and_return("FAKEMD5")
  end

  describe "#upload_large_icon and #upload_watch_icon" do
    let(:correct_jpg_image) { du_uploadimage_correct_jpg }
    let(:bad_png_image) { du_uploadimage_invalid_png }

    it "handles successful upload request using #upload_large_icon" do
      du_upload_large_image_success

      data = subject.upload_large_icon(version, correct_jpg_image, contentProviderId, ssoTokenForImage)
      expect(data['token']).to eq('Purple7/v4/65/04/4d/65044dae-15b0-a5e0-d021-5aa4162a03a3/pr_source.jpg')
    end

    it "handles failed upload request using #upload_watch_icon" do
      du_upload_watch_image_failure

      error_text = "[IMG_ALPHA_NOT_ALLOWED] Alpha is not allowed. Please edit the image to remove alpha and re-save it."
      expect do
        data = subject.upload_watch_icon(version, bad_png_image, contentProviderId, ssoTokenForImage)
      end.to raise_error(Spaceship::Client::UnexpectedResponse, error_text)
    end
  end

  describe "#upload_geojson" do
    let(:valid_geojson) { du_upload_valid_geojson }
    let(:invalid_geojson) { du_upload_invalid_geojson }

    it "handles successful upload request" do
      du_upload_geojson_success

      data = subject.upload_geojson(version, valid_geojson, contentProviderId, ssoTokenForImage)
      expect(data['token']).to eq('Purple1/v4/45/50/9d/45509d39-6a5d-7f55-f919-0fbc7436be61/pr_source.geojson')
      expect(data['dsId']).to eq(1_206_675_732)
      expect(data['type']).to eq('SMGameCenterAvatarImageType.SOURCE')
    end

    it "handles failed upload request" do
      du_upload_geojson_failure

      error_text = "[FILE_GEOJSON_FIELD_NOT_SUPPORTED] The routing app coverage file is in the wrong format. For more information, see the Location and Maps Programming Guide in the iOS Developer Library."
      expect do
        data = subject.upload_geojson(version, invalid_geojson, contentProviderId, ssoTokenForImage)
      end.to raise_error(Spaceship::Client::UnexpectedResponse, error_text)
    end
  end

  describe "#upload_screenshot" do
    # we voluntary skip tests for this method, it's mostly covered by other functions
  end

  # These tests were created when we migrated the mappings from several files
  # to `spaceship/lib/assets/displayFamilies.json`.
  # They make sure our logic to parse that file works as expected.
  describe "mapping migrations" do
    it "matches the picture_type_map prior to using DisplayFamily" do
      expect(subject.send(:picture_type_map).sort).to eq({
        ipad:         "MZPFT.SortedTabletScreenShot",
        ipad105:      "MZPFT.SortedJ207ScreenShot",
        ipadPro:      "MZPFT.SortedJ99ScreenShot",
        ipadPro11:    "MZPFT.SortedJ317ScreenShot",
        ipadPro129:   "MZPFT.SortedJ320ScreenShot",
        iphone35:     "MZPFT.SortedScreenShot",
        iphone4:      "MZPFT.SortedN41ScreenShot",
        iphone6:      "MZPFT.SortedN61ScreenShot",
        iphone6Plus:  "MZPFT.SortedN56ScreenShot",
        iphone58:     "MZPFT.SortedD22ScreenShot",
        iphone65:     "MZPFT.SortedD33ScreenShot",
        watch:        "MZPFT.SortedN27ScreenShot",
        watchSeries4: "MZPFT.SortedN131ScreenShot",
        appleTV:      "MZPFT.SortedATVScreenShot",
        desktop:      "MZPFT.SortedDesktopScreenShot"
      }.sort)
    end

    it "matches the messages_picture_type_map prior to using DisplayFamily" do
      expect(subject.send(:messages_picture_type_map).sort).to eq({
        ipad:         "MZPFT.SortedTabletMessagesScreenShot",
        ipad105:      "MZPFT.SortedJ207MessagesScreenShot",
        ipadPro:      "MZPFT.SortedJ99MessagesScreenShot",
        ipadPro11:    "MZPFT.SortedJ317MessagesScreenShot",
        ipadPro129:   "MZPFT.SortedJ320MessagesScreenShot",
        iphone4:      "MZPFT.SortedN41MessagesScreenShot",
        iphone6:      "MZPFT.SortedN61MessagesScreenShot",
        iphone6Plus:  "MZPFT.SortedN56MessagesScreenShot",
        iphone58:     "MZPFT.SortedD22MessagesScreenShot",
        iphone65:     "MZPFT.SortedD33MessagesScreenShot"
      }.sort)
    end

    it "matches the device_resolution_map prior to using DisplayFamily" do
      device_resolution_map = subject.send(:device_resolution_map)
      old_device_resolution_map = {
        watch:        [[312, 390]],
        watchSeries4: [[368, 448]],
        ipad:         [[1024, 748], [1024, 768], [2048, 1496], [2048, 1536], [768, 1004], [768, 1024], [1536, 2008], [1536, 2048]],
        ipad105:      [[1668, 2224], [2224, 1668]],
        ipadPro:      [[2048, 2732], [2732, 2048]],
        ipadPro11:    [[1668, 2388], [2388, 1668]],
        ipadPro129:   [[2048, 2732], [2064, 2752], [2732, 2048], [2752, 2064]],
        iphone35:     [[640, 960], [640, 920], [960, 600], [960, 640]],
        iphone4:      [[640, 1096], [640, 1136], [1136, 600], [1136, 640]],
        iphone6:      [[750, 1334], [1334, 750]],
        iphone6Plus:  [[1242, 2208], [2208, 1242]],
        iphone58:     [[1125, 2436], [2436, 1125]],
        iphone65:     [[1242, 2688], [2688, 1242]],
        appleTV:      [[1920, 1080], [3840, 2160]],
        desktop:      [[1280, 800], [1440, 900], [2560, 1600], [2880, 1800]]
      }

      expect(device_resolution_map.count).to eq(old_device_resolution_map.count)
      device_resolution_map.each do |k, v|
        expect(v.sort).to eq(old_device_resolution_map[k].sort)
      end
    end
  end
end
