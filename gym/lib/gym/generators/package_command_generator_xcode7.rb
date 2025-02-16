# encoding: utf-8

# from https://stackoverflow.com/a/9857493/445598
# because of
# `incompatible encoding regexp match (UTF-8 regexp with ASCII-8BIT string) (Encoding::CompatibilityError)`

require 'addressable/uri'
require 'tempfile'
require 'xcodeproj'

require 'fastlane_core/core_ext/cfpropertylist'
require_relative '../module'
require_relative '../error_handler'
require_relative '../export_method'
require_relative 'build_command_generator'

module Gym
  # Responsible for building the fully working xcodebuild command
  class PackageCommandGeneratorXcode7
    class << self
      def default_export_method
        Gym::ExportMethod::DEFAULT
      end

      def generate
        parts = ["/usr/bin/xcrun #{wrap_xcodebuild.shellescape} -exportArchive"]
        parts += options
        parts += pipe

        File.write(config_path, config_content) # overwrite every time. Could be optimized

        parts
      end

      def options
        config = Gym.config

        options = []
        options << "-exportOptionsPlist '#{config_path}'"
        options << "-archivePath #{BuildCommandGenerator.archive_path.shellescape}"
        options << "-exportPath '#{temporary_output_path}'"
        options << "-toolchain '#{config[:toolchain]}'" if config[:toolchain]
        options << config[:export_xcargs] if config[:export_xcargs]
        options << config[:xcargs] if config[:xcargs]

        options
      end

      def pipe
        [""]
      end

      # We export the ipa into this directory, as we can't specify the ipa file directly
      def temporary_output_path
        Gym.cache[:temporary_output_path] ||= Dir.mktmpdir('gym_output')
      end

      # Wrap xcodebuild to work around ipatool dependency to system ruby
      def wrap_xcodebuild
        require 'fileutils'
        @wrapped_xcodebuild_path ||= File.join(Gym::ROOT, "lib/assets/wrap_xcodebuild/xcbuild-safe.sh")
      end

      def ipa_path
        path = Gym.cache[:ipa_path]
        return path if path

        path = Dir[File.join(temporary_output_path, "*.ipa")].last
        # We need to process generic IPA
        if path
          # Try to find IPA file in the output directory, used when app thinning was not set
          Gym.cache[:ipa_path] = File.join(temporary_output_path, "#{Gym.config[:output_name]}.ipa")
          FileUtils.mv(path, Gym.cache[:ipa_path]) unless File.expand_path(path).casecmp?(File.expand_path(Gym.cache[:ipa_path]).downcase)
        elsif Dir.exist?(apps_path)
          # Try to find "generic" IPA file inside "Apps" folder, used when app thinning was set
          files = Dir[File.join(apps_path, "*.ipa")]
          # Generic IPA file doesn't have suffix so its name is the shortest
          path = files.min_by(&:length)
          Gym.cache[:ipa_path] = File.join(temporary_output_path, "#{Gym.config[:output_name]}.ipa")
          FileUtils.cp(path, Gym.cache[:ipa_path]) unless File.expand_path(path).casecmp?(File.expand_path(Gym.cache[:ipa_path]).downcase)
        else
          ErrorHandler.handle_empty_ipa unless path
        end

        Gym.cache[:ipa_path]
      end

      def binary_path
        path = Gym.cache[:binary_path]
        return path if path

        path = Dir[File.join(temporary_output_path, "*.pkg")].last
        app_path = Dir[File.join(temporary_output_path, "*.app")].last
        # We need to process generic PKG or APP
        if path
          # Try to find PKG file in the output directory, used when app thinning was not set
          Gym.cache[:binary_path] = File.join(temporary_output_path, "#{Gym.config[:output_name]}.pkg")
          FileUtils.mv(path, Gym.cache[:binary_path]) unless File.expand_path(path).casecmp(File.expand_path(Gym.cache[:binary_path]).downcase).zero?
        elsif Dir.exist?(apps_path)
          # Try to find "generic" PKG file inside "Apps" folder, used when app thinning was set
          files = Dir[File.join(apps_path, "*.pkg")]
          # Generic PKG file doesn't have suffix so its name is the shortest
          path = files.min_by(&:length)
          Gym.cache[:binary_path] = File.join(temporary_output_path, "#{Gym.config[:output_name]}.pkg")
          FileUtils.cp(path, Gym.cache[:binary_path]) unless File.expand_path(path).casecmp(File.expand_path(Gym.cache[:binary_path]).downcase).zero?
        elsif app_path
          # Try to find .app file in the output directory. This is used when macOS is set and .app is being generated.
          Gym.cache[:binary_path] = File.join(temporary_output_path, "#{Gym.config[:output_name]}.app")
          FileUtils.mv(app_path, Gym.cache[:binary_path]) unless File.expand_path(app_path).casecmp(File.expand_path(Gym.cache[:binary_path]).downcase).zero?
        else
          ErrorHandler.handle_empty_pkg unless path
        end

        Gym.cache[:binary_path]
      end

      # The path of the dSYM file for this app. Might be nil
      def dsym_path
        Dir[BuildCommandGenerator.archive_path + "/**/*.app.dSYM"].last
      end

      # The path the config file we use to sign our app
      def config_path
        Gym.cache[:config_path] ||= "#{Tempfile.new('gym_config').path}.plist"
        return Gym.cache[:config_path]
      end

      # The path to the manifest plist file
      def manifest_path
        Gym.cache[:manifest_path] ||= File.join(temporary_output_path, "manifest.plist")
      end

      # The path to the app-thinning plist file
      def app_thinning_path
        Gym.cache[:app_thinning] ||= File.join(temporary_output_path, "app-thinning.plist")
      end

      # The path to the App Thinning Size Report file
      def app_thinning_size_report_path
        Gym.cache[:app_thinning_size_report] ||= File.join(temporary_output_path, "App Thinning Size Report.txt")
      end

      # The path to the Apps folder
      def apps_path
        Gym.cache[:apps_path] ||= File.join(temporary_output_path, "Apps")
      end

      # The path to the Apps folder
      def asset_packs_path
        Gym.cache[:asset_packs_path] ||= File.join(temporary_output_path, "OnDemandResources")
      end

      def appstore_info_path
        Gym.cache[:appstore_info_path] ||= File.join(temporary_output_path, "AppStoreInfo.plist")
      end

      private

      def normalize_export_options(hash)
        # Normalize some values
        hash[:onDemandResourcesAssetPacksBaseURL] = Addressable::URI.encode(hash[:onDemandResourcesAssetPacksBaseURL]) if hash[:onDemandResourcesAssetPacksBaseURL]
        if hash[:manifest]
          hash[:manifest][:appURL] = Addressable::URI.encode(hash[:manifest][:appURL]) if hash[:manifest][:appURL]
          hash[:manifest][:displayImageURL] = Addressable::URI.encode(hash[:manifest][:displayImageURL]) if hash[:manifest][:displayImageURL]
          hash[:manifest][:fullSizeImageURL] = Addressable::URI.encode(hash[:manifest][:fullSizeImageURL]) if hash[:manifest][:fullSizeImageURL]
          hash[:manifest][:assetPackManifestURL] = Addressable::URI.encode(hash[:manifest][:assetPackManifestURL]) if hash[:manifest][:assetPackManifestURL]
        end
        hash
      end

      def read_export_options
        # Reads export options
        if Gym.config[:export_options]
          hash = normalize_export_options(Gym.config[:export_options])

          # Saves configuration for later use
          Gym.config[:export_method] ||= hash[:method] || default_export_method
          Gym.config[:include_symbols] = hash[:uploadSymbols] if Gym.config[:include_symbols].nil?
          Gym.config[:include_bitcode] = hash[:uploadBitcode] if Gym.config[:include_bitcode].nil?
          Gym.config[:export_team_id] ||= hash[:teamID]
        else
          hash = {}
          # Sets default values
          Gym.config[:export_method] ||= default_export_method
          Gym.config[:include_symbols] = true if Gym.config[:include_symbols].nil?
          Gym.config[:include_bitcode] = false if Gym.config[:include_bitcode].nil?
        end
        hash
      end

      def config_content
        hash = read_export_options

        # Overrides export options if needed
        hash[:method] = Gym.config[:export_method]
        if Gym.config[:export_method] == 'app-store'
          hash[:uploadSymbols] = (Gym.config[:include_symbols] ? true : false) unless Gym.config[:include_symbols].nil?
          hash[:uploadBitcode] = (Gym.config[:include_bitcode] ? true : false) unless Gym.config[:include_bitcode].nil?
        end

        # xcodebuild will not use provisioning profiles
        # if we don't specify signingStyle as manual
        if Helper.xcode_at_least?("9.0") && hash[:provisioningProfiles]
          hash[:signingStyle] = 'manual'
        end

        if Gym.config[:installer_cert_name] && (Gym.project.mac? || Gym.building_mac_catalyst_for_mac?)
          hash[:installerSigningCertificate] = Gym.config[:installer_cert_name]
        end

        hash[:teamID] = Gym.config[:export_team_id] if Gym.config[:export_team_id]

        UI.important("Generated plist file with the following values:")
        UI.command_output("-----------------------------------------")
        UI.command_output(JSON.pretty_generate(hash))
        UI.command_output("-----------------------------------------")
        if FastlaneCore::Globals.verbose?
          UI.message("This results in the following plist file:")
          UI.command_output("-----------------------------------------")
          UI.command_output(hash.to_plist)
          UI.command_output("-----------------------------------------")
        end

        hash.to_plist
      end

      def signing_style
        projects = Gym.project.project_paths
        project = projects.first
        xcodeproj = Xcodeproj::Project.open(project)
        xcodeproj.root_object.attributes["TargetAttributes"].each do |target, sett|
          return sett["ProvisioningStyle"].to_s.downcase
        end
      rescue => e
        UI.verbose(e.to_s)
        UI.error("Unable to read provisioning style from .pbxproj file.")
        return "automatic"
      end
    end
  end
end
