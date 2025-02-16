require 'fastlane_core/fastlane_folder'
require 'fastlane_core/ipa_file_analyser'
require 'fastlane_core/pkg_file_analyser'
require 'spaceship/tunes/tunes'
require 'spaceship/tunes/application'

require_relative 'module'
require_relative 'languages'

module Deliver
  class DetectValues
    def run!(options, skip_params = {})
      Deliver.cache = {}

      find_platform(options)
      find_app_identifier(options)
      find_app(options)
      find_folders(options)
      ensure_folders_created(options)
      find_version(options) unless skip_params[:skip_version]

      verify_languages!(options)
    end

    def find_app_identifier(options)
      return if options[:app_identifier]

      if options[:ipa]
        identifier = FastlaneCore::IpaFileAnalyser.fetch_app_identifier(options[:ipa])
      elsif options[:pkg]
        identifier = FastlaneCore::PkgFileAnalyser.fetch_app_identifier(options[:pkg])
      end

      options[:app_identifier] = identifier if identifier.to_s.length > 0
      options[:app_identifier] ||= UI.input("The Bundle Identifier of your App: ")
    rescue => ex
      UI.error("#{ex.message}\n#{ex.backtrace.join('\n')}")
      UI.user_error!("Could not infer your App's Bundle Identifier")
    end

    def find_app(options)
      app_identifier = options[:app_identifier]
      app_id = options[:app] if app_identifier.to_s.empty?

      if !app_identifier.to_s.empty?
        app = Spaceship::ConnectAPI::App.find(app_identifier)
      elsif !app_id.kind_of?(Spaceship::ConnectAPI::App) && !app_id.to_s.empty?
        app = Spaceship::ConnectAPI::App.get(app_id: app_id)
      end

      Deliver.cache[:app] = app

      unless app
        UI.user_error!("Could not find app with app identifier '#{options[:app_identifier]}' in your App Store Connect account (#{options[:username]} - Team: #{Spaceship::Tunes.client.team_id})")
      end
    end

    def find_folders(options)
      containing = Helper.fastlane_enabled? ? FastlaneCore::FastlaneFolder.path : '.'
      options[:screenshots_path] ||= File.join(containing, 'screenshots')
      options[:metadata_path] ||= File.join(containing, 'metadata')
    end

    def ensure_folders_created(options)
      FileUtils.mkdir_p(options[:screenshots_path])
      FileUtils.mkdir_p(options[:metadata_path])
    end

    def find_version(options)
      return if options[:app_version]
      return if options[:skip_auto_detecting_app_version]

      if options[:ipa]
        options[:app_version] ||= FastlaneCore::IpaFileAnalyser.fetch_app_version(options[:ipa])
      elsif options[:pkg]
        options[:app_version] ||= FastlaneCore::PkgFileAnalyser.fetch_app_version(options[:pkg])
      end
    rescue => ex
      UI.error("#{ex.message}\n#{ex.backtrace.join('\n')}")
      UI.user_error!("Could not infer your app's version")
    end

    def find_platform(options)
      if options[:ipa]
        options[:platform] ||= FastlaneCore::IpaFileAnalyser.fetch_app_platform(options[:ipa])
      elsif options[:pkg]
        options[:platform] = 'osx'
      end
    end

    def verify_languages!(options)
      languages = options[:languages]
      return unless languages

      # 2020-08-24 - Available locales are not available as an endpoint in App Store Connect
      # Update with Spaceship::Tunes.client.available_languages.sort (as long as endpoint is available)
      all_languages = Deliver::Languages::ALL_LANGUAGES
      diff = languages - all_languages

      unless diff.empty?
        UI.user_error!("The following languages are invalid and cannot be activated: #{diff.join(',')}\n\nValid languages are: #{all_languages}")
      end
    end
  end
end
