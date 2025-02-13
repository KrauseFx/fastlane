require 'commander'
require 'fastlane/version'
require 'fastlane_core/ui/help_formatter'

require_relative 'options'
require_relative 'resign'
require_relative 'local_manage'
require_relative 'manager'

HighLine.track_eof = false

module Sigh
  class CommandsGenerator
    include Commander::Methods

    def self.start
      self.new.run
    end

    def run
      program :name, 'sigh'
      program :version, Fastlane::VERSION
      program :description, 'CLI for \'sigh\' - Because you would rather spend your time building stuff than fighting provisioning'
      program :help, 'Author', 'Felix Krause <sigh@krausefx.com>'
      program :help, 'Website', 'https://fastlane.tools'
      program :help, 'Documentation', 'https://docs.fastlane.tools/actions/sigh/'
      program :help_formatter, FastlaneCore::HelpFormatter

      global_option('--verbose') { FastlaneCore::Globals.verbose = true }
      global_option('--env STRING[,STRING2]', String, 'Add environment(s) to use with `dotenv`')

      command :renew do |c|
        c.syntax = 'fastlane sigh renew'
        c.description = 'Renews the certificate (in case it expired) and outputs the path to the generated file'

        FastlaneCore::CommanderGenerator.new.generate(Sigh::Options.available_options, command: c)

        c.action do |args, options|
          user_input = options.__hash__

          # The user might run sigh using
          #
          #   sigh development
          #
          #   sigh adhoc -u user@krausefx.com
          #
          # When the user runs this, it will use :development
          #
          #   sigh development --adhoc
          #
          case args.first
          when "development"
            user_input[:development] = true
            user_input.delete(:adhoc)
          when "adhoc"
            user_input[:adhoc] = true
            user_input.delete(:development)
          end

          Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, user_input)

          Sigh::Manager.start
        end
      end

      command :download_all do |c|
        c.syntax = 'fastlane sigh download_all'
        c.description = 'Downloads all valid provisioning profiles'

        c.option('--download_xcode_profiles', 'Only works with `fastlane sigh download_all` command: Also download Xcode managed provisioning profiles')

        FastlaneCore::CommanderGenerator.new.generate(Sigh::Options.available_options, command: c)

        c.action do |args, options|
          # Below is some custom code to get an extra flag that's only available
          # for the `fastlane sigh download_all` command and not for the `sigh` action
          user_hash = options.__hash__
          download_xcode_profiles = options.download_xcode_profiles

          if download_xcode_profiles == true
            user_hash.delete(:download_xcode_profiles)
          end
          Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, user_hash)
          Sigh::Manager.download_all(download_xcode_profiles: download_xcode_profiles)
        end
      end

      command :repair do |c|
        c.syntax = 'fastlane sigh repair'
        c.description = 'Repairs all expired or invalid provisioning profiles'

        FastlaneCore::CommanderGenerator.new.generate(Sigh::Options.available_options, command: c)

        c.action do |args, options|
          Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, options.__hash__)
          require 'sigh/repair'
          Sigh::Repair.new.repair_all
        end
      end

      command :resign do |c|
        c.syntax = 'fastlane sigh resign'
        c.description = 'Resigns an existing ipa file with the given provisioning profile'
        c.option('-i', '--signing_identity STRING', String, 'The signing identity to use. Must match the one defined in the provisioning profile.')
        c.option('-x', '--version_number STRING', String, 'Version number to force binary and all nested binaries to use. Changes both CFBundleShortVersionString and CFBundleVersion.')
        c.option('-p', '--provisioning_profile PATH', String, '(or BUNDLE_ID=PATH) The path to the provisioning profile which should be used. '\
                 'Can be provided multiple times if the application contains nested applications and app extensions, which need their own provisioning profile. '\
                 'The path may be prefixed with a identifier in order to determine which provisioning profile should be used on which app.',
                 &multiple_values_option_proc(c, "provisioning_profile", &proc { |value| value.split('=', 2) }))
        c.option('-d', '--display_name STRING', String, 'Display name to use')
        c.option('-e', '--entitlements PATH', String, 'The path to the entitlements file to use.' \
                 'Can be provided multiple times if the application contains nested applications and app extensions, which need their own entitlements file. ',
                 &multiple_values_option_proc(c, "entitlements"))
        c.option('--short_version STRING', String, 'Short version string to force binary and all nested binaries to use (CFBundleShortVersionString).')
        c.option('--bundle_version STRING', String, 'Bundle version to force binary and all nested binaries to use (CFBundleVersion).')
        c.option('--use_app_entitlements', 'Extract app bundle codesigning entitlements and combine with entitlements from new provisioning profile.')
        c.option('-g', '--new_bundle_id STRING', String, 'New application bundle ID (CFBundleIdentifier)')
        c.option('--keychain_path STRING', String, 'Path to the keychain that /usr/bin/codesign should use')

        c.action do |args, options|
          Sigh::Resign.new.run(options, args)
        end
      end

      command :manage do |c|
        c.syntax = 'fastlane sigh manage'
        c.description = 'Manage installed provisioning profiles on your system.'

        c.option('-f', '--force', 'Force remove all expired provisioning profiles. Required on CI.')
        c.option('-e', '--clean_expired', 'Remove all expired provisioning profiles.')

        c.option('-p', '--clean_pattern STRING', String, 'Remove any provisioning profiles that matches the regular expression.')
        c.example('Remove all "iOS Team Provisioning" provisioning profiles', 'fastlane sigh manage -p "iOS\ ?Team Provisioning Profile"')

        c.action do |args, options|
          Sigh::LocalManage.start(options, args)
        end
      end

      default_command(:renew)

      run!
    end

    def multiple_values_option_proc(command, name)
      proc do |value|
        value = yield(value) if block_given?
        option = command.proxy_options.find { |opt| opt[0] == name } || []
        values = option[1] || []
        values << value

        command.proxy_options.delete(option)
        command.proxy_options << [name, values]
      end
    end
  end
end
