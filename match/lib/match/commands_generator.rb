require 'commander'
require 'fastlane_core'
require 'fastlane/version'

HighLine.track_eof = false

module Match
  class CommandsGenerator
    include Commander::Methods
    UI = FastlaneCore::UI

    def self.start
      self.new.run
    end

    def run
      program :name, 'match'
      program :version, Fastlane::VERSION
      program :description, Match::DESCRIPTION
      program :help, 'Author', 'Felix Krause <match@krausefx.com>'
      program :help, 'Website', 'https://fastlane.tools'
      program :help, 'GitHub', 'https://docs.fastlane.tools/actions/match/'
      program :help_formatter, :compact

      global_option('--verbose') { FastlaneCore::Globals.verbose = true }

      command :run do |c|
        c.syntax = 'fastlane match'
        c.description = Match::DESCRIPTION

        FastlaneCore::CommanderGenerator.new.generate(Match::Options.available_options, command: c)

        c.action do |args, options|
          if args.count > 0
            FastlaneCore::UI.user_error!("Please run `fastlane match [type]`, allowed values: development, adhoc, enterprise  or appstore")
          end

          params = FastlaneCore::Configuration.create(Match::Options.available_options, options.__hash__)
          params.load_configuration_file("Matchfile")
          Match::Runner.new.run(params)
        end
      end

      Match.environments.each do |type|
        command type do |c|
          c.syntax = "fastlane match #{type}"
          c.description = "Run match for a #{type} provisioning profile"

          FastlaneCore::CommanderGenerator.new.generate(Match::Options.available_options, command: c)

          c.action do |args, options|
            params = FastlaneCore::Configuration.create(Match::Options.available_options, options.__hash__)
            params.load_configuration_file("Matchfile") # this has to be done *before* overwriting the value
            params[:type] = type.to_s
            Match::Runner.new.run(params)
          end
        end
      end

      command :init do |c|
        c.syntax = 'fastlane match init'
        c.description = 'Create the Matchfile for you'
        c.action do |args, options|
          containing = FastlaneCore::Helper.fastlane_enabled_folder_path
          is_swift_fastfile = args.include?("swift")

          if is_swift_fastfile
            path = File.join(containing, "Matchfile.swift")
          else
            path = File.join(containing, "Matchfile")
          end

          if File.exist?(path)
            FastlaneCore::UI.user_error!("You already have a Matchfile in this directory (#{path})")
            return 0
          end

          Match::Setup.new.run(path, is_swift_fastfile: is_swift_fastfile)
        end
      end

      command :change_password do |c|
        c.syntax = 'fastlane match change_password'
        c.description = 'Re-encrypt all files with a different password'

        FastlaneCore::CommanderGenerator.new.generate(Match::Options.available_options, command: c)

        c.action do |args, options|
          params = FastlaneCore::Configuration.create(Match::Options.available_options, options.__hash__)
          params.load_configuration_file("Matchfile")

          Match::ChangePassword.update(params: params)
          UI.success "Successfully changed the password. Make sure to update the password on all your clients and servers"
        end
      end

      command :decrypt do |c|
        c.syntax = "fastlane match decrypt"
        c.description = "Decrypts the repository and keeps it on the filesystem"

        FastlaneCore::CommanderGenerator.new.generate(Match::Options.available_options, command: c)

        c.action do |args, options|
          params = FastlaneCore::Configuration.create(Match::Options.available_options, options.__hash__)
          params.load_configuration_file("Matchfile")
          decrypted_repo = Match::GitHelper.clone(params[:git_url],
                                                  params[:shallow_clone],
                                                  branch: params[:git_branch],
                                                  clone_branch_directly: params[:clone_branch_directly])
          UI.success "Repo is at: '#{decrypted_repo}'"
        end
      end

      command "nuke" do |c|
        # We have this empty command here, since otherwise the normal `match` command will be executed
        c.syntax = "fastlane match nuke"
        c.description = "Delete all certificates and provisioning profiles from the Apple Dev Portal"
        c.action do |args, options|
          FastlaneCore::UI.user_error!("Please run `fastlane match nuke [type], allowed values: distribution and development. For the 'adhoc' type, please use 'distribution' instead.")
        end
      end

      ["development", "distribution"].each do |type|
        command "nuke #{type}" do |c|
          c.syntax = "fastlane match nuke #{type}"
          c.description = "Delete all certificates and provisioning profiles from the Apple Dev Portal of the type #{type}"

          FastlaneCore::CommanderGenerator.new.generate(Match::Options.available_options, command: c)

          c.action do |args, options|
            params = FastlaneCore::Configuration.create(Match::Options.available_options, options.__hash__)
            params.load_configuration_file("Matchfile")
            Match::Nuke.new.run(params, type: type.to_s)
          end
        end
      end

      default_command :run

      run!
    end
  end
end
