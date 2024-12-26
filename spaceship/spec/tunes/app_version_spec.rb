describe Spaceship::AppVersion, all: true do
  include_examples "common spaceship login"

  let(:client) { Spaceship::AppVersion.client }
  let(:app) { Spaceship::Application.all.find { |a| a.apple_id == "898536088" } }

  describe "successfully loads and parses the app version" do
    it "inspect works" do
      expect(app.edit_version.inspect).to include("Tunes::AppVersion")
    end

    it "parses the basic version details correctly" do
      version = app.edit_version

      expect(version.application).to eq(app)
      expect(version.is_live?).to eq(false)
      expect(version.current_build_number).to eq("9")
      expect(version.copyright).to eq("2015 SunApps GmbH")
      expect(version.version_id).to eq(812_106_519)
      expect(version.raw_status).to eq('readyForSale')
      expect(version.can_reject_version).to eq(false)
      expect(version.can_prepare_for_upload).to eq(false)
      expect(version.can_send_version_live).to eq(false)
      expect(version.release_on_approval).to eq(true)
      expect(version.auto_release_date).to eq(nil)
      expect(version.ratings_reset).to eq(false)
      expect(version.can_beta_test).to eq(true)
      expect(version.version).to eq('0.9.13')
      expect(version.supports_apple_watch).to eq(false)
      expect(version.large_app_icon.url).to eq('https://is1-ssl.mzstatic.com/image/thumb/Purple3/v4/02/88/4d/02884d3d-92ea-5e6a-2a7b-b19da39f73a6/pr_source.png/0x0ss.jpg')
      expect(version.large_app_icon.original_file_name).to eq('AppIconFull.png')
      expect(version.watch_app_icon.url).to eq('https://is1-ssl.mzstatic.com/image/thumb//0x0ss.jpg')
      expect(version.watch_app_icon.original_file_name).to eq('OriginalName.png')
      expect(version.transit_app_file).to eq(nil)
      expect(version.platform).to eq("ios")
    end

    it "parses the localized values correctly" do
      version = app.edit_version

      expect(version.description['English']).to eq('Super Description here')
      expect(version.description['German']).to eq('My title')
      expect(version.keywords['English']).to eq('Some random titles')
      expect(version.keywords['German']).to eq('More random stuff')
      expect(version.support_url['German']).to eq('http://url.com')
      expect(version.release_notes['German']).to eq('Wow, News')
      expect(version.release_notes['English']).to eq('Also News')

      expect(version.description.keys).to eq(version.description.languages)
      expect(version.description.keys).to eq(["German", "English"])
    end

    it "parses the review information correctly" do
      version = app.edit_version

      expect(version.review_first_name).to eq('Felix')
      expect(version.review_last_name).to eq('Krause')
      expect(version.review_phone_number).to eq('+4123123123')
      expect(version.review_email).to eq('felix@sunapps.net')
      expect(version.review_demo_user).to eq('MyUser@gmail.com')
      expect(version.review_user_needed).to eq(true)
      expect(version.review_demo_password).to eq('SuchPass')
      expect(version.review_notes).to eq('Such Notes here')
    end

    describe "supports setting of the app rating" do
      before do
        @v = app.edit_version

        @v.update_rating({
          'CARTOON_FANTASY_VIOLENCE' => 1,
          'MATURE_SUGGESTIVE' => 2,
          'GAMBLING' => 0,
          'UNRESTRICTED_WEB_ACCESS' => 1,
          'GAMBLING_CONTESTS' => 0
        })
      end

      it "infrequent_mild" do
        val = @v.raw_data['ratings']['nonBooleanDescriptors'].find do |a|
          a['name'].include?('CARTOON_FANTASY_VIOLENCE')
        end
        expect(val['level']).to eq("ITC.apps.ratings.level.INFREQUENT_MILD")
      end

      it "infrequent_mild" do
        val = @v.raw_data['ratings']['nonBooleanDescriptors'].find do |a|
          a['name'].include?('CARTOON_FANTASY_VIOLENCE')
        end
        expect(val['level']).to eq("ITC.apps.ratings.level.INFREQUENT_MILD")
      end

      it "none" do
        val = @v.raw_data['ratings']['nonBooleanDescriptors'].find do |a|
          a['name'].include?('GAMBLING')
        end
        expect(val['level']).to eq("ITC.apps.ratings.level.NONE")
      end

      it "boolean true" do
        val = @v.raw_data['ratings']['booleanDescriptors'].find do |a|
          a['name'].include?('UNRESTRICTED_WEB_ACCESS')
        end
        expect(val['level']).to eq("ITC.apps.ratings.level.YES")
      end

      it "boolean false" do
        val = @v.raw_data['ratings']['booleanDescriptors'].find do |a|
          a['name'].include?('GAMBLING_CONTESTS')
        end
        expect(val['level']).to eq("ITC.apps.ratings.level.NO")
      end
    end

    describe "#candidate_builds" do
      it "properly fetches and parses all builds ready to be deployed" do
        version = app.edit_version
        res = version.candidate_builds
        build = res.first
        expect(build.build_version).to eq("9")
        expect(build.train_version).to eq("1.1")
        expect(build.icon_url).to eq("https://is5-ssl.mzstatic.com/image/thumb/Newsstand3/v4/70/6a/7f/706a7f53-bac9-0a43-eb07-9f2cbb9a7d71/Icon-76@2x.png.png/150x150bb-80.png")
        expect(build.upload_date).to eq(1_443_150_586_000)
        expect(build.processing).to eq(false)
        expect(build.apple_id).to eq("898536088")
      end

      it "allows choosing of the build for the version to submit" do
        version = app.edit_version
        build = version.candidate_builds.first

        version.select_build(build)
        expect(version.raw_data['preReleaseBuildVersionString']['value']).to eq("9")
        expect(version.raw_data['preReleaseBuildTrainVersionString']).to eq("1.1")
        expect(version.raw_data['preReleaseBuildUploadDate']).to eq(1_443_150_586_000)
      end
    end

    describe "release an app version" do
      it "allows release the edit version" do
        version = app.edit_version

        version.raw_status = 'pendingDeveloperRelease'

        status = version.release!
        # Note right now we don't really update the raw_data after the release
        expect(version.raw_status).to eq('pendingDeveloperRelease')
      end
    end

    describe "release an app version in phased release to all users" do
      it "allows releasing the live version to all users" do
        version = app.live_version

        version.raw_status = 'readyForSale'

        status = version.release_to_all_users!

        expect(version.raw_status).to eq('readyForSale')
      end
    end

    describe "#url" do
      it "live version" do
        expect(app.live_version.url).to eq("https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/ng/app/#{app.apple_id}/#{app.platform}/versioninfo/deliverable")
      end

      it "edit version" do
        expect(app.edit_version.url).to eq("https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/ng/app/#{app.apple_id}/#{app.platform}/versioninfo/")
      end
    end

    describe "App Status" do
      it "parses readyForSale" do
        version = app.live_version

        expect(version.app_status).to eq("Ready for Sale")
        expect(version.current_build_number).to eq("9")
        expect(version.app_status).to eq(Spaceship::Tunes::AppStatus::READY_FOR_SALE)
      end

      it "parses prepareForUpload" do
        expect(Spaceship::Tunes::AppStatus.get_from_string('prepareForUpload')).to eq(Spaceship::Tunes::AppStatus::PREPARE_FOR_SUBMISSION)
      end

      it "parses rejected" do
        expect(Spaceship::Tunes::AppStatus.get_from_string('rejected')).to eq(Spaceship::Tunes::AppStatus::REJECTED)
      end

      it "parses pendingDeveloperRelease" do
        expect(Spaceship::Tunes::AppStatus.get_from_string('pendingDeveloperRelease')).to eq(Spaceship::Tunes::AppStatus::PENDING_DEVELOPER_RELEASE)
      end

      it "parses metadataRejected" do
        expect(Spaceship::Tunes::AppStatus.get_from_string('metadataRejected')).to eq(Spaceship::Tunes::AppStatus::METADATA_REJECTED)
      end

      it "parses removedFromSale" do
        expect(Spaceship::Tunes::AppStatus.get_from_string('removedFromSale')).to eq(Spaceship::Tunes::AppStatus::REMOVED_FROM_SALE)
      end
    end

    describe "Screenshots" do
      it "properly parses all the screenshots" do
        v = app.live_version

        # This app only has screenshots in the English version
        expect(v.screenshots['German']).to eq([])

        s1 = v.screenshots["English"].first
        expect(s1.device_type).to eq('iphone4')
        expect(s1.url).to eq('https://is1-ssl.mzstatic.com/image/thumb/Purple62/v4/4f/26/50/4f265065-b11d-857b-6232-d219ad4791d2/pr_source.png/0x0ss.jpg')
        expect(s1.sort_order).to eq(1)
        expect(s1.original_file_name).to eq('ftl_250ec6b31ba0da4c4e8e22fdf83d71a1_65ea94f6b362563260a5742b93659729.png')
        expect(s1.language).to eq("English")

        expect(v.screenshots["English"].count).to eq(13)

        # 2 iPhone 6 Plus Screenshots
        expect(v.screenshots["English"].count { |s| s.device_type == 'iphone6Plus' }).to eq(3)
      end
    end

    # describe "AppTrailers", :trailers do
    #   it "properly parses all the trailers" do
    #     v = app.live_version

    #     # This app only has screenshots in the English version
    #     expect(v.trailers["German"]).to eq([])

    #     s1 = v.trailers["English"].first
    #     expect(s1.device_type).to eq("ipad")
    #     expect(s1.language).to eq("English")

    #     expect(s1.preview_frame_time_code).to eq("00:05")
    #     expect(s1.is_portrait).to eq(false)

    #     expect(v.trailers["English"].count).to eq(1)

    #     expect(v.trailers["English"].count { |s| s.device_type == "iphone6Plus" }).to eq(0)
    #   end
    # end
  end

  describe "Modifying the app version" do
    let(:version) { app.edit_version }

    it "doesn't allow modification of localized properties without the language" do
      begin
        version.description = "Yes"
        raise "Should raise exception before"
      rescue NoMethodError => ex
        expected_message = if Gem::Version.create('3.4.0') <= Gem::Version.create(RUBY_VERSION)
                             "undefined method 'description='"
                           else
                             "undefined method `description='"
                           end
        expect(ex.to_s).to include(expected_message)
      end
    end

    describe "Modifying the app large and watch icon", :du do
      before do
        allow(Spaceship::UploadFile).to receive(:from_path) do |path|
          du_uploadimage_correct_jpg if path == "path_to_jpg"
        end

        json = JSON.parse(du_read_fixture_file("upload_image_success.json"))
        allow(client.du_client).to receive(:upload_large_icon).and_return(json)
        allow(client.du_client).to receive(:upload_watch_icon).and_return(json)
      end

      it "stores extra information in the raw_data" do
        version.upload_large_icon!("path_to_jpg")
        expect(version.raw_data["largeAppIcon"]["value"]).to eq({
          assetToken: "Purple7/v4/65/04/4d/65044dae-15b0-a5e0-d021-5aa4162a03a3/pr_source.jpg",
          originalFileName: "ftl_FAKEMD5_icon1024.jpg",
           size: 198_508,
           height: 1024,
           width: 1024,
           checksum: "d41d8cd98f00b204e9800998ecf8427e"
           })
      end

      it "deletes the large app data" do
        version.upload_large_icon!(nil)
        expect(version.large_app_icon.url).to eq(nil)
        expect(version.large_app_icon.original_file_name).to eq(nil)
        expect(version.large_app_icon.asset_token).to eq(nil)
      end

      it "deletes the watch app data" do
        version.upload_watch_icon!(nil)
        expect(version.watch_app_icon.url).to eq(nil)
        expect(version.watch_app_icon.original_file_name).to eq(nil)
        expect(version.watch_app_icon.asset_token).to eq(nil)
      end
    end

    # describe "Modifying the app trailers", :trailers do
    #   let(:ipad_trailer_path) { "path_to_trailer.mov" }
    #   let(:ipad_trailer_preview_path) { "path_to_trailer_preview.jpg" }
    #   let(:ipad_external_valid_trailer_preview_path) { "path_to_my_screenshot.jpg" }
    #   let(:ipad_external_invalid_trailer_preview_path) { "path_to_my_invalid_screenshot.jpg.jpg" }
    #   before do
    #     allow(Spaceship::UploadFile).to receive(:from_path) do |path|
    #       r = du_uploadtrailer_correct_mov if path == ipad_trailer_path
    #       r = du_uploadtrailer_preview_correct_jpg if path == ipad_trailer_preview_path
    #       r = du_uploadtrailer_preview_correct_jpg if path == ipad_external_valid_trailer_preview_path
    #       r
    #     end

    #     allow(Spaceship::Utilities).to receive(:grab_video_preview) do |path|
    #       r = ipad_trailer_preview_path if path == ipad_trailer_path
    #       r
    #     end

    #     allow(Spaceship::Utilities).to receive(:portrait?) do |path|
    #       r = true if path == ipad_trailer_preview_path
    #       r = true if path == ipad_external_invalid_trailer_preview_path
    #       r = true if path == ipad_external_valid_trailer_preview_path
    #       r
    #     end

    #     allow(Spaceship::Utilities).to receive(:resolution) do |path|
    #       r = [900, 1200] if path == ipad_trailer_path
    #       r = [768, 1024] if path == ipad_trailer_preview_path
    #       r = [700, 1000] if path == ipad_external_invalid_trailer_preview_path
    #       r = [768, 1024] if path == ipad_external_valid_trailer_preview_path
    #       r
    #     end

    #     json = JSON.parse(du_read_fixture_file("upload_trailer_response_success.json"))
    #     allow(client.du_client).to receive(:upload_trailer).and_return(json)

    #     json = JSON.parse(du_read_upload_trailer_preview_response_success)
    #     allow(client.du_client).to receive(:upload_trailer_preview).and_return(json)
    #   end

    #   def trailers(device)
    #     version.trailers["English"].select { |s| s.device_type == device }
    #   end

    #   def ipad_trailers
    #     trailers("ipad")
    #   end

    #   it "cannot add a trailer to iphone35" do
    #     expect do
    #       version.upload_trailer!(ipad_trailer_path, "English", 'iphone35')
    #     end.to raise_error "No app trailer supported for iphone35"
    #   end

    #   it "requires timestamp with a specific format" do
    #     expect do
    #       version.upload_trailer!(ipad_trailer_path, "English", 'ipad', "00:01.000")
    #     end.to raise_error "Invalid timestamp 00:01.000"
    #     expect do
    #       version.upload_trailer!(ipad_trailer_path, "English", 'ipad', "01.000")
    #     end.to raise_error "Invalid timestamp 01.000"
    #   end

    #   it "can add a new trailer" do
    #     # remove existing
    #     version.upload_trailer!(nil, "English", 'ipad')

    #     count = ipad_trailers.count
    #     expect(count).to eq(0)
    #     version.upload_trailer!(ipad_trailer_path, "English", 'ipad')
    #     count_after = ipad_trailers.count
    #     expect(count_after).to eq(count + 1)
    #     expect(count_after).to eq(count + 1)
    #     trailer = ipad_trailers[0]
    #     expect(trailer.video_asset_token).to eq("VideoSource40/v4/e3/48/1a/e3481a8f-ec25-e19f-5048-270d7acaf89a/pr_source.mov")
    #     expect(trailer.picture_asset_token).to eq("Purple69/v4/5f/2b/81/5f2b814d-1083-5509-61fb-c0845f7a9374/pr_source.jpg")
    #     expect(trailer.descriptionXML).to match(/FoghornLeghorn/)
    #     expect(trailer.preview_frame_time_code).to eq("00:00:05:00")
    #     expect(trailer.video_url).to eq(nil)
    #     expect(trailer.preview_image_url).to eq(nil)
    #     expect(trailer.full_sized_preview_image_url).to eq(nil)
    #     expect(trailer.device_type).to eq("ipad")
    #     expect(trailer.language).to eq("English")
    #   end

    #   it "can modify the preview of an existing trailer and automatically generates a new screenshot preview" do
    #     json = JSON.parse(du_read_upload_trailer_preview_2_response_success)
    #     allow(client.du_client).to receive(:upload_trailer_preview).and_return(json)

    #     count = ipad_trailers.count
    #     expect(count).to eq(1)
    #     version.upload_trailer!(ipad_trailer_path, "English", 'ipad', "06.12")
    #     count_after = ipad_trailers.count
    #     expect(count_after).to eq(count)
    #     trailer = ipad_trailers[0]

    #     expect(trailer.video_asset_token).to eq(nil)
    #     expect(trailer.picture_asset_token).to eq("Purple70/v4/5f/2b/81/5f2b814d-1083-5509-61fb-c0845f7a9374/pr_source.jpg")
    #     expect(trailer.descriptionXML).to eq(nil)
    #     expect(trailer.preview_frame_time_code).to eq("00:00:06:12")
    #     expect(trailer.video_url).to eq("http://a1713.phobos.apple.com/us/r30/PurpleVideo7/v4/be/38/db/be38db8d-868a-d442-87dc-cb6d630f921e/P37134684_default.m3u8")
    #     expect(trailer.preview_image_url).to eq("https://is1-ssl.mzstatic.com/image/thumb/PurpleVideo5/v4/b7/41/5e/b7415e96-5ad5-6cf5-9323-15122145e53f/Job21976428-61a9-456b-af46-26c1303ae607-91524171-PreviewImage_AppTrailer_quicktime-Time1438426738374.png/500x500bb-80.png")
    #     expect(trailer.full_sized_preview_image_url).to eq("https://is1-ssl.mzstatic.com/image/thumb/PurpleVideo5/v4/b7/41/5e/b7415e96-5ad5-6cf5-9323-15122145e53f/Job21976428-61a9-456b-af46-26c1303ae607-91524171-PreviewImage_AppTrailer_quicktime-Time1438426738374.png/900x1200ss-80.png")
    #     expect(trailer.device_type).to eq("ipad")
    #     expect(trailer.language).to eq("English")
    #   end

    #   it "can add a new trailer given a valid externally provided preview screenshot" do
    #     # remove existing
    #     version.upload_trailer!(nil, "English", 'ipad')

    #     expect do
    #       version.upload_trailer!(ipad_trailer_path, "English", 'ipad', '12.34', ipad_external_invalid_trailer_preview_path)
    #     end.to raise_error "Invalid portrait screenshot resolution for device ipad. Should be [768, 1024]"
    #   end

    #   it "can add a new trailer given a valid externally provided preview screenshot" do
    #     # remove existing
    #     version.upload_trailer!(nil, "English", 'ipad')

    #     count = ipad_trailers.count
    #     expect(count).to eq(0)
    #     version.upload_trailer!(ipad_trailer_path, "English", 'ipad', '12.34', ipad_external_valid_trailer_preview_path)
    #     count_after = ipad_trailers.count
    #     expect(count_after).to eq(count + 1)
    #     trailer = ipad_trailers[0]
    #     expect(trailer.video_asset_token).to eq("VideoSource40/v4/e3/48/1a/e3481a8f-ec25-e19f-5048-270d7acaf89a/pr_source.mov")
    #     expect(trailer.picture_asset_token).to eq("Purple69/v4/5f/2b/81/5f2b814d-1083-5509-61fb-c0845f7a9374/pr_source.jpg")
    #     expect(trailer.descriptionXML).to match(/FoghornLeghorn/)
    #     expect(trailer.preview_frame_time_code).to eq("00:00:12:34")
    #     expect(trailer.video_url).to eq(nil)
    #     expect(trailer.preview_image_url).to eq(nil)
    #     expect(trailer.full_sized_preview_image_url).to eq(nil)
    #     expect(trailer.device_type).to eq("ipad")
    #     expect(trailer.language).to eq("English")
    #   end

    #   # IDEA: can we detect trailer source change ?

    #   it "remove the video trailer" do
    #     count = ipad_trailers.count
    #     expect(count).to eq(1)
    #     version.upload_trailer!(nil, "English", 'ipad')
    #     count_after = ipad_trailers.count
    #     expect(count_after).to eq(count - 1)
    #   end
    # end

    describe "Reading and modifying the geojson file", :du do
      before do
        json = JSON.parse(du_read_upload_geojson_response_success)
        allow(client.du_client).to receive(:upload_geojson).and_return(json)
      end

      it "default geojson data is nil when value field is missing" do
        expect(version.raw_data["transitAppFile"]["value"]).to eq(nil)
        expect(version.transit_app_file).to eq(nil)
      end

      it "modifies the geojson file data after update" do
        allow(Spaceship::Utilities).to receive(:md5digest).and_return("FAKEMD5")
        file_name = "upload_valid.geojson"
        version.upload_geojson!(du_fixture_file_path(file_name))
        expect(version.transit_app_file.name).to eq("ftl_FAKEMD5_#{file_name}")
        expect(version.transit_app_file.url).to eq(nil)
        expect(version.transit_app_file.asset_token).to eq("Purple1/v4/45/50/9d/45509d39-6a5d-7f55-f919-0fbc7436be61/pr_source.geojson")
      end

      it "deletes the geojson" do
        version.upload_geojson!(du_fixture_file_path("upload_valid.geojson"))
        version.upload_geojson!(nil)
        expect(version.raw_data["transitAppFile"]["value"]).to eq(nil)
        expect(version.transit_app_file).to eq(nil)
      end
    end

    describe "Upload screenshots", :screenshots do
      before do
        allow(Spaceship::UploadFile).to receive(:from_path) do |path|
          du_uploadimage_correct_screenshot if path == "path_to_screenshot"
        end
      end
      let(:screenshot_path) { "path_to_screenshot" }

      describe "Parameter checks" do
        it "prevents from using negative sort_order" do
          expect do
            version.upload_screenshot!(screenshot_path, -1, "English", 'iphone4', false)
          end.to raise_error("sort_order must be higher than 0")
        end

        it "prevents from using sort_order 0" do
          expect do
            version.upload_screenshot!(screenshot_path, 0, "English", 'iphone4', false)
          end.to raise_error("sort_order must be higher than 0")
        end

        it "prevents from using too large sort_order" do
          expect do
            version.upload_screenshot!(screenshot_path, 11, "English", 'iphone4', false)
          end.to raise_error("sort_order must not be > 10")
        end

        # not really sure if we want to enforce that
        # it "prevents from letting holes in sort_orders" do
        #  expect do
        #    version.upload_screenshot!(screenshot_path, 4, "English", 'iphone4', false)
        #  end.to raise_error "FIXME"
        # end

        it "prevent from using invalid language" do
          expect do
            version.upload_screenshot!(screenshot_path, 1, "NotALanguage", 'iphone4', false)
          end.to raise_error("App Store Connect error: NotALanguage isn't an activated language")
        end

        it "prevent from using invalid language" do
          expect do
            version.upload_screenshot!(screenshot_path, 1, "English_CA", 'iphone4', false)
          end.to raise_error("App Store Connect error: English_CA isn't an activated language")
        end

        it "prevent from using invalid device" do
          expect do
            version.upload_screenshot!(screenshot_path, 1, "English", :android, false)
          end.to raise_error("App Store Connect error: android isn't a valid device name")
        end
      end

      describe "Add, Replace, Remove screenshots" do
        before do
          allow(Spaceship::Utilities).to receive(:md5digest).and_return("FAKEMD5")
        end

        it "can add a new screenshot to the list" do
          du_upload_screenshot_success

          count = version.screenshots["English"].count
          version.upload_screenshot!(screenshot_path, 4, "English", 'iphone4', false)
          expect(version.screenshots["English"].count).to eq(count + 1)
        end

        it "can add a new iMessage screenshot to the list" do
          du_upload_messages_screenshot_success

          count = version.screenshots["English"].count
          version.upload_screenshot!(screenshot_path, 4, "English", 'iphone4', true)
          expect(version.screenshots["English"].count).to eq(count + 1)
        end

        it "auto-sets the 'scaled' parameter when the user provides a screenshot" do
          def fetch_family(device_type, language)
            lang_details = version.raw_data["details"]["value"].find { |a| a["language"] == language }
            return lang_details["displayFamilies"]["value"].find { |value| value["name"] == device_type }
          end

          device_type = "iphone35"
          language = "English"

          du_upload_screenshot_success

          family = fetch_family(device_type, language)
          expect(family["scaled"]["value"]).to eq(true)

          version.upload_screenshot!(screenshot_path, 1, language, device_type, false)

          family = fetch_family(device_type, language)
          expect(family["scaled"]["value"]).to eq(false)
        end

        it "auto-sets the 'scaled' parameter when the user provides an iMessage screenshot" do
          def fetch_family(device_type, language)
            lang_details = version.raw_data["details"]["value"].find { |a| a["language"] == language }
            return lang_details["displayFamilies"]["value"].find { |value| value["name"] == device_type }
          end

          device_type = "iphone4"
          language = "English"

          du_upload_messages_screenshot_success

          family = fetch_family(device_type, language)
          expect(family["messagesScaled"]["value"]).to eq(true)

          version.upload_screenshot!(screenshot_path, 1, language, device_type, true)

          family = fetch_family(device_type, language)
          expect(family["messagesScaled"]["value"]).to eq(false)
        end

        it "can replace an existing screenshot with existing sort_order" do
          du_upload_screenshot_success

          count = version.screenshots["English"].count
          version.upload_screenshot!(screenshot_path, 2, "English", 'iphone4', false)
          expect(version.screenshots["English"].count).to eq(count)
        end

        it "can remove existing screenshot" do
          count = version.screenshots["English"].count
          version.upload_screenshot!(nil, 2, "English", 'iphone4', false)
          expect(version.screenshots["English"].count).to eq(count - 1)
        end

        it "fails with error if the screenshot to remove doesn't exist" do
          expect do
            version.upload_screenshot!(nil, 5, "English", 'iphone4', false)
          end.to raise_error("cannot remove screenshot with nonexistent sort_order")
        end
      end
    end

    it "allows modifications of localized values" do
      new_title = 'New Title'
      version.description["English"] = new_title
      lang = version.languages.find { |a| a['language'] == "English" }
      expect(lang['description']['value']).to eq(new_title)
    end

    describe "Pushing the changes back to the server" do
      it "raises an exception if there was an error" do
        TunesStubbing.itc_stub_invalid_update
        expect do
          version.save!
        end.to raise_error("[German]: The App Name you entered has already been used. [English]: The App Name you entered has already been used. You must provide an address line. There are errors on the page and for 2 of your localizations.")
      end

      it "works with valid update data" do
        TunesStubbing.itc_stub_valid_update
        expect(client).to receive(:update_app_version!).with('898536088', 812_106_519, version.raw_data)
        version.save!
      end

      it "overwrites release_upon_approval if auto_release_date is set" do
        TunesStubbing.itc_stub_valid_version_update_with_autorelease_and_release_on_datetime
        version.release_on_approval = true
        version.auto_release_date = 1_480_435_200_000
        returned = Spaceship::Tunes::AppVersion.new(version.save!)
        expect(returned.release_on_approval).to eq(false)
        expect(returned.auto_release_date).to eq(1_480_435_200_000)
      end
    end

    describe "update_app_version! retry mechanism" do
      let(:update_success_data) { JSON.parse(TunesStubbing.itc_read_fixture_file('update_app_version_success.json'))['data'] }

      def setup_handle_itc_response_failure(nb_failures)
        @times_called = 0
        allow(client).to receive(:handle_itc_response) do |data|
          @times_called += 1
          raise Spaceship::TunesClient::ITunesConnectTemporaryError, "simulated try again" if @times_called <= nb_failures
          update_success_data
        end
        # arbitrary stub to prevent mock network failures. We override itc_response
        TunesStubbing.itc_stub_valid_update
      end

      def setup_handle_itc_potential_server_failure(nb_failures)
        @times_called = 0
        allow(client).to receive(:handle_itc_response) do |data|
          @times_called += 1
          raise Spaceship::TunesClient::ITunesConnectPotentialServerError, "simulated try again" if @times_called <= nb_failures
          update_success_data
        end
        # arbitrary stub to prevent mock network failures. We override itc_response
        TunesStubbing.itc_stub_valid_update
      end

      it "retries when ITC is temporarily unable to save changes" do
        setup_handle_itc_response_failure(1)

        version.save!
        expect(@times_called).to eq(2)
      end

      it "retries when ITC throws an error and it might be a server issue" do
        setup_handle_itc_potential_server_failure(1)

        version.save!
        expect(@times_called).to eq(2)
      end

      it "retries a maximum number of times when ITC is temporarily unable to save changes" do
        setup_handle_itc_response_failure(6) # set to more than should happen

        expect do
          version.save!
        end.to raise_error(Spaceship::TunesClient::ITunesConnectTemporaryError)
        expect(@times_called).to eq(5)
      end

      it "retries a maximum number of times when ITC is not responding properly" do
        setup_handle_itc_potential_server_failure(4) # set to more than should happen

        expect do
          version.save!
        end.to raise_error(Spaceship::TunesClient::ITunesConnectPotentialServerError)
        expect(@times_called).to eq(3)
      end
    end

    describe "Accessing different languages" do
      it "raises an exception if language is not available" do
        expect do
          version.description["ja-JP"]
        end.to raise_error("Language 'ja-JP' is not activated / available for this app version.")
      end

      # it "allows the creation of a new language" do
      #   version.create_languages!(['German', 'English_CA'])
      #   expect(version.name['German']).to eq("yep, that's the name")
      #   expect(version.name['English_CA']).to eq("yep, that's the name")
      # end
    end

    describe "Rejecting" do
      it 'rejects' do
        TunesStubbing.itc_stub_reject_version_success
        version.can_reject_version = true
        expect(client).to receive(:reject!).with('898536088', 812_106_519)
        version.reject!
      end

      it 'raises exception when not rejectable' do
        TunesStubbing.itc_stub_valid_update
        expect do
          version.reject!
        end.to raise_error("Version not rejectable")
      end
    end
  end

  describe "Modifying the app live version" do
    let(:version) { app.live_version }

    describe "Generate promo codes", focus: true do
      it "fetches remaining promocodes" do
        promocodes = version.generate_promocodes!(1)

        expect(promocodes.effective_date).to eq(1_457_864_552_300)
        expect(promocodes.expiration_date).to eq(1_460_283_752_300)
        expect(promocodes.username).to eq('joe@wewanttoknow.com')

        expect(promocodes.codes.count).to eq(1)
        expect(promocodes.codes[0]).to eq('6J49JFRPTXXXX')
        expect(promocodes.version.app_id).to eq(816_549_081)
        expect(promocodes.version.app_name).to eq('DragonBox Numbers')
        expect(promocodes.version.version).to eq('1.5.0')
        expect(promocodes.version.platform).to eq('ios')
        expect(promocodes.version.number_of_codes).to eq(3)
        expect(promocodes.version.maximum_number_of_codes).to eq(100)
        expect(promocodes.version.contract_file_name).to eq('promoCodes/ios/spqr5/PromoCodeHolderTermsDisplay_en_us.html')
      end
    end
  end

  describe "Validate attachment file" do
    before { Spaceship::Tunes.login }
    let(:client) { Spaceship::AppVersion.client }
    describe "successfully loads and parses the app version and attachment" do
      it "contains the right information" do
        TunesStubbing.itc_stub_app_attachment
        v = app.edit_version(platform: 'ios')
        expect(v.review_attachment_file.original_file_name).to eq("attachment.txt")
        expect(v.review_attachment_file.asset_token).to eq("test/v4/02/88/4d/02884d3d-92ea-5e6a-2a7b-b19da39f73a6/attachment.txt")
        expect(v.review_attachment_file.url).to eq("https://iosapps-ssl.itunes.apple.com/itunes-assets/test/v4/02/88/4d/02884d3d-92ea-5e6a-2a7b-b19da39f73a6/attachment.txt")
      end
    end
  end
end
