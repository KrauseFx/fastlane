require 'tmpdir'
require 'terminal-table'
require 'emoji_regex'

require 'fastlane_core/itunes_transporter'
require 'fastlane_core/build_watcher'
require 'fastlane_core/ipa_upload_package_builder'
require_relative 'manager'

module Pilot
  # rubocop:disable Metrics/ClassLength
  class BuildManager < Manager
    def upload(options)
      # Only need to login before upload if no apple_id was given
      # 'login' will be deferred until before waiting for build processing
      should_login_in_start = options[:apple_id].nil?
      start(options, should_login: should_login_in_start)

      UI.user_error!("No ipa or pkg file given") if config[:ipa].nil? && config[:pkg].nil?

      if config[:ipa] && config[:pkg]
        UI.important("WARNING: Both `ipa` and `pkg` options are defined either explicitly or with default_value (build found in directory)")
        UI.important("Uploading `ipa` is preferred by default. Set `app_platform` to `osx` to force uploading `pkg`")
      end

      check_for_changelog_or_whats_new!(options)

      UI.success("Ready to upload new build to TestFlight (App: #{fetch_app_id})...")

      dir = Dir.mktmpdir

      platform = fetch_app_platform
      ipa_path = options[:ipa]
      if ipa_path && platform != 'osx'
        asset_path = ipa_path
        app_identifier = config[:app_identifier] || fetch_app_identifier
        short_version = config[:app_version] || FastlaneCore::IpaFileAnalyser.fetch_app_version(ipa_path)
        bundle_version = config[:build_number] || FastlaneCore::IpaFileAnalyser.fetch_app_build(ipa_path)
        package_path = FastlaneCore::IpaUploadPackageBuilder.new.generate(app_id: fetch_app_id,
                                                                      ipa_path: ipa_path,
                                                                  package_path: dir,
                                                                      platform: platform,
                                                                app_identifier: app_identifier,
                                                                 short_version: short_version,
                                                                bundle_version: bundle_version)
      else
        pkg_path = options[:pkg]
        asset_path = pkg_path
        package_path = FastlaneCore::PkgUploadPackageBuilder.new.generate(app_id: fetch_app_id,
                                                                        pkg_path: pkg_path,
                                                                    package_path: dir,
                                                                        platform: platform)
      end

      transporter = transporter_for_selected_team(options)
      result = transporter.upload(package_path: package_path, asset_path: asset_path, platform: platform)

      unless result
        transporter_errors = transporter.displayable_errors
        file_type = platform == "osx" ? "pkg" : "ipa"
        UI.user_error!("Error uploading #{file_type} file: \n #{transporter_errors}")
      end

      UI.success("Successfully uploaded the new binary to App Store Connect")

      # We will fully skip waiting for build processing *only* if no changelog is supplied
      # Otherwise we may partially wait until the build appears so the changelog can be set, and then bail.
      return_when_build_appears = false
      if config[:skip_waiting_for_build_processing]
        if config[:changelog].nil?
          UI.important("`skip_waiting_for_build_processing` used and no `changelog` supplied - skipping waiting for build processing")
          return
        else
          UI.important("`skip_waiting_for_build_processing` used and `changelog` supplied - will wait until build appears on App Store Connect, update the changelog and then skip the rest of the remaining of the processing steps.")
          return_when_build_appears = true
        end
      end

      # Calling login again here is needed if login was not called during 'start'
      login unless should_login_in_start

      if config[:skip_waiting_for_build_processing].nil?
        UI.message("If you want to skip waiting for the processing to be finished, use the `skip_waiting_for_build_processing` option")
        UI.message("Note that if `skip_waiting_for_build_processing` is used but a `changelog` is supplied, this process will wait for the build to appear on App Store Connect, update the changelog and then skip the remaining of the processing steps.")
      end

      latest_build = wait_for_build_processing_to_be_complete(return_when_build_appears)
      distribute(options, build: latest_build)
    end

    def has_changelog_or_whats_new?(options)
      # Look for legacy :changelog option
      has_changelog = !options[:changelog].nil?

      # Look for :whats_new in :localized_build_info
      unless has_changelog
        infos_by_lang = options[:localized_build_info] || []
        infos_by_lang.each do |k, v|
          next if has_changelog
          v ||= {}
          has_changelog = v.key?(:whats_new) || v.key?('whats_new')
        end
      end

      return has_changelog
    end

    def check_for_changelog_or_whats_new!(options)
      if !has_changelog_or_whats_new?(options) && options[:distribute_external] == true
        if UI.interactive?
          options[:changelog] = UI.input("No changelog provided for new build. You can provide a changelog using the `changelog` option. For now, please provide a changelog here:")
        else
          UI.user_error!("No changelog provided for new build. Please either disable `distribute_external` or provide a changelog using the `changelog` option")
        end
      end
    end

    def wait_for_build_processing_to_be_complete(return_when_build_appears = false)
      platform = fetch_app_platform
      if config[:ipa] && platform != "osx" && !config[:distribute_only]
        app_version = FastlaneCore::IpaFileAnalyser.fetch_app_version(config[:ipa])
        app_build = FastlaneCore::IpaFileAnalyser.fetch_app_build(config[:ipa])
      elsif config[:pkg] && !config[:distribute_only]
        app_version = FastlaneCore::PkgFileAnalyser.fetch_app_version(config[:pkg])
        app_build = FastlaneCore::PkgFileAnalyser.fetch_app_build(config[:pkg])
      else
        app_version = config[:app_version]
        app_build = config[:build_number]
      end

      latest_build = FastlaneCore::BuildWatcher.wait_for_build_processing_to_be_complete(
        app_id: app.id,
        platform: platform,
        app_version: app_version,
        build_version: app_build,
        poll_interval: config[:wait_processing_interval],
        timeout_duration: config[:wait_processing_timeout_duration],
        return_when_build_appears: return_when_build_appears,
        return_spaceship_testflight_build: false,
        select_latest: config[:distribute_only],
        wait_for_build_beta_detail_processing: true
      )

      unless latest_build.app_version == app_version && latest_build.version == app_build
        UI.important("Uploaded app #{app_version} - #{app_build}, but received build #{latest_build.app_version} - #{latest_build.version}.")
      end

      return latest_build
    end

    def distribute(options, build: nil)
      start(options)
      if config[:apple_id].to_s.length == 0 && config[:app_identifier].to_s.length == 0
        config[:app_identifier] = UI.input("App Identifier: ")
      end

      # Get latest uploaded build if no build specified
      if build.nil?
        app_version = config[:app_version]
        build_number = config[:build_number]
        if build_number.nil?
          if app_version.nil?
            UI.important("No build specified - fetching latest build")
          else
            UI.important("No build specified - fetching latest build for version #{app_version}")
          end
        end
        platform = Spaceship::ConnectAPI::Platform.map(fetch_app_platform)
        build ||= Spaceship::ConnectAPI::Build.all(app_id: app.id, version: app_version, build_number: build_number, sort: "-uploadedDate", platform: platform, limit: Spaceship::ConnectAPI::Platform::ALL.size).first
      end

      # Verify the build has all the includes that we need
      # and fetch a new build if not
      if build && (!build.app || !build.build_beta_detail || !build.pre_release_version)
        UI.important("Build did include information for app, build beta detail and pre release version")
        UI.important("Fetching a new build with all the information needed")
        build = Spaceship::ConnectAPI::Build.get(build_id: build.id)
      end

      # Error out if no build
      if build.nil?
        UI.user_error!("No build to distribute!")
      end

      # Update beta app meta info
      # 1. Demo account required
      # 2. App info
      # 3. Localized app  info
      # 4. Localized build info
      # 5. Auto notify enabled with config[:notify_external_testers]
      update_beta_app_meta(options, build)

      return if config[:skip_submission]
      if options[:reject_build_waiting_for_review]
        reject_build_waiting_for_review(build)
      end

      if options[:expire_previous_builds]
        expire_previous_builds(build)
      end

      if !build.ready_for_internal_testing? && options[:skip_waiting_for_build_processing]
        # Meta can be uploaded for a build still in processing
        # Returning before distribute if skip_waiting_for_build_processing
        # because can't distribute an app that is still processing
        return
      end

      distribute_build(build, options)
      type = options[:distribute_external] ? 'External' : 'Internal'
      UI.success("Successfully distributed build to #{type} testers 🚀")
    end

    def list(options)
      start(options)
      if config[:apple_id].to_s.length == 0 && config[:app_identifier].to_s.length == 0
        config[:app_identifier] = UI.input("App Identifier: ")
      end

      # Get processing builds
      build_deliveries = app.get_build_deliveries.map do |build_delivery|
        [
          build_delivery.cf_build_short_version_string,
          build_delivery.cf_build_version
        ]
      end

      # Get processed builds
      builds = app.get_builds(includes: "betaBuildMetrics,preReleaseVersion", sort: "-uploadedDate").map do |build|
        [
          build.app_version,
          build.version,
          (build.beta_build_metrics || []).map(&:install_count).compact.reduce(:+)
        ]
      end

      # Only show table if there are any build deliveries
      unless build_deliveries.empty?
        puts(Terminal::Table.new(
               title: "#{app.name} Processing Builds".green,
               headings: ["Version #", "Build #"],
               rows: FastlaneCore::PrintTable.transform_output(build_deliveries)
        ))
      end

      puts(Terminal::Table.new(
             title: "#{app.name} Builds".green,
             headings: ["Version #", "Build #", "Installs"],
             rows: FastlaneCore::PrintTable.transform_output(builds)
      ))
    end

    def update_beta_app_meta(options, build)
      # If demo_account_required is a parameter, it should added into beta_app_review_info
      unless options[:demo_account_required].nil?
        options[:beta_app_review_info] = {} if options[:beta_app_review_info].nil?
        options[:beta_app_review_info][:demo_account_required] = options[:demo_account_required]
      end

      if should_update_beta_app_review_info(options)
        update_review_detail(build, options[:beta_app_review_info])
      end

      if should_update_localized_app_information?(options)
        update_localized_app_review(build, options[:localized_app_info])
      elsif should_update_app_test_information?(options)
        default_info = {}
        default_info[:feedback_email] = options[:beta_app_feedback_email] if options[:beta_app_feedback_email]
        default_info[:description] = options[:beta_app_description] if options[:beta_app_description]
        begin
          update_localized_app_review(build, {}, default_info: default_info)
          UI.success("Successfully set the beta_app_feedback_email and/or beta_app_description")
        rescue => ex
          UI.user_error!("Could not set beta_app_feedback_email and/or beta_app_description: #{ex}")
        end
      end

      if should_update_localized_build_information?(options)
        update_localized_build_review(build, options[:localized_build_info])
      elsif should_update_build_information?(options)
        begin
          update_localized_build_review(build, {}, default_info: { whats_new: options[:changelog] })
          UI.success("Successfully set the changelog for build")
        rescue => ex
          UI.user_error!("Could not set changelog: #{ex}")
        end
      end

      if options[:notify_external_testers].nil?
        UI.important("Using App Store Connect's default for notifying external testers (which is true) - set `notify_external_testers` for full control")
      else
        update_build_beta_details(build, {
          auto_notify_enabled: options[:notify_external_testers]
        })
      end
    end

    def self.truncate_changelog(changelog)
      max_changelog_bytes = 4000
      if changelog
        changelog_bytes = changelog.unpack('C*').length
        if changelog_bytes > max_changelog_bytes
          UI.important("Changelog will be truncated since it exceeds Apple's #{max_changelog_bytes}-byte limit. It currently contains #{changelog_bytes} bytes.")
          new_changelog = ''
          new_changelog_bytes = 0
          max_changelog_bytes -= 3 # Will append '...' later.
          changelog.chars.each do |char|
            new_changelog_bytes += char.unpack('C*').length
            break if new_changelog_bytes >= max_changelog_bytes
            new_changelog += char
          end
          changelog = new_changelog + '...'
        end
      end
      changelog
    end

    def self.emoji_regex
      # EmojiRegex::RGIEmoji is now preferred over EmojiRegex::Regex which is deprecated as of 3.2.0
      # https://github.com/ticky/ruby-emoji-regex/releases/tag/v3.2.0
      return defined?(EmojiRegex::RGIEmoji) ? EmojiRegex::RGIEmoji : EmojiRegex::Regex
    end

    def self.strip_emoji(changelog)
      if changelog && changelog =~ emoji_regex
        changelog.gsub!(emoji_regex, "")
        UI.important("Emoji symbols have been removed from the changelog, since they're not allowed by Apple.")
      end
      changelog
    end

    def self.strip_less_than_sign(changelog)
      if changelog && changelog.include?("<")
        changelog.delete!("<")
        UI.important("Less than signs (<) have been removed from the changelog, since they're not allowed by Apple.")
      end
      changelog
    end

    def self.sanitize_changelog(changelog)
      changelog = strip_emoji(changelog)
      changelog = strip_less_than_sign(changelog)
      truncate_changelog(changelog)
    end

    private

    def describe_build(build)
      row = [build.train_version,
             build.build_version,
             build.install_count]

      return row
    end

    def should_update_beta_app_review_info(options)
      !options[:beta_app_review_info].nil?
    end

    def should_update_build_information?(options)
      options[:changelog].to_s.length > 0
    end

    def should_update_app_test_information?(options)
      options[:beta_app_description].to_s.length > 0 || options[:beta_app_feedback_email].to_s.length > 0
    end

    def should_update_localized_app_information?(options)
      !options[:localized_app_info].nil?
    end

    def should_update_localized_build_information?(options)
      !options[:localized_build_info].nil?
    end

    def reject_build_waiting_for_review(build)
      waiting_for_review_build = build.app.get_builds(
        filter: { "betaAppReviewSubmission.betaReviewState" => "WAITING_FOR_REVIEW,IN_REVIEW",
                  "expired" => false,
                  "preReleaseVersion.version" => build.pre_release_version.version },
        includes: "betaAppReviewSubmission,preReleaseVersion"
      ).first
      unless waiting_for_review_build.nil?
        UI.important("Another build is already in review. Going to remove that build and submit the new one.")
        UI.important("Canceling beta app review submission for build: #{waiting_for_review_build.app_version} - #{waiting_for_review_build.version}")
        waiting_for_review_build.expire!
        UI.success("Canceled beta app review submission for previous build: #{waiting_for_review_build.app_version} - #{waiting_for_review_build.version}")
      end
    end

    def expire_previous_builds(build)
      builds_to_expire = build.app.get_builds.reject do |asc_build|
        asc_build.id == build.id
      end

      builds_to_expire.each(&:expire!)
    end

    # If App Store Connect API token, use token.
    # If api_key is specified and it is an Individual API Key, don't use token but use username.
    # If itc_provider was explicitly specified, use it.
    # If there are multiple teams, infer the provider from the selected team name.
    # If there are fewer than two teams, don't infer the provider.
    def transporter_for_selected_team(options)
      # Use JWT auth
      api_token = Spaceship::ConnectAPI.token
      api_key = if options[:api_key].nil? && !api_token.nil?
                  # Load api key info if user set api_key_path, not api_key
                  { key_id: api_token.key_id, issuer_id: api_token.issuer_id, key: api_token.key_raw }
                elsif !options[:api_key].nil?
                  api_key = options[:api_key].transform_keys(&:to_sym).dup
                  # key is still base 64 style if api_key is loaded from option
                  api_key[:key] = Base64.decode64(api_key[:key]) if api_key[:is_key_content_base64]
                  api_key
                end

      # Currently no kind of transporters accept an Individual API Key. Use username and app-specific password instead.
      # See https://github.com/fastlane/fastlane/issues/22115
      is_individual_key = !api_key.nil? && api_key[:issuer_id].nil?
      if is_individual_key
        api_key = nil
        api_token = nil
      end

      unless api_token.nil?
        api_token.refresh! if api_token.expired?
        return FastlaneCore::ItunesTransporter.new(nil, nil, false, nil, api_token.text, altool_compatible_command: true, api_key: api_key)
      end

      # Otherwise use username and password
      tunes_client = Spaceship::ConnectAPI.client ? Spaceship::ConnectAPI.client.tunes_client : nil

      generic_transporter = FastlaneCore::ItunesTransporter.new(options[:username], nil, false, options[:itc_provider], altool_compatible_command: true, api_key: api_key)
      return generic_transporter if options[:itc_provider] || tunes_client.nil?
      return generic_transporter unless tunes_client.teams.count > 1

      begin
        team = tunes_client.teams.find { |t| t['providerId'].to_s == tunes_client.team_id }
        name = team['name']
        provider_id = generic_transporter.provider_ids[name]
        UI.verbose("Inferred provider id #{provider_id} for team #{name}.")
        return FastlaneCore::ItunesTransporter.new(options[:username], nil, false, provider_id, altool_compatible_command: true, api_key: api_key)
      rescue => ex
        STDERR.puts(ex.to_s)
        UI.verbose("Couldn't infer a provider short name for team with id #{tunes_client.team_id} automatically: #{ex}. Proceeding without provider short name.")
        return generic_transporter
      end
    end

    def distribute_build(uploaded_build, options)
      UI.message("Distributing new build to testers: #{uploaded_build.app_version} - #{uploaded_build.version}")

      # This is where we could add a check to see if encryption is required and has been updated
      uploaded_build = set_export_compliance_if_needed(uploaded_build, options)

      if options[:submit_beta_review] && (options[:groups] || options[:distribute_external])
        if uploaded_build.ready_for_beta_submission?
          uploaded_build.post_beta_app_review_submission
        else
          UI.message("Build #{uploaded_build.app_version} - #{uploaded_build.version} already submitted for review")
        end
      end

      if options[:groups]
        app = uploaded_build.app
        beta_groups = app.get_beta_groups.select do |group|
          options[:groups].include?(group.name)
        end

        unless beta_groups.empty?
          uploaded_build.add_beta_groups(beta_groups: beta_groups)
        end
      end

      if options[:distribute_external] && options[:groups].nil?
        # Legacy Spaceship::TestFlight API used to have a `default_external_group` that would automatically
        # get selected but this no longer exists with Spaceship::ConnectAPI
        UI.user_error!("You must specify at least one group using the `:groups` option to distribute externally")
      end

      true
    end

    def set_export_compliance_if_needed(uploaded_build, options)
      if uploaded_build.uses_non_exempt_encryption.nil?
        uses_non_exempt_encryption = options[:uses_non_exempt_encryption]
        attributes = { usesNonExemptEncryption: uses_non_exempt_encryption }

        Spaceship::ConnectAPI.patch_builds(build_id: uploaded_build.id, attributes: attributes)

        UI.important("Export compliance has been set to '#{uses_non_exempt_encryption}'. Need to wait for build to finishing processing again...")
        UI.important("Set 'ITSAppUsesNonExemptEncryption' in the 'Info.plist' to skip this step and speed up the submission")

        loop do
          build = Spaceship::ConnectAPI::Build.get(build_id: uploaded_build.id)
          return build unless build.missing_export_compliance?

          UI.message("Waiting for build #{uploaded_build.id} to process export compliance")
          sleep(5)
        end
      else
        return uploaded_build
      end
    end

    def update_review_detail(build, info)
      info = info.transform_keys(&:to_sym)

      attributes = {}
      attributes[:contactEmail] = info[:contact_email] if info.key?(:contact_email)
      attributes[:contactFirstName] = info[:contact_first_name] if info.key?(:contact_first_name)
      attributes[:contactLastName] = info[:contact_last_name] if info.key?(:contact_last_name)
      attributes[:contactPhone] = info[:contact_phone] if info.key?(:contact_phone)
      attributes[:demoAccountName] = info[:demo_account_name] if info.key?(:demo_account_name)
      attributes[:demoAccountPassword] = info[:demo_account_password] if info.key?(:demo_account_password)
      attributes[:demoAccountRequired] = info[:demo_account_required] if info.key?(:demo_account_required)
      attributes[:notes] = info[:notes] if info.key?(:notes)

      Spaceship::ConnectAPI.patch_beta_app_review_detail(app_id: build.app.id, attributes: attributes)
    end

    def update_localized_app_review(build, info_by_lang, default_info: nil)
      info_by_lang = info_by_lang.transform_keys(&:to_sym)

      if default_info
        info_by_lang.delete(:default)
      else
        default_info = info_by_lang.delete(:default)
      end

      # Initialize hash of lang codes with info_by_lang keys
      localizations_by_lang = {}
      info_by_lang.each_key do |key|
        localizations_by_lang[key] = nil
      end

      # Validate locales exist
      localizations = app.get_beta_app_localizations
      localizations.each do |localization|
        localizations_by_lang[localization.locale.to_sym] = localization
      end

      # Create or update localized app review info
      localizations_by_lang.each do |lang_code, localization|
        info = info_by_lang[lang_code]

        info = default_info unless info
        update_localized_app_review_for_lang(app, localization, lang_code, info) if info
      end
    end

    def update_localized_app_review_for_lang(app, localization, locale, info)
      attributes = {}
      attributes[:feedbackEmail] = info[:feedback_email] if info.key?(:feedback_email)
      attributes[:marketingUrl] = info[:marketing_url] if info.key?(:marketing_url)
      attributes[:privacyPolicyUrl] = info[:privacy_policy_url] if info.key?(:privacy_policy_url)
      attributes[:tvOsPrivacyPolicy] = info[:tv_os_privacy_policy_url] if info.key?(:tv_os_privacy_policy_url)
      attributes[:description] = info[:description] if info.key?(:description)

      if localization
        Spaceship::ConnectAPI.patch_beta_app_localizations(localization_id: localization.id, attributes: attributes)
      else
        attributes[:locale] = locale if locale
        Spaceship::ConnectAPI.post_beta_app_localizations(app_id: app.id, attributes: attributes)
      end
    end

    def update_localized_build_review(build, info_by_lang, default_info: nil)
      info_by_lang = info_by_lang.transform_keys(&:to_sym)

      if default_info
        info_by_lang.delete(:default)
      else
        default_info = info_by_lang.delete(:default)
      end

      # Initialize hash of lang codes with info_by_lang keys
      localizations_by_lang = {}
      info_by_lang.each_key do |key|
        localizations_by_lang[key] = nil
      end

      # Validate locales exist
      localizations = build.get_beta_build_localizations
      localizations.each do |localization|
        localizations_by_lang[localization.locale.to_sym] = localization
      end

      # Create or update localized app review info
      localizations_by_lang.each do |lang_code, localization|
        info = info_by_lang[lang_code]

        info = default_info unless info
        update_localized_build_review_for_lang(build, localization, lang_code, info) if info
      end
    end

    def update_localized_build_review_for_lang(build, localization, locale, info)
      attributes = {}
      attributes[:whatsNew] = self.class.sanitize_changelog(info[:whats_new]) if info.key?(:whats_new)

      if localization
        Spaceship::ConnectAPI.patch_beta_build_localizations(localization_id: localization.id, attributes: attributes)
      else
        attributes[:locale] = locale if locale
        Spaceship::ConnectAPI.post_beta_build_localizations(build_id: build.id, attributes: attributes)
      end
    end

    def update_build_beta_details(build, info)
      attributes = {}
      attributes[:autoNotifyEnabled] = info[:auto_notify_enabled] if info.key?(:auto_notify_enabled)
      build_beta_detail = build.build_beta_detail

      if build_beta_detail
        Spaceship::ConnectAPI.patch_build_beta_details(build_beta_details_id: build_beta_detail.id, attributes: attributes)
      else
        if attributes[:autoNotifyEnabled]
          UI.important("Unable to auto notify testers as the build did not include beta detail information - this is likely a temporary issue on TestFlight.")
        end
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
