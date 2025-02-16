require 'precheck/options'
require 'precheck/runner'
require 'fastlane_core/configuration/configuration'
require 'fastlane_core/ipa_upload_package_builder'
require 'fastlane_core/pkg_upload_package_builder'
require 'fastlane_core/itunes_transporter'
require 'spaceship'
require_relative 'html_generator'
require_relative 'submit_for_review'
require_relative 'upload_price_tier'
require_relative 'upload_metadata'
require_relative 'upload_screenshots'
require_relative 'sync_screenshots'
require_relative 'detect_values'

module Deliver
  class Runner
    attr_accessor :options

    def initialize(options, skip_auto_detection = {})
      self.options = options

      login

      Deliver::DetectValues.new.run!(self.options, skip_auto_detection)
      FastlaneCore::PrintTable.print_values(config: options, hide_keys: [:app], mask_keys: ['app_review_information.demo_password'], title: "deliver #{Fastlane::VERSION} Summary")
    end

    def login
      if (api_token = Spaceship::ConnectAPI::Token.from(hash: options[:api_key], filepath: options[:api_key_path]))
        UI.message("Creating authorization token for App Store Connect API")
        Spaceship::ConnectAPI.token = api_token
      elsif !Spaceship::ConnectAPI.token.nil?
        UI.message("Using existing authorization token for App Store Connect API")
      else
        # Username is now optional since addition of App Store Connect API Key
        # Force asking for username to prompt user if not already set
        options.fetch(:username, force_ask: true)

        # Team selection passed though FASTLANE_TEAM_ID and FASTLANE_TEAM_NAME environment variables
        # Prompts select team if multiple teams and none specified
        UI.message("Login to App Store Connect (#{options[:username]})")
        Spaceship::ConnectAPI.login(options[:username], nil, use_portal: false, use_tunes: true)
        UI.message("Login successful")
      end
    end

    def run
      if options[:verify_only]
        UI.important("Verify flag is set, only package validation will take place and no submission will be made")
        verify_binary
        return
      end

      verify_version if options[:app_version].to_s.length > 0 && !options[:skip_app_version_update]

      # Rejecting before upload meta
      # Screenshots cannot be updated or deleted if the app is in the "waiting for review" state
      reject_version_if_possible if options[:reject_if_possible]

      upload_metadata

      has_binary = (options[:ipa] || options[:pkg])
      if !options[:skip_binary_upload] && !options[:build_number] && has_binary
        upload_binary
      end

      UI.success("Finished the upload to App Store Connect") unless options[:skip_binary_upload]

      precheck_success = precheck_app
      submit_for_review if options[:submit_for_review] && precheck_success
    end

    # Make sure we pass precheck before uploading
    def precheck_app
      return true unless options[:run_precheck_before_submit]
      UI.message("Running precheck before submitting to review, if you'd like to disable this check you can set run_precheck_before_submit to false")

      if options[:submit_for_review]
        UI.message("Making sure we pass precheck 👮‍♀️ 👮 before we submit  🛫")
      else
        UI.message("Running precheck 👮‍♀️ 👮")
      end

      precheck_options = {
        default_rule_level: options[:precheck_default_rule_level],
        include_in_app_purchases: options[:precheck_include_in_app_purchases],
        app_identifier: options[:app_identifier]
      }

      if options[:api_key] || options[:api_key_path]
        if options[:precheck_include_in_app_purchases]
          UI.user_error!("Precheck cannot check In-app purchases with the App Store Connect API Key (yet). Exclude In-app purchases from precheck, disable the precheck step in your build step, or use Apple ID login")
        end

        precheck_options[:api_key] = options[:api_key]
        precheck_options[:api_key_path] = options[:api_key_path]
      else
        precheck_options[:username] = options[:username]
        precheck_options[:platform] = options[:platform]
      end

      precheck_config = FastlaneCore::Configuration.create(Precheck::Options.available_options, precheck_options)
      Precheck.config = precheck_config

      precheck_success = true
      begin
        precheck_success = Precheck::Runner.new.run
      rescue => ex
        UI.error("fastlane precheck just tried to inspect your app's metadata for App Store guideline violations and ran into a problem. We're not sure what the problem was, but precheck failed to finish. You can run it in verbose mode if you want to see the whole error. We'll have a fix out soon 🚀")
        UI.verbose(ex.inspect)
        UI.verbose(ex.backtrace.join("\n"))
      end

      return precheck_success
    end

    # Make sure the version on App Store Connect matches the one in the ipa
    # If not, the new version will automatically be created
    def verify_version
      app_version = options[:app_version]
      UI.message("Making sure the latest version on App Store Connect matches '#{app_version}'...")

      app = Deliver.cache[:app]

      platform = Spaceship::ConnectAPI::Platform.map(options[:platform])
      changed = app.ensure_version!(app_version, platform: platform)

      if changed
        UI.success("Successfully set the version to '#{app_version}'")
      else
        UI.success("'#{app_version}' is the latest version on App Store Connect")
      end
    end

    # Upload all metadata, screenshots, pricing information, etc. to App Store Connect
    def upload_metadata
      upload_metadata = UploadMetadata.new(options)
      upload_screenshots = UploadScreenshots.new

      # First, collect all the things for the HTML Report
      screenshots = upload_screenshots.collect_screenshots(options)
      upload_metadata.load_from_filesystem

      # Assign "default" values to all languages
      upload_metadata.assign_defaults

      # Validate
      validate_html(screenshots)

      # Commit
      upload_metadata.upload

      if options[:sync_screenshots]
        sync_screenshots = SyncScreenshots.new(app: Deliver.cache[:app], platform: Spaceship::ConnectAPI::Platform.map(options[:platform]))
        sync_screenshots.sync(screenshots)
      else
        upload_screenshots.upload(options, screenshots)
      end

      UploadPriceTier.new.upload(options)
    end

    # Verify the binary with App Store Connect
    def verify_binary
      UI.message("Verifying binary with App Store Connect")

      ipa_path = options[:ipa]
      pkg_path = options[:pkg]

      platform = options[:platform]
      transporter = transporter_for_selected_team

      case platform
      when "ios", "appletvos", "xros"
        package_path = FastlaneCore::IpaUploadPackageBuilder.new.generate(
          app_id: Deliver.cache[:app].id,
          ipa_path: ipa_path,
          package_path: "/tmp",
          platform: platform
        )
        result = transporter.verify(package_path: package_path, asset_path: ipa_path, platform: platform)
      when "osx"
        package_path = FastlaneCore::PkgUploadPackageBuilder.new.generate(
          app_id: Deliver.cache[:app].id,
          pkg_path: pkg_path,
          package_path: "/tmp",
          platform: platform
        )
        result = transporter.verify(package_path: package_path, asset_path: pkg_path, platform: platform)
      else
        UI.user_error!("No suitable file found for verify for platform: #{options[:platform]}")
      end

      unless result
        transporter_errors = transporter.displayable_errors
        UI.user_error!("Error verifying the binary file: \n #{transporter_errors}")
      end
    end

    # Upload the binary to App Store Connect
    def upload_binary
      UI.message("Uploading binary to App Store Connect")

      ipa_path = options[:ipa]
      pkg_path = options[:pkg]

      platform = options[:platform]
      transporter = transporter_for_selected_team

      case platform
      when "ios", "appletvos", "xros"
        package_path = FastlaneCore::IpaUploadPackageBuilder.new.generate(
          app_id: Deliver.cache[:app].id,
          ipa_path: ipa_path,
          package_path: "/tmp",
          platform: platform
        )
        result = transporter.upload(package_path: package_path, asset_path: ipa_path, platform: platform)
      when "osx"
        package_path = FastlaneCore::PkgUploadPackageBuilder.new.generate(
          app_id: Deliver.cache[:app].id,
          pkg_path: pkg_path,
          package_path: "/tmp",
          platform: platform
        )
        result = transporter.upload(package_path: package_path, asset_path: pkg_path, platform: platform)
      else
        UI.user_error!("No suitable file found for upload for platform: #{options[:platform]}")
      end

      unless result
        transporter_errors = transporter.displayable_errors
        file_type = platform == "osx" ? "pkg" : "ipa"
        UI.user_error!("Error uploading #{file_type} file: \n #{transporter_errors}")
      end
    end

    def reject_version_if_possible
      app = Deliver.cache[:app]
      platform = Spaceship::ConnectAPI::Platform.map(options[:platform])

      submission = app.get_in_progress_review_submission(platform: platform)
      if submission
        submission.cancel_submission
        UI.message("Review submission cancellation has been requested")

        # An app version won't get removed from review instantly
        # Polling until there is no longer an in-progress version
        loop do
          break if app.get_in_progress_review_submission(platform: platform).nil?
          UI.message("Waiting for cancellation to take effect...")
          sleep(15)
        end

        UI.success("Successfully cancelled previous submission!")
      end
    end

    def submit_for_review
      SubmitForReview.new.submit!(options)
    end

    private

    # If App Store Connect API token, use token.
    # If api_key is specified and it is an Individual API Key, don't use token but use username.
    # If itc_provider was explicitly specified, use it.
    # If there are multiple teams, infer the provider from the selected team name.
    # If there are fewer than two teams, don't infer the provider.
    def transporter_for_selected_team
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

      tunes_client = Spaceship::ConnectAPI.client.tunes_client

      generic_transporter = FastlaneCore::ItunesTransporter.new(options[:username], nil, false, options[:itc_provider], altool_compatible_command: true, api_key: api_key)
      return generic_transporter unless options[:itc_provider].nil? && tunes_client.teams.count > 1

      begin
        team = tunes_client.teams.find { |t| t['providerId'].to_s == tunes_client.team_id }
        name = team['name']
        provider_id = generic_transporter.provider_ids[name]
        UI.verbose("Inferred provider id #{provider_id} for team #{name}.")
        return FastlaneCore::ItunesTransporter.new(options[:username], nil, false, provider_id, altool_compatible_command: true, api_key: api_key)
      rescue => ex
        UI.verbose("Couldn't infer a provider short name for team with id #{tunes_client.team_id} automatically: #{ex}. Proceeding without provider short name.")
        return generic_transporter
      end
    end

    def validate_html(screenshots)
      return if options[:force]
      return if options[:skip_metadata] && options[:skip_screenshots]
      HtmlGenerator.new.run(options, screenshots)
    end
  end
end
