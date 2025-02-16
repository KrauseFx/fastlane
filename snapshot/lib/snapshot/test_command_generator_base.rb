require 'fastlane_core/device_manager'
require_relative 'module'

module Snapshot
  class TestCommandGeneratorBase
    class << self
      def prefix
        ["set -o pipefail &&"]
      end

      # Path to the project or workspace as parameter
      # This will also include the scheme (if given)
      # @return [Array] The array with all the components to join
      def project_path_array
        proj = Snapshot.project.xcodebuild_parameters
        return proj if proj.count > 0
        UI.user_error!("No project/workspace found")
      end

      def options(language, locale)
        config = Snapshot.config
        result_bundle_path = resolve_result_bundle_path(language, locale) if config[:result_bundle]

        options = []
        options += project_path_array
        options << "-sdk '#{config[:sdk]}'" if config[:sdk]
        if derived_data_path && !options.include?("-derivedDataPath #{derived_data_path.shellescape}")
          options << "-derivedDataPath #{derived_data_path.shellescape}"
        end
        options << "-resultBundlePath '#{result_bundle_path}'" if result_bundle_path
        if FastlaneCore::Helper.xcode_at_least?(11)
          options << "-testPlan '#{config[:testplan]}'" if config[:testplan]
        end
        options << config[:xcargs] if config[:xcargs]

        # detect_values will ensure that these values are present as Arrays if
        # they are present at all
        options += config[:only_testing].map { |test_id| "-only-testing:#{test_id.shellescape}" } if config[:only_testing]
        options += config[:skip_testing].map { |test_id| "-skip-testing:#{test_id.shellescape}" } if config[:skip_testing]

        # Explicitly run simulator in Rosetta (needed for Xcode 14.3 and up)
        options << "ARCHS=x86_64" if config[:run_rosetta_simulator]

        return options
      end

      def build_settings(language, locale)
        config = Snapshot.config

        build_settings = []
        build_settings << "FASTLANE_SNAPSHOT=YES"
        build_settings << "FASTLANE_LANGUAGE=#{language}" if language
        build_settings << "FASTLANE_LOCALE=#{locale}" if locale
        build_settings << "TEST_TARGET_NAME=#{config[:test_target_name].shellescape}" if config[:test_target_name]

        return build_settings
      end

      def actions
        actions = []
        if Snapshot.config[:test_without_building]
          actions << "test-without-building"
        else
          actions << :clean if Snapshot.config[:clean]
          actions << :build # https://github.com/fastlane/fastlane/issues/2581
          actions << :test
        end
        return actions
      end

      def suffix
        return []
      end

      def find_device(device_name, os_version = Snapshot.config[:ios_version])
        # We might get this error message
        # > The requested device could not be found because multiple devices matched the request.
        #
        # This happens when you have multiple simulators for a given device type / iOS combination
        #   { platform:iOS Simulator, id:1685B071-AFB2-4DC1-BE29-8370BA4A6EBD, OS:9.0, name:iPhone 5 }
        #   { platform:iOS Simulator, id:A141F23B-96B3-491A-8949-813B376C28A7, OS:9.0, name:iPhone 5 }
        #
        simulators = FastlaneCore::DeviceManager.simulators
        # Sort devices with matching names by OS version, largest first, so that we can
        # pick the device with the newest OS in case an exact OS match is not available
        name_matches = simulators.find_all { |sim| sim.name.strip == device_name.strip }
                                 .sort_by { |sim| Gem::Version.new(sim.os_version) }
                                 .reverse
        return name_matches.find { |sim| sim.os_version == os_version } || name_matches.first
      end

      def device_udid(device_name, os_version = Snapshot.config[:ios_version])
        device = find_device(device_name, os_version)

        return device ? device.udid : nil
      end

      def derived_data_path
        Snapshot.cache[:derived_data_path] ||= (Snapshot.config[:derived_data_path] || Dir.mktmpdir("snapshot_derived"))
      end

      def resolve_result_bundle_path(language, locale)
        Snapshot.cache[:result_bundle_path] = {}
        language_key = locale || language

        unless Snapshot.cache[:result_bundle_path][language_key]
          ext = FastlaneCore::Helper.xcode_at_least?(11) ? '.xcresult' : '.test_result'
          path = File.join(Snapshot.config[:output_directory], "test_output", language_key, Snapshot.config[:scheme]) + ext
          if File.directory?(path)
            FileUtils.remove_dir(path)
          end
          Snapshot.cache[:result_bundle_path][language_key] = path
        end
        return Snapshot.cache[:result_bundle_path][language_key]
      end

      def initialize
        not_implemented(__method__)
      end

      def pipe(device_type, language, locale)
        not_implemented(__method__)
      end

      def destination(device_name)
        not_implemented(__method__)
      end

      def xcodebuild_log_path(device_type: nil, language: nil, locale: nil)
        not_implemented(__method__)
      end
    end
  end
end
