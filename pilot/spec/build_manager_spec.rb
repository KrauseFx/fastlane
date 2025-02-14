describe "Build Manager" do
  describe ".truncate_changelog" do
    it "Truncates Changelog if it exceeds character size" do
      changelog = File.read("./pilot/spec/fixtures/build_manager/changelog_long")
      changelog = Pilot::BuildManager.truncate_changelog(changelog)
      expect(changelog).to eq(File.read("./pilot/spec/fixtures/build_manager/changelog_long_truncated"))
    end
    it "Truncates Changelog if it exceeds byte size" do
      changelog = File.binread("./pilot/spec/fixtures/build_manager/changelog_bytes_long").force_encoding("UTF-8")
      changelog = Pilot::BuildManager.truncate_changelog(changelog)
      expect(changelog).to eq(File.binread("./pilot/spec/fixtures/build_manager/changelog_bytes_long_truncated").force_encoding("UTF-8"))
    end
    it "Keeps changelog if short enough" do
      changelog = "1234"
      changelog = Pilot::BuildManager.truncate_changelog(changelog)
      expect(changelog).to eq("1234")
    end
    it "Truncates based on bytes not characters" do
      changelog = "ü" * 4000
      expect(changelog.unpack("C*").length).to eq(8000)
      changelog = Pilot::BuildManager.truncate_changelog(changelog)
      # Truncation appends "...", so the result is 1998 two-byte characters plus "..." for 3999 bytes.
      expect(changelog.unpack("C*").length).to eq(3999)
    end
  end

  describe ".sanitize_changelog" do
    it "removes emoji" do
      changelog = "I'm 🦇B🏧an🪴!"
      changelog = Pilot::BuildManager.sanitize_changelog(changelog)
      expect(changelog).to eq("I'm Ban!")
    end
    it "removes less than symbols" do
      changelog = "I'm <script>man<<!"
      changelog = Pilot::BuildManager.sanitize_changelog(changelog)
      expect(changelog).to eq("I'm script>man!")
    end
    it "removes prohibited symbols before truncating" do
      changelog = File.read("./pilot/spec/fixtures/build_manager/changelog_long")
      changelog = "🎉<🎉<🎉#{changelog}🎉<🎉<🎉"
      changelog = Pilot::BuildManager.sanitize_changelog(changelog)
      expect(changelog).to eq(File.read("./pilot/spec/fixtures/build_manager/changelog_long_truncated"))
    end
  end

  describe ".has_changelog_or_whats_new?" do
    let(:fake_build_manager) { Pilot::BuildManager.new }
    let(:no_options) { {} }
    let(:changelog) { { changelog: "Sup" } }
    let(:whats_new_symbol) { { localized_build_info: { 'en-us' => { whats_new: 'Sup' } } } }
    let(:whats_new_string) { { localized_build_info: { 'en-us' => { 'whats_new' => 'Sup' } } } }

    it "returns false for no changelog or whats_new" do
      has = fake_build_manager.has_changelog_or_whats_new?(no_options)
      expect(has).to eq(false)
    end

    it "returns true for changelog" do
      has = fake_build_manager.has_changelog_or_whats_new?(changelog)
      expect(has).to eq(true)
    end

    it "returns true for whats_new with symbol" do
      has = fake_build_manager.has_changelog_or_whats_new?(whats_new_symbol)
      expect(has).to eq(true)
    end

    it "returns true for whats_new with string" do
      has = fake_build_manager.has_changelog_or_whats_new?(whats_new_string)
      expect(has).to eq(true)
    end
  end

  describe ".check_for_changelog_or_whats_new!" do
    let(:fake_build_manager) { Pilot::BuildManager.new }
    let(:fake_changelog) { "fake changelog" }
    let(:input_options) { { distribute_external: true } }

    describe "what happens when changelog is not given and distribute_external is true" do
      before(:each) do
        allow(fake_build_manager).to receive(:has_changelog_or_whats_new?).with(input_options).and_return(false)
      end

      context "when UI.interactive? is possible" do
        before(:each) do
          allow(UI).to receive(:interactive?).and_return(true)
        end

        it "asks the user to enter the changelog" do
          expect(UI).to receive(:input).with("No changelog provided for new build. You can provide a changelog using the `changelog` option. For now, please provide a changelog here:")

          fake_build_manager.check_for_changelog_or_whats_new!(input_options)
        end

        it "sets the user entered changelog into input_options" do
          allow(UI).to receive(:input).and_return(fake_changelog)

          fake_build_manager.check_for_changelog_or_whats_new!(input_options)

          expect(input_options).to eq({ distribute_external: true, changelog: fake_changelog })
        end
      end

      context "when UI.interactive? is not possible" do
        before(:each) do
          allow(UI).to receive(:interactive?).and_return(false)
        end

        it "raises an exception with message either disable `distribute_external` or provide a changelog using the `changelog` option" do
          expect(UI).to receive(:user_error!).with("No changelog provided for new build. Please either disable `distribute_external` or provide a changelog using the `changelog` option")

          fake_build_manager.check_for_changelog_or_whats_new!(input_options)
        end
      end
    end
  end

  describe "distribute submits the build for review" do
    let(:mock_base_client) { "fake api base client" }
    let(:fake_build_manager) { Pilot::BuildManager.new }

    let(:app) do
      Spaceship::ConnectAPI::App.new("123-123-123-123", {
        name: "Mock App"
      })
    end
    let(:pre_release_version) do
      Spaceship::ConnectAPI::PreReleaseVersion.new("123-123-123-123", {
        version: "1.0"
      })
    end
    let(:app_localizations) do
      [
        Spaceship::ConnectAPI::BetaAppLocalization.new("234", {
          feedbackEmail: 'email@email.com',
          marketingUrl: 'https://url.com',
          privacyPolicyUrl: 'https://url.com',
          description: 'desc desc desc',
          locale: 'en-us'
        }),
        Spaceship::ConnectAPI::BetaAppLocalization.new("432", {
          feedbackEmail: 'email@email.com',
          marketingUrl: 'https://url.com',
          privacyPolicyUrl: 'https://url.com',
          description: 'desc desc desc',
          locale: 'en-gb'
        })
      ]
    end
    let(:build_localizations) do
      [
        Spaceship::ConnectAPI::BetaBuildLocalization.new("234", {
          whatsNew: 'some more words',
          locale: 'en-us'
        }),
        Spaceship::ConnectAPI::BetaBuildLocalization.new("432", {
          whatsNew: 'some words',
          locale: 'en-gb'
        })
      ]
    end
    let(:build_beta_detail_still_processing) do
      Spaceship::ConnectAPI::BuildBetaDetail.new("321", {
        internal_build_state: Spaceship::ConnectAPI::BuildBetaDetail::InternalState::PROCESSING,
        external_build_state: Spaceship::ConnectAPI::BuildBetaDetail::ExternalState::PROCESSING
      })
    end
    let(:build_beta_detail_missing_export_compliance) do
      Spaceship::ConnectAPI::BuildBetaDetail.new("321", {
        internal_build_state: Spaceship::ConnectAPI::BuildBetaDetail::InternalState::MISSING_EXPORT_COMPLIANCE,
        external_build_state: Spaceship::ConnectAPI::BuildBetaDetail::ExternalState::MISSING_EXPORT_COMPLIANCE
      })
    end
    let(:build_beta_detail) do
      Spaceship::ConnectAPI::BuildBetaDetail.new("321", {
        internal_build_state: Spaceship::ConnectAPI::BuildBetaDetail::InternalState::READY_FOR_BETA_TESTING,
        external_build_state: Spaceship::ConnectAPI::BuildBetaDetail::ExternalState::READY_FOR_BETA_SUBMISSION
      })
    end
    let(:beta_groups) do
      [
        Spaceship::ConnectAPI::BetaGroup.new("987", {
          name: "Blue Man Group"
        }),
        Spaceship::ConnectAPI::BetaGroup.new("654", {
          name: "Green Eggs and Ham"
        })
      ]
    end
    let(:ready_to_submit_mock_build) do
      Spaceship::ConnectAPI::Build.new("123", {
        version: '',
        uploadedDate: '',
        processingState: Spaceship::ConnectAPI::Build::ProcessingState::VALID,
        usesNonExemptEncryption: nil
      })
    end

    let(:distribute_options) do
      {
        apple_id: 'mock_apple_id',
        app_identifier: 'mock_app_id',
        distribute_external: true,
        groups: ["Blue Man Group"],
        skip_submission: false
      }
    end
    let(:mock_api_client_beta_app_localizations) do
      [
        { "id" => "234", "attributes" => { "locale" => "en-us" } },
        { "id" => "432", "attributes" => { "locale" => "en-gb" } }
      ]
    end
    let(:mock_api_client_beta_build_localizations) do
      [
        { "id" => "234", "attributes" => { "locale" => "en-us" } },
        { "id" => "432", "attributes" => { "locale" => "en-gb" } }
      ]
    end
    let(:mock_api_client_beta_groups) do
      [
        { "id" => "987", "attributes" => { "name" => "Blue Man Group" } },
        { "id" => "654", "attributes" => { "name" => "Green Eggs and Ham" } }
      ]
    end

    describe "distribute success" do
      let(:distribute_options_skip_waiting_non_localized_changelog) do
        {
          apple_id: 'mock_apple_id',
          app_identifier: 'mock_app_id',
          distribute_external: false,
          skip_submission: false,
          skip_waiting_for_build_processing: true,
          notify_external_testers: true,
          uses_non_exempt_encryption: false,
          changelog: "log of changing"
        }
      end
      let(:distribute_options_non_localized) do
        {
          apple_id: 'mock_apple_id',
          app_identifier: 'mock_app_id',
          distribute_external: true,
          groups: ["Blue Man Group"],
          skip_submission: false,
          demo_account_required: true,
          notify_external_testers: true,
          beta_app_feedback_email: "josh+oldfeedback@rokkincat.com",
          beta_app_description: "old description for all the things",
          uses_non_exempt_encryption: false,
          submit_beta_review: true,
          changelog: "log of changing"
        }
      end

      before(:each) do
        allow(fake_build_manager).to receive(:login)
        allow(mock_base_client).to receive(:team_id).and_return('')

        allow(Spaceship::ConnectAPI).to receive(:post_beta_app_review_submissions) # pretend it worked.
        allow(Spaceship::ConnectAPI::TestFlight).to receive(:instance).and_return(mock_base_client)

        # Allow build to return app, build_beta_detail, and pre_release_version
        # These are models that are expected to usually be included in the build passed into distribute
        allow(ready_to_submit_mock_build).to receive(:app).and_return(app)
        allow(ready_to_submit_mock_build).to receive(:pre_release_version).and_return(pre_release_version)
      end

      it "updates non-localized changelog and doesn't distribute" do
        expect(ready_to_submit_mock_build).to receive(:build_beta_detail).and_return(build_beta_detail_still_processing).exactly(4).times

        options = distribute_options_skip_waiting_non_localized_changelog

        # Expect beta build localizations to be fetched
        expect(Spaceship::ConnectAPI).to receive(:get_beta_build_localizations).with({
          filter: { build: ready_to_submit_mock_build.id },
          includes: nil,
          limit: nil,
          sort: nil
        }).and_return(Spaceship::ConnectAPI::Response.new)
        expect(ready_to_submit_mock_build).to receive(:get_beta_build_localizations).and_wrap_original do |m, *args|
          m.call(*args)
          build_localizations
        end

        # Expect beta build localizations to be patched with a UI.success after
        mock_api_client_beta_build_localizations.each do |localization|
          expect(Spaceship::ConnectAPI).to receive(:patch_beta_build_localizations).with({
            localization_id: localization['id'],
            attributes: {
              whatsNew: options[:changelog]
            }
          })
        end
        expect(FastlaneCore::UI).to receive(:success).with("Successfully set the changelog for build")

        # Expect build beta details to be patched
        expect(Spaceship::ConnectAPI).to receive(:patch_build_beta_details).with({
          build_beta_details_id: build_beta_detail.id,
          attributes: { autoNotifyEnabled: options[:notify_external_testers] }
        })

        # Don't expect success messages
        expect(FastlaneCore::UI).to_not(receive(:message).with(/Distributing new build to testers/))
        expect(FastlaneCore::UI).to_not(receive(:success).with(/Successfully distributed build to/))

        fake_build_manager.distribute(options, build: ready_to_submit_mock_build)
      end

      it "updates non-localized demo_account_required, notify_external_testers, beta_app_feedback_email, and beta_app_description and distributes" do
        expect(ready_to_submit_mock_build).to receive(:build_beta_detail).and_return(build_beta_detail_missing_export_compliance).exactly(7).times

        options = distribute_options_non_localized

        # Expect App.find to be called from within Pilot::Manager
        expect(Spaceship::ConnectAPI::App).to receive(:get).and_return(app)

        # Expect a beta app review detail to be patched
        expect(Spaceship::ConnectAPI).to receive(:patch_beta_app_review_detail).with({
          app_id: ready_to_submit_mock_build.app_id,
          attributes: { demoAccountRequired: options[:demo_account_required] }
        })

        # Expect beta app localizations to be fetched
        expect(Spaceship::ConnectAPI).to receive(:get_beta_app_localizations).with({
          filter: { app: ready_to_submit_mock_build.app.id },
          includes: nil,
          limit: nil,
          sort: nil
        }).and_return(Spaceship::ConnectAPI::Response.new)
        expect(app).to receive(:get_beta_app_localizations).and_wrap_original do |m, *args|
          m.call(*args)
          app_localizations
        end

        # Expect beta app localizations to be patched with a UI.success after
        mock_api_client_beta_app_localizations.each do |localization|
          expect(Spaceship::ConnectAPI).to receive(:patch_beta_app_localizations).with({
            localization_id: localization['id'],
            attributes: {
              feedbackEmail: options[:beta_app_feedback_email],
              description: options[:beta_app_description]
            }
          })
        end
        expect(FastlaneCore::UI).to receive(:success).with("Successfully set the beta_app_feedback_email and/or beta_app_description")

        # Expect beta build localizations to be fetched
        expect(Spaceship::ConnectAPI).to receive(:get_beta_build_localizations).with({
          filter: { build: ready_to_submit_mock_build.id },
          includes: nil,
          limit: nil,
          sort: nil
        }).and_return(Spaceship::ConnectAPI::Response.new)
        expect(ready_to_submit_mock_build).to receive(:get_beta_build_localizations).and_wrap_original do |m, *args|
          m.call(*args)
          build_localizations
        end

        # Expect beta build localizations to be patched with a UI.success after
        mock_api_client_beta_build_localizations.each do |localization|
          expect(Spaceship::ConnectAPI).to receive(:patch_beta_build_localizations).with({
            localization_id: localization['id'],
            attributes: {
              whatsNew: options[:changelog]
            }
          })
        end
        expect(FastlaneCore::UI).to receive(:success).with("Successfully set the changelog for build")

        # Expect build beta details to be patched
        expect(Spaceship::ConnectAPI).to receive(:patch_build_beta_details).with({
          build_beta_details_id: build_beta_detail.id,
          attributes: { autoNotifyEnabled: options[:notify_external_testers] }
        })

        # A build will go back into a processing state after a patch
        # Expect wait_for_export compliance processing_to_be_complete to be called after patching
        expect(Spaceship::ConnectAPI).to receive(:patch_builds).with({
          build_id: ready_to_submit_mock_build.id, attributes: { usesNonExemptEncryption: false }
        })
        expect(Spaceship::ConnectAPI::Build).to receive(:get).and_return(ready_to_submit_mock_build).exactly(2).times
        expect(FastlaneCore::UI).to receive(:message).with("Waiting for build 123 to process export compliance")
        expect(ready_to_submit_mock_build).to receive(:build_beta_detail).and_return(build_beta_detail).exactly(3).times

        # Expect beta groups fetched from app. This tests:
        # 1. app.get_beta_groups is called
        # 2. client.get_beta_groups is called inside of app.beta_groups
        expect(Spaceship::ConnectAPI).to receive(:get_beta_groups).with({
          filter: { app: ready_to_submit_mock_build.app.id },
          includes: nil,
          limit: nil,
          sort: nil
        }).and_return(Spaceship::ConnectAPI::Response.new)
        expect(app).to receive(:get_beta_groups).and_wrap_original do |m, *args|
          m.call(*args)
          beta_groups
        end

        # Expect beta groups to be added to a builds. This tests:
        # 1. build.add_beta_groups is called
        # 2. client.add_beta_groups_to_build is called inside of build.add_beta_groups
        expect(Spaceship::ConnectAPI).to receive(:add_beta_groups_to_build).with({
          build_id: ready_to_submit_mock_build.id,
          beta_group_ids: [beta_groups[0].id]
        }).and_return(Spaceship::ConnectAPI::Response.new)
        expect(ready_to_submit_mock_build).to receive(:add_beta_groups).with(beta_groups: [beta_groups[0]]).and_wrap_original do |m, *args|
          options = args.first
          m.call(**options)
        end

        # Expect success messages
        expect(FastlaneCore::UI).to receive(:message).with(/Distributing new build to testers/)
        expect(FastlaneCore::UI).to receive(:success).with(/Successfully distributed build to/)

        fake_build_manager.distribute(options, build: ready_to_submit_mock_build)
      end
    end
  end

  describe "#wait_for_build_processing_to_be_complete" do
    let(:fake_build_manager) { Pilot::BuildManager.new }
    let(:app) do
      Spaceship::ConnectAPI::App.new("123-123-123-123", {
        name: "Mock App"
      })
    end

    before(:each) do
      allow(fake_build_manager).to receive(:login)
      allow(fake_build_manager).to receive(:app).and_return(app)
    end

    it "wait given :ipa" do
      options = { ipa: "some_path.ipa" }
      fake_build_manager.instance_variable_set(:@config, options)

      expect(fake_build_manager).to receive(:fetch_app_platform)
      expect(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_version).and_return("1.2.3")
      expect(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_build).and_return("123")
      expect(FastlaneCore::PkgFileAnalyser).to_not(receive(:fetch_app_version))
      expect(FastlaneCore::PkgFileAnalyser).to_not(receive(:fetch_app_build))

      fake_build = double
      expect(fake_build).to receive(:app_version).and_return("1.2.3")
      expect(fake_build).to receive(:version).and_return("123")
      expect(FastlaneCore::BuildWatcher).to receive(:wait_for_build_processing_to_be_complete).and_return(fake_build)

      fake_build_manager.wait_for_build_processing_to_be_complete
    end

    it "wait given :pkg" do
      options = { pkg: "some_path.pkg" }
      fake_build_manager.instance_variable_set(:@config, options)

      expect(fake_build_manager).to receive(:fetch_app_platform)
      expect(FastlaneCore::IpaFileAnalyser).to_not(receive(:fetch_app_version))
      expect(FastlaneCore::IpaFileAnalyser).to_not(receive(:fetch_app_build))
      expect(FastlaneCore::PkgFileAnalyser).to receive(:fetch_app_version).and_return("1.2.3")
      expect(FastlaneCore::PkgFileAnalyser).to receive(:fetch_app_build).and_return("123")

      fake_build = double
      expect(fake_build).to receive(:app_version).and_return("1.2.3")
      expect(fake_build).to receive(:version).and_return("123")
      expect(FastlaneCore::BuildWatcher).to receive(:wait_for_build_processing_to_be_complete).and_return(fake_build)

      fake_build_manager.wait_for_build_processing_to_be_complete
    end

    it "wait given :distribute_only" do
      options = { pkg: "some_path.pkg", build_number: "234", app_version: "2.3.4", distribute_only: true }
      fake_build_manager.instance_variable_set(:@config, options)

      expect(fake_build_manager).to receive(:fetch_app_platform)
      expect(FastlaneCore::IpaFileAnalyser).to_not(receive(:fetch_app_version))
      expect(FastlaneCore::IpaFileAnalyser).to_not(receive(:fetch_app_build))
      expect(FastlaneCore::PkgFileAnalyser).to_not(receive(:fetch_app_version))
      expect(FastlaneCore::PkgFileAnalyser).to_not(receive(:fetch_app_build))

      fake_build = double
      expect(fake_build).to receive(:app_version).and_return("2.3.4")
      expect(fake_build).to receive(:version).and_return("234")
      expect(FastlaneCore::BuildWatcher).to receive(:wait_for_build_processing_to_be_complete).and_return(fake_build)

      fake_build_manager.wait_for_build_processing_to_be_complete
    end

    it "wait given :ipa and :pkg and platform ios" do
      options = { ipa: "some_path.ipa", pkg: "some_path.pkg" }
      fake_build_manager.instance_variable_set(:@config, options)

      expect(fake_build_manager).to receive(:fetch_app_platform).and_return("ios")
      expect(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_version).and_return("1.2.3")
      expect(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_build).and_return("123")
      expect(FastlaneCore::PkgFileAnalyser).to_not(receive(:fetch_app_version))
      expect(FastlaneCore::PkgFileAnalyser).to_not(receive(:fetch_app_build))

      fake_build = double
      expect(fake_build).to receive(:app_version).and_return("1.2.3")
      expect(fake_build).to receive(:version).and_return("123")
      expect(FastlaneCore::BuildWatcher).to receive(:wait_for_build_processing_to_be_complete).and_return(fake_build)

      fake_build_manager.wait_for_build_processing_to_be_complete
    end

    it "wait given :ipa and :pkg and osx platform" do
      options = { ipa: "some_path.ipa", pkg: "some_path.pkg", app_platform: "osx" }
      fake_build_manager.instance_variable_set(:@config, options)

      expect(fake_build_manager.config[:app_platform]).to be == "osx"
      expect(fake_build_manager).to receive(:fetch_app_platform).and_return("osx")

      expect(FastlaneCore::IpaFileAnalyser).to_not(receive(:fetch_app_version))
      expect(FastlaneCore::IpaFileAnalyser).to_not(receive(:fetch_app_build))
      expect(FastlaneCore::PkgFileAnalyser).to receive(:fetch_app_version).and_return("1.2.3")
      expect(FastlaneCore::PkgFileAnalyser).to receive(:fetch_app_build).and_return("123")

      fake_build = double
      expect(fake_build).to receive(:app_version).and_return("1.2.3")
      expect(fake_build).to receive(:version).and_return("123")
      expect(FastlaneCore::BuildWatcher).to receive(:wait_for_build_processing_to_be_complete).and_return(fake_build)

      fake_build_manager.wait_for_build_processing_to_be_complete
    end

    it "wait given :app_version and :build_number" do
      options = { app_version: "1.2.3", build_number: "123" }
      fake_build_manager.instance_variable_set(:@config, options)

      expect(fake_build_manager).to receive(:fetch_app_platform)

      fake_build = double
      expect(fake_build).to receive(:app_version).and_return("1.2.3")
      expect(fake_build).to receive(:version).and_return("123")
      expect(FastlaneCore::BuildWatcher).to receive(:wait_for_build_processing_to_be_complete).and_return(fake_build)

      fake_build_manager.wait_for_build_processing_to_be_complete
    end

    it "wait given :ipa, :app_version and :build_number" do
      options = { app_version: "4.5.6", build_number: "456", ipa: "some_path.ipa" }
      fake_build_manager.instance_variable_set(:@config, options)

      expect(fake_build_manager).to receive(:fetch_app_platform)
      expect(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_version).and_return("1.2.3")
      expect(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_build).and_return("123")

      fake_build = double
      expect(fake_build).to receive(:app_version).and_return("1.2.3")
      expect(fake_build).to receive(:version).and_return("123")
      expect(FastlaneCore::BuildWatcher).to receive(:wait_for_build_processing_to_be_complete).and_return(fake_build)

      fake_build_manager.wait_for_build_processing_to_be_complete
    end
  end

  describe "#update_beta_app_meta" do
    let(:fake_build_manager) { Pilot::BuildManager.new }
    let(:fake_build) { double("fake build") }

    it "does not attempt to set demo account required" do
      options = {}

      expect(fake_build_manager).not_to receive(:update_review_detail)
      expect(fake_build_manager).not_to receive(:update_build_beta_details)
      fake_build_manager.update_beta_app_meta(options, fake_build)
    end

    it "does not attempt to set demo account required" do
      options = { notify_external_testers: true }

      expect(fake_build_manager).not_to receive(:update_review_detail)
      expect(fake_build_manager).to receive(:update_build_beta_details)
      fake_build_manager.update_beta_app_meta(options, fake_build)
    end

    it "sets demo account required to false" do
      options = { demo_account_required: false }

      expect(fake_build_manager).to receive(:update_review_detail)
      expect(fake_build_manager).not_to receive(:update_build_beta_details)

      fake_build_manager.update_beta_app_meta(options, fake_build)

      expect(options[:beta_app_review_info][:demo_account_required]).to be(false)
    end

    it "sets demo account required to true" do
      options = { demo_account_required: true }

      expect(fake_build_manager).to receive(:update_review_detail)
      expect(fake_build_manager).not_to receive(:update_build_beta_details)

      fake_build_manager.update_beta_app_meta(options, fake_build)

      expect(options[:beta_app_review_info][:demo_account_required]).to be(true)
    end
  end

  describe "#upload" do
    describe "shows the correct notices" do
      let(:fake_build_manager) { Pilot::BuildManager.new }
      let(:fake_app_id) { 123 }
      let(:fake_dir) { "fake dir" }
      let(:fake_app_platform) { "ios" }
      let(:fake_app_identifier) { "org.fastlane.very-capable-app" }
      let(:fake_short_version) { "1.0" }
      let(:fake_bundle_version) { "1" }
      let(:upload_options) do
        {
          apple_id: fake_app_id,
          skip_waiting_for_build_processing: true,
          changelog: "changelog contents",
          ipa: File.expand_path("./fastlane_core/spec/fixtures/ipas/very-capable-app.ipa")
        }
      end

      before(:each) do
        allow(fake_build_manager).to receive(:login)
        allow(fake_build_manager).to receive(:fetch_app_platform).and_return(fake_app_platform)
        allow(Dir).to receive(:mktmpdir).and_return(fake_dir)

        fake_ipauploadpackagebuilder = double
        allow(fake_ipauploadpackagebuilder).to receive(:generate).with(app_id: fake_app_id, ipa_path: upload_options[:ipa], package_path: fake_dir, platform: fake_app_platform, app_identifier: fake_app_identifier, short_version: fake_short_version, bundle_version: fake_bundle_version).and_return(true)
        allow(FastlaneCore::IpaUploadPackageBuilder).to receive(:new).and_return(fake_ipauploadpackagebuilder)

        fake_itunestransporter = double
        allow(fake_itunestransporter).to receive(:upload).and_return(true)
        allow(FastlaneCore::ItunesTransporter).to receive(:new).and_return(fake_itunestransporter)

        fake_build = double
        expect(fake_build_manager).to receive(:wait_for_build_processing_to_be_complete).and_return(fake_build)

        expect(fake_build_manager).to receive(:distribute).with(upload_options, build: fake_build)
      end

      it "does not advertise `skip_waiting_for_build_processing` if the option is set" do
        expect(FastlaneCore::UI).to_not(receive(:message).with("If you want to skip waiting for the processing to be finished, use the `skip_waiting_for_build_processing` option"))
        expect(FastlaneCore::UI).to_not(receive(:message).with("Note that if `skip_waiting_for_build_processing` is used but a `changelog` is supplied, this process will wait for the build to appear on App Store Connect, update the changelog and then skip the remaining of the processing steps."))

        fake_build_manager.upload(upload_options)
      end

      it "shows notice when using `skip_waiting_for_build_processing` and changelog together" do
        expect(FastlaneCore::UI).to(receive(:important).with("`skip_waiting_for_build_processing` used and `changelog` supplied - will wait until build appears on App Store Connect, update the changelog and then skip the rest of the remaining of the processing steps."))

        fake_build_manager.upload(upload_options)
      end
    end

    describe "uses Manager.login (which does spaceship login) for ipa" do
      let(:fake_build_manager) { Pilot::BuildManager.new }
      let(:fake_app_id) { 123 }
      let(:fake_dir) { "fake dir" }
      let(:fake_app_platform) { "ios" }
      let(:fake_app_identifier) { "org.fastlane.very-capable-app" }
      let(:fake_short_version) { "1.0" }
      let(:fake_bundle_version) { "1" }
      let(:upload_options) do
        {
          apple_id: fake_app_id,
          skip_waiting_for_build_processing: true,
          ipa: File.expand_path("./fastlane_core/spec/fixtures/ipas/very-capable-app.ipa")
        }
      end

      before(:each) do
        allow(fake_build_manager).to receive(:fetch_app_platform).and_return(fake_app_platform)
        allow(Dir).to receive(:mktmpdir).and_return(fake_dir)

        fake_ipauploadpackagebuilder = double
        allow(fake_ipauploadpackagebuilder).to receive(:generate).with(app_id: fake_app_id, ipa_path: upload_options[:ipa], package_path: fake_dir, platform: fake_app_platform, app_identifier: fake_app_identifier, short_version: fake_short_version, bundle_version: fake_bundle_version).and_return(true)
        allow(FastlaneCore::IpaUploadPackageBuilder).to receive(:new).and_return(fake_ipauploadpackagebuilder)

        fake_itunestransporter = double
        allow(fake_itunestransporter).to receive(:upload).and_return(true)
        allow(FastlaneCore::ItunesTransporter).to receive(:new).and_return(fake_itunestransporter)

        expect(UI).to receive(:success).with("Ready to upload new build to TestFlight (App: #{fake_app_id})...")
        expect(UI).to receive(:success).with("Successfully uploaded the new binary to App Store Connect")
      end

      it "NOT when skip_waiting_for_build_processing and apple_id are set" do
        # should not execute Manager.login (which does spaceship login)
        expect(fake_build_manager).not_to(receive(:login))

        fake_build_manager.upload(upload_options)
      end

      it "when skip_waiting_for_build_processing and apple_id are not set" do
        # remove options that make login unnecessary
        upload_options.delete(:apple_id)
        upload_options.delete(:skip_waiting_for_build_processing)

        # allow Manager.login method this time
        expect(fake_build_manager).to receive(:login).at_least(:once)

        # check for changelog or whats new!
        expect(fake_build_manager).to receive(:check_for_changelog_or_whats_new!).with(upload_options)

        # other stuff required to let `upload` work:

        expect(fake_build_manager).to receive(:fetch_app_id).and_return(fake_app_id).exactly(2).times
        expect(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_version).and_return(fake_short_version).exactly(2).times
        expect(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_build).and_return(fake_bundle_version).exactly(2).times

        fake_app = double
        expect(fake_app).to receive(:id).and_return(fake_app_id)
        expect(fake_build_manager).to receive(:app).and_return(fake_app)

        fake_build = double
        expect(fake_build).to receive(:app_version).and_return(fake_short_version)
        expect(fake_build).to receive(:version).and_return(fake_bundle_version)
        expect(UI).to receive(:message).with("If you want to skip waiting for the processing to be finished, use the `skip_waiting_for_build_processing` option")
        expect(UI).to receive(:message).with("Note that if `skip_waiting_for_build_processing` is used but a `changelog` is supplied, this process will wait for the build to appear on App Store Connect, update the changelog and then skip the remaining of the processing steps.")
        expect(FastlaneCore::BuildWatcher).to receive(:wait_for_build_processing_to_be_complete).and_return(fake_build)

        expect(fake_build_manager).to receive(:distribute).with(upload_options, build: fake_build)

        fake_build_manager.upload(upload_options)
      end
    end

    describe "uploads file" do
      let(:fake_build_manager) { Pilot::BuildManager.new }
      let(:fake_app_id) { 123 }
      let(:fake_dir) { "fake dir" }

      before(:each) do
        allow(Dir).to receive(:mktmpdir).and_return(fake_dir)

        fake_itunestransporter = double
        allow(fake_itunestransporter).to receive(:upload).and_return(true)
        allow(FastlaneCore::ItunesTransporter).to receive(:new).and_return(fake_itunestransporter)

        # allow Manager.login method this time
        expect(fake_build_manager).to receive(:login).at_least(:once)

        # check for changelog or whats new!
        expect(fake_build_manager).to receive(:check_for_changelog_or_whats_new!).with(upload_options)

        expect(UI).to receive(:success).with("Ready to upload new build to TestFlight (App: #{fake_app_id})...")
        expect(UI).to receive(:success).with("Successfully uploaded the new binary to App Store Connect")

        fake_app = double
        expect(fake_app).to receive(:id).and_return(fake_app_id)
        expect(fake_build_manager).to receive(:app).and_return(fake_app)

        fake_build = double
        expect(fake_build).to receive(:app_version).and_return(fake_short_version)
        expect(fake_build).to receive(:version).and_return(fake_bundle_version)
        expect(UI).to receive(:message).with("If you want to skip waiting for the processing to be finished, use the `skip_waiting_for_build_processing` option")
        expect(UI).to receive(:message).with("Note that if `skip_waiting_for_build_processing` is used but a `changelog` is supplied, this process will wait for the build to appear on App Store Connect, update the changelog and then skip the remaining of the processing steps.")
        expect(FastlaneCore::BuildWatcher).to receive(:wait_for_build_processing_to_be_complete).and_return(fake_build)

        expect(fake_build_manager).to receive(:distribute).with(upload_options, build: fake_build)
      end

      context "ipa for ios platform" do
        let(:fake_app_platform) { "ios" }
        let(:fake_app_identifier) { "org.fastlane.very-capable-app" }
        let(:fake_short_version) { "1.0" }
        let(:fake_bundle_version) { "1" }
        let(:upload_options) do
          {
            ipa: File.expand_path("./fastlane_core/spec/fixtures/ipas/very-capable-app.ipa")
          }
        end

        before(:each) do
          allow(fake_build_manager).to receive(:fetch_app_platform).and_return(fake_app_platform)

          fake_ipauploadpackagebuilder = double
          allow(fake_ipauploadpackagebuilder).to receive(:generate).with(app_id: fake_app_id, ipa_path: upload_options[:ipa], package_path: fake_dir, platform: fake_app_platform, app_identifier: fake_app_identifier, short_version: fake_short_version, bundle_version: fake_bundle_version).and_return(true)
          allow(FastlaneCore::IpaUploadPackageBuilder).to receive(:new).and_return(fake_ipauploadpackagebuilder)
        end

        it "gets file analysed with IpaFileAnalyser" do
          expect(fake_build_manager).to receive(:fetch_app_id).and_return(fake_app_id).exactly(2).times
          expect(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_version).and_return(fake_short_version).exactly(2).times
          expect(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_build).and_return(fake_bundle_version).exactly(2).times
          expect(FastlaneCore::PkgFileAnalyser).to_not(receive(:fetch_app_version))
          expect(FastlaneCore::PkgFileAnalyser).to_not(receive(:fetch_app_build))

          fake_build_manager.upload(upload_options)
        end
      end

      context "pkg for osx platform" do
        let(:fake_app_platform) { "osx" }
        let(:fake_short_version) { nil }
        let(:fake_bundle_version) { nil }
        let(:upload_options) do
          {
            pkg: 'bar'
          }
        end

        before(:each) do
          allow(fake_build_manager).to receive(:fetch_app_platform).and_return(fake_app_platform)

          fake_pkguploadpackagebuilder = double
          allow(fake_pkguploadpackagebuilder).to receive(:generate).with(app_id: fake_app_id, pkg_path: upload_options[:pkg], package_path: fake_dir, platform: fake_app_platform).and_return(true)
          allow(FastlaneCore::PkgUploadPackageBuilder).to receive(:new).and_return(fake_pkguploadpackagebuilder)
        end

        it "gets file analysed with PkgFileAnalyser" do
          expect(fake_build_manager).to receive(:fetch_app_id).and_return(fake_app_id).exactly(2).times
          expect(FastlaneCore::IpaFileAnalyser).to_not(receive(:fetch_app_version))
          expect(FastlaneCore::IpaFileAnalyser).to_not(receive(:fetch_app_build))
          expect(FastlaneCore::PkgFileAnalyser).to receive(:fetch_app_version)
          expect(FastlaneCore::PkgFileAnalyser).to receive(:fetch_app_build)

          fake_build_manager.upload(upload_options)
        end
      end

      context "pkg for osx platform when both ipa and pkg are available" do
        let(:fake_app_platform) { "osx" }
        let(:fake_short_version) { nil }
        let(:fake_bundle_version) { nil }
        let(:upload_options) do
          {
            ipa: 'foo',
            pkg: 'bar'
          }
        end

        before(:each) do
          allow(fake_build_manager).to receive(:fetch_app_platform).and_return(fake_app_platform)

          fake_pkguploadpackagebuilder = double
          allow(fake_pkguploadpackagebuilder).to receive(:generate).with(app_id: fake_app_id, pkg_path: upload_options[:pkg], package_path: fake_dir, platform: fake_app_platform).and_return(true)
          allow(FastlaneCore::PkgUploadPackageBuilder).to receive(:new).and_return(fake_pkguploadpackagebuilder)

          expect(UI).to receive(:important).with("WARNING: Both `ipa` and `pkg` options are defined either explicitly or with default_value (build found in directory)")
          expect(UI).to receive(:important).with("Uploading `ipa` is preferred by default. Set `app_platform` to `osx` to force uploading `pkg`")
        end

        it "gets file analysed with PkgFileAnalyser" do
          expect(fake_build_manager).to receive(:fetch_app_id).and_return(fake_app_id).exactly(2).times
          expect(FastlaneCore::IpaFileAnalyser).to_not(receive(:fetch_app_version))
          expect(FastlaneCore::IpaFileAnalyser).to_not(receive(:fetch_app_build))
          expect(FastlaneCore::PkgFileAnalyser).to receive(:fetch_app_version)
          expect(FastlaneCore::PkgFileAnalyser).to receive(:fetch_app_build)

          fake_build_manager.upload(upload_options)
        end
      end

      context "ipa for ios platform when both ipa and pkg are available" do
        let(:fake_app_platform) { "ios" }
        let(:fake_app_identifier) { "org.fastlane.very-capable-app" }
        let(:fake_short_version) { "1.0" }
        let(:fake_bundle_version) { "1" }
        let(:upload_options) do
          {
            ipa: File.expand_path("./fastlane_core/spec/fixtures/ipas/very-capable-app.ipa"),
            pkg: 'bar'
          }
        end

        before(:each) do
          allow(fake_build_manager).to receive(:fetch_app_platform).and_return(fake_app_platform)

          fake_ipauploadpackagebuilder = double
          allow(fake_ipauploadpackagebuilder).to receive(:generate).with(app_id: fake_app_id, ipa_path: upload_options[:ipa], package_path: fake_dir, platform: fake_app_platform, app_identifier: fake_app_identifier, short_version: fake_short_version, bundle_version: fake_bundle_version).and_return(true)
          allow(FastlaneCore::IpaUploadPackageBuilder).to receive(:new).and_return(fake_ipauploadpackagebuilder)

          expect(UI).to receive(:important).with("WARNING: Both `ipa` and `pkg` options are defined either explicitly or with default_value (build found in directory)")
          expect(UI).to receive(:important).with("Uploading `ipa` is preferred by default. Set `app_platform` to `osx` to force uploading `pkg`")
        end

        it "gets file analysed with IpaFileAnalyser" do
          expect(fake_build_manager).to receive(:fetch_app_id).and_return(fake_app_id).exactly(2).times
          expect(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_version).and_return(fake_short_version).exactly(2).times
          expect(FastlaneCore::IpaFileAnalyser).to receive(:fetch_app_build).and_return(fake_bundle_version).exactly(2).times
          expect(FastlaneCore::PkgFileAnalyser).to_not(receive(:fetch_app_version))
          expect(FastlaneCore::PkgFileAnalyser).to_not(receive(:fetch_app_build))

          fake_build_manager.upload(upload_options)
        end
      end
    end
  end

  describe "#transporter_for_selected_team" do
    let(:fake_manager) { Pilot::BuildManager.new }
    let(:fake_team_api_key_json_path) do
      "./spaceship/spec/connect_api/fixtures/asc_key.json"
    end
    let(:fake_individual_api_key_json_path) do
      "./spaceship/spec/connect_api/fixtures/asc_individual_key.json"
    end

    let(:selected_team_id) { "123" }
    let(:selected_team_name) { "123 name" }
    let(:selected_team) do
      {
        "providerId" => selected_team_id,
        "name" => selected_team_name
      }
    end
    let(:unselected_team) do
      {
        "providerId" => "456",
        "name" => "456 name"
      }
    end

    it "with Team API Key and API token" do
      options = {}
      allow(Spaceship::ConnectAPI).to receive(:token).and_return(Spaceship::ConnectAPI::Token.from(filepath: fake_team_api_key_json_path))

      transporter = fake_manager.send(:transporter_for_selected_team, options)
      expect(transporter.instance_variable_get(:@jwt)).not_to(be_nil)
      expect(transporter.instance_variable_get(:@user)).to be_nil
      expect(transporter.instance_variable_get(:@password)).to be_nil
      expect(transporter.instance_variable_get(:@provider_short_name)).to be_nil
    end

    it "with Individual API Key" do
      options = { username: "josh" }
      allow(Spaceship::ConnectAPI).to receive(:token).and_return(Spaceship::ConnectAPI::Token.from(filepath: fake_individual_api_key_json_path))

      transporter = fake_manager.send(:transporter_for_selected_team, options)
      expect(transporter.instance_variable_get(:@jwt)).to(be_nil)
      expect(transporter.instance_variable_get(:@user)).to eq("josh")
      expect(transporter.instance_variable_get(:@password)).to eq("DELIVERPASS")
      expect(transporter.instance_variable_get(:@provider_short_name)).to(be_nil)
    end

    describe "with itc_provider" do
      it "with nil Spaceship::TunesClient" do
        options = { username: "josh", itc_provider: "123456789" }
        fake_manager.instance_variable_set(:@config, options)

        allow(Spaceship::ConnectAPI).to receive(:client).and_return(nil)

        transporter = fake_manager.send(:transporter_for_selected_team, options)
        expect(transporter.instance_variable_get(:@jwt)).to be_nil
        expect(transporter.instance_variable_get(:@user)).not_to(be_nil)
        expect(transporter.instance_variable_get(:@password)).not_to(be_nil) # Loaded with spec_helper
        expect(transporter.instance_variable_get(:@provider_short_name)).to eq("123456789")
      end

      it "with nil Spaceship::TunesClient" do
        options = { username: "josh", itc_provider: "123456789" }
        fake_manager.instance_variable_set(:@config, options)

        allow(Spaceship::ConnectAPI).to receive(:client).and_return(double)
        allow(Spaceship::ConnectAPI.client).to receive(:tunes_client).and_return(double)

        transporter = fake_manager.send(:transporter_for_selected_team, options)
        expect(transporter.instance_variable_get(:@jwt)).to be_nil
        expect(transporter.instance_variable_get(:@user)).not_to(be_nil)
        expect(transporter.instance_variable_get(:@password)).not_to(be_nil) # Loaded with spec_helper
        expect(transporter.instance_variable_get(:@provider_short_name)).to eq("123456789")
      end
    end

    it "with one team id" do
      options = { username: "josh" }
      fake_manager.instance_variable_set(:@config, options)

      fake_tunes_client = double('tunes client')
      allow(Spaceship::ConnectAPI).to receive(:client).and_return(double)
      allow(Spaceship::ConnectAPI.client).to receive(:tunes_client).and_return(fake_tunes_client)
      expect(fake_tunes_client).to receive(:teams).and_return([selected_team])

      transporter = fake_manager.send(:transporter_for_selected_team, options)
      expect(transporter.instance_variable_get(:@jwt)).to be_nil
      expect(transporter.instance_variable_get(:@user)).not_to(be_nil)
      expect(transporter.instance_variable_get(:@password)).not_to(be_nil) # Loaded with spec_helper
      expect(transporter.instance_variable_get(:@provider_short_name)).to be_nil
    end

    it "with inferred provider id" do
      options = { username: "josh" }
      fake_manager.instance_variable_set(:@config, options)

      fake_tunes_client = double('tunes client')
      allow(Spaceship::ConnectAPI).to receive(:client).and_return(double)
      allow(Spaceship::ConnectAPI.client).to receive(:tunes_client).and_return(fake_tunes_client)
      allow(fake_tunes_client).to receive(:team_id).and_return(selected_team_id)
      allow(fake_tunes_client).to receive(:teams).and_return([unselected_team, selected_team])

      allow_any_instance_of(FastlaneCore::ItunesTransporter).to receive(:provider_ids).and_return({ selected_team_name.to_s => selected_team_id })

      transporter = fake_manager.send(:transporter_for_selected_team, options)
      expect(transporter.instance_variable_get(:@jwt)).to be_nil
      expect(transporter.instance_variable_get(:@user)).not_to(be_nil)
      expect(transporter.instance_variable_get(:@password)).not_to(be_nil) # Loaded with spec_helper
      expect(transporter.instance_variable_get(:@provider_short_name)).to eq(selected_team_id)
    end
  end

  describe "#list" do
    let(:fake_build_manager) { Pilot::BuildManager.new }
    let(:fake_app_identifier) { "fake app_identifier" }
    let(:fake_app_name) { "fake app_name" }

    describe "what happens when listing the builds" do
      let(:fake_processing_builds) { [ double("fake processing_build", cf_build_short_version_string: "1.0.0", cf_build_version: "1234") ] }
      let(:fake_processed_builds) { [ double("fake processed_build", app_version: "1.1.0", version: "12345", beta_build_metrics: [ double("fake processed_build 1 metrics", install_count: 100) ]) ] }
      let(:fake_app) { double("fake app", get_build_deliveries: fake_processing_builds, get_builds: fake_processed_builds, name: fake_app_name) }

      before(:each) do
        expect(fake_build_manager).to receive(:app).and_return(fake_app).exactly(4).times
        expect(fake_app).to receive(:get_build_deliveries)
        expect(fake_app).to receive(:get_builds).with(includes: "betaBuildMetrics,preReleaseVersion", sort: "-uploadedDate")
        expect(fake_app).to receive(:name)
      end

      context "when apple_id and app_identifier both are not set" do
        let(:input_options_without_app_identifier) { {} }

        before(:each) do
          fake_build_manager.instance_variable_set(:@config, input_options_without_app_identifier)
          allow(fake_build_manager).to receive(:start).with(input_options_without_app_identifier)
          allow(Terminal::Table).to receive(:new).and_return("")
        end

        it "asks the user to enter the app_identifier manually" do
          expect(UI).to receive(:input).with("App Identifier: ")

          fake_build_manager.list(input_options_without_app_identifier)
        end

        it "sets the user entered app_identifier into input_options" do
          allow(UI).to receive(:input).and_return(fake_app_identifier)

          fake_build_manager.list(input_options_without_app_identifier)
          expect(input_options_without_app_identifier).to eq({ app_identifier: fake_app_identifier })
        end
      end

      context "when app_identifier is set" do
        let(:input_options_with_app_identifier) { { app_identifier: fake_app_identifier } }

        before(:each) do
          fake_build_manager.instance_variable_set(:@config, input_options_with_app_identifier)
          allow(fake_build_manager).to receive(:start).with(input_options_with_app_identifier)
        end

        it "prints the processing and processed both builds" do
          expect(FastlaneCore::PrintTable).to receive(:transform_output).with([["1.0.0", "1234"]]).and_return([])
          expect(FastlaneCore::PrintTable).to receive(:transform_output).with([["1.1.0", "12345", 100]]).and_return([])
          expect(Terminal::Table).to receive(:new).with({ headings: ["Version #", "Build #"], rows: [], title: "\e[32m#{fake_app_name} Processing Builds\e[0m" }).and_return("fake Terminal::Table fake_processing_builds")
          expect(Terminal::Table).to receive(:new).with({ headings: ["Version #", "Build #", "Installs"], rows: [], title: "\e[32m#{fake_app_name} Builds\e[0m" }).and_return("fake Terminal::Table fake_processed_builds")

          fake_build_manager.list(input_options_with_app_identifier)
        end
      end
    end
  end

  describe "#update_build_beta_details" do
    let(:fake_build_manager) { Pilot::BuildManager.new }
    let(:fake_build_id) { "fake build_id" }
    let(:fake_auto_notify) { "fake auto_notify" }

    describe "what happens when updating the beta build details" do
      context "when build_beta_detail has info" do
        let(:fake_build_beta_detail) { double("fake build_beta_detail", id: fake_build_id) }
        let(:fake_build) { double("fake build", build_beta_detail: fake_build_beta_detail) }

        context "when auto_notify_enabled is set" do
          let(:fake_info) do
            { auto_notify_enabled: fake_auto_notify }
          end

          it "patches the beta build details using Spaceship" do
            expect(Spaceship::ConnectAPI).to receive(:patch_build_beta_details).with({
              build_beta_details_id: fake_build_id,
              attributes: { autoNotifyEnabled: fake_auto_notify }
            })

            fake_build_manager.send(:update_build_beta_details, fake_build, fake_info)
          end
        end

        context "when auto_notify_enabled is not set" do
          let(:fake_info) do
            { foo: "fake foo" }
          end

          it "patches the beta build details using Spaceship" do
            expect(Spaceship::ConnectAPI).to receive(:patch_build_beta_details).with({
              build_beta_details_id: fake_build_id,
              attributes: {}
            })

            fake_build_manager.send(:update_build_beta_details, fake_build, fake_info)
          end
        end
      end

      context "when build_beta_detail is nil and auto_notify_enabled is set" do
        let(:fake_build) { double("fake build", build_beta_detail: nil) }
        let(:fake_info) do
          { auto_notify_enabled: fake_auto_notify }
        end

        it "logs the warning message 'Unable to auto notify testers'" do
          expect(UI).to receive(:important).with("Unable to auto notify testers as the build did not include beta detail information - this is likely a temporary issue on TestFlight.")

          fake_build_manager.send(:update_build_beta_details, fake_build, fake_info)
        end
      end
    end
  end
end
