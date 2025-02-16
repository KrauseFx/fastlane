require 'commander'
require 'fastlane/version'
require 'fastlane_core/ui/help_formatter'

require_relative 'download_screenshots'
require_relative 'options'
require_relative 'module'
require_relative 'generate_summary'
require_relative 'runner'

HighLine.track_eof = false

module Deliver
  class CommandsGenerator
    include Commander::Methods

    def self.start
      self.new.run
    end

    def deliverfile_options(skip_verification: false)
      available_options = Deliver::Options.available_options
      return available_options unless skip_verification

      # These don't matter for downloading metadata, so verification can be skipped
      irrelevant_options_keys = [:ipa, :pkg, :app_rating_config_path]

      available_options.each do |opt|
        next unless irrelevant_options_keys.include?(opt.key)
        opt.verify_block = nil
        opt.conflicting_options = nil
      end

      return available_options
    end

    def self.force_overwrite_metadata?(options, path)
      res = options[:force]
      res ||= ENV["DELIVER_FORCE_OVERWRITE"] # for backward compatibility
      res ||= UI.confirm("Do you want to overwrite existing metadata on path '#{File.expand_path(path)}'?") if UI.interactive?
      res
    end

    # rubocop:disable Metrics/PerceivedComplexity
    def run
      program :name, 'deliver'
      program :version, Fastlane::VERSION
      program :description, Deliver::DESCRIPTION
      program :help, 'Author', 'Felix Krause <deliver@krausefx.com>'
      program :help, 'Website', 'https://fastlane.tools'
      program :help, 'Documentation', 'https://docs.fastlane.tools/actions/deliver/'
      program :help_formatter, FastlaneCore::HelpFormatter

      global_option('--verbose') { FastlaneCore::Globals.verbose = true }
      global_option('--env STRING[,STRING2]', String, 'Add environment(s) to use with `dotenv`')

      always_trace!

      command :run do |c|
        c.syntax = 'fastlane deliver'
        c.description = 'Upload metadata and binary to App Store Connect'

        FastlaneCore::CommanderGenerator.new.generate(deliverfile_options, command: c)

        c.action do |args, options|
          options = FastlaneCore::Configuration.create(deliverfile_options, options.__hash__)
          loaded = options.load_configuration_file("Deliverfile")

          # Check if we already have a deliver setup in the current directory
          loaded = true if options[:description] || options[:ipa] || options[:pkg]
          loaded = true if File.exist?(File.join(FastlaneCore::FastlaneFolder.path || ".", "metadata"))
          unless loaded
            if UI.confirm("No deliver configuration found in the current directory. Do you want to setup deliver?")
              is_swift = UI.confirm("Would you like to use Swift instead of Ruby?")
              require 'deliver/setup'
              Deliver::Runner.new(options) # to login...
              Deliver::Setup.new.run(options, is_swift: is_swift)
              return 0
            end
          end

          Deliver::Runner.new(options).run
        end
      end

      command :submit_build do |c|
        c.syntax = 'fastlane deliver submit_build'
        c.description = 'Submit a specific build-nr for review, use latest for the latest build'

        FastlaneCore::CommanderGenerator.new.generate(deliverfile_options, command: c)

        c.action do |args, options|
          options = FastlaneCore::Configuration.create(deliverfile_options, options.__hash__)
          options.load_configuration_file("Deliverfile")
          options[:submit_for_review] = true
          options[:build_number] = "latest" unless options[:build_number]
          Deliver::Runner.new(options).run
        end
      end

      command :init do |c|
        c.syntax = 'fastlane deliver init'
        c.description = 'Create the initial `deliver` configuration based on an existing app'

        FastlaneCore::CommanderGenerator.new.generate(deliverfile_options, command: c)

        c.action do |args, options|
          if File.exist?("Deliverfile") || File.exist?("fastlane/Deliverfile")
            UI.important("You already have a running deliver setup in this directory")
            return 0
          end

          require 'deliver/setup'

          options = FastlaneCore::Configuration.create(deliverfile_options, options.__hash__)
          options[:run_precheck_before_submit] = false # precheck doesn't need to run during init

          Deliver::Runner.new(options) # to login...
          Deliver::Setup.new.run(options)
        end
      end

      command :generate_summary do |c|
        c.syntax = 'fastlane deliver generate_summary'
        c.description = 'Generate HTML Summary without uploading/downloading anything'

        FastlaneCore::CommanderGenerator.new.generate(deliverfile_options, command: c)

        c.action do |args, options|
          options = FastlaneCore::Configuration.create(deliverfile_options, options.__hash__)
          options.load_configuration_file("Deliverfile")
          Deliver::Runner.new(options)
          html_path = Deliver::GenerateSummary.new.run(options)
          UI.success("Successfully generated HTML report at '#{html_path}'")
          system("open '#{html_path}'") unless options[:force]
        end
      end

      command :download_screenshots do |c|
        c.syntax = 'fastlane deliver download_screenshots'
        c.description = "Downloads all existing screenshots from App Store Connect and stores them in the screenshots folder"

        FastlaneCore::CommanderGenerator.new.generate(deliverfile_options, command: c)

        c.action do |args, options|
          options = FastlaneCore::Configuration.create(deliverfile_options(skip_verification: true), options.__hash__)
          options.load_configuration_file("Deliverfile")
          Deliver::Runner.new(options, skip_version: true) # to login...
          containing = FastlaneCore::Helper.fastlane_enabled_folder_path
          path = options[:screenshots_path] || File.join(containing, 'screenshots')
          Deliver::DownloadScreenshots.run(options, path)
        end
      end

      command :download_metadata do |c|
        c.syntax = 'fastlane deliver download_metadata'
        c.description = "Downloads existing metadata and stores it locally. This overwrites the local files."

        FastlaneCore::CommanderGenerator.new.generate(deliverfile_options, command: c)

        c.action do |args, options|
          options = FastlaneCore::Configuration.create(deliverfile_options(skip_verification: true), options.__hash__)
          options.load_configuration_file("Deliverfile")
          Deliver::Runner.new(options) # to login...
          containing = FastlaneCore::Helper.fastlane_enabled_folder_path
          path = options[:metadata_path] || File.join(containing, 'metadata')
          res = Deliver::CommandsGenerator.force_overwrite_metadata?(options, path)
          return 0 unless res

          require 'deliver/setup'
          app = Deliver.cache[:app]
          platform = Spaceship::ConnectAPI::Platform.map(options[:platform])
          if options[:use_live_version]
            v = app.get_live_app_store_version(platform: platform)
          else
            v = app.get_latest_app_store_version(platform: platform)
          end
          if options[:app_version].to_s.length > 0
            v = app.get_live_app_store_version(platform: platform) if v.version_string != options[:app_version]
            if v.nil? || v.version_string != options[:app_version]
              raise "Neither the current nor live version match specified app_version \"#{options[:app_version]}\""
            end
          end

          Deliver::Setup.new.generate_metadata_files(app, v, path, options)
        end
      end

      default_command(:run)

      run!
    end
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
