require 'xcodeproj'

require_relative 'module'
require_relative 'export_method'

module Gym
  class CodeSigningMapping
    attr_accessor :project

    def initialize(project: nil)
      self.project = project
    end

    # @param primary_mapping [Hash] The preferred mapping (e.g. whatever the user provided)
    # @param secondary_mapping [Hash] (optional) The secondary mapping (e.g. whatever is detected from the Xcode project)
    # @param export_method [String] The method that should be preferred in case there is a conflict
    def merge_profile_mapping(primary_mapping: nil, secondary_mapping: nil, export_method: nil)
      final_mapping = (primary_mapping || {}).dup # for verbose output at the end of the method
      secondary_mapping ||= self.detect_project_profile_mapping # default to Xcode project

      final_mapping = final_mapping.transform_keys(&:to_sym)
      secondary_mapping = secondary_mapping.transform_keys(&:to_sym)

      # Now it's time to merge the (potentially) existing mapping
      #   (e.g. coming from `provisioningProfiles` of the `export_options` or from previous match calls)
      # with the secondary hash we just created (or was provided as parameter).
      # Both might include information about what profile to use
      # This is important as it might not be clear for the user that they have to call match for each app target
      # before adding this code, we'd only either use whatever we get from match, or what's defined in the Xcode project
      # With the code below, we'll make sure to take the best of it:
      #
      #   1) A provisioning profile is defined in the `primary_mapping`
      #   2) A provisioning profile is defined in the `secondary_mapping`
      #   3) On a conflict (app identifier assigned both in xcode and match)
      #     3.1) we'll choose whatever matches what's defined as the `export_method`
      #     3.2) If both include the right `export_method`, we'll prefer the one from `primary_mapping`
      #     3.3) If none has the right export_method, we'll use whatever is defined in the Xcode project
      #
      # To get a better sense of this, check out code_signing_spec.rb for some test cases

      secondary_mapping.each do |bundle_identifier, provisioning_profile|
        if final_mapping[bundle_identifier].nil?
          final_mapping[bundle_identifier] = provisioning_profile
        else
          if self.app_identifier_contains?(final_mapping[bundle_identifier], export_method) # 3.1 + 3.2 nothing to do in this case
          elsif self.app_identifier_contains?(provisioning_profile, export_method)
            # Also 3.1 (3.1 is "implemented" twice, as it could be either the primary, or the secondary being the one that matches)
            final_mapping[bundle_identifier] = provisioning_profile
          else
            # 3.3
            final_mapping[bundle_identifier] = provisioning_profile
          end
        end
      end

      UI.verbose("Merging provisioning profile mappings")
      UI.verbose("-------------------------------------")
      UI.verbose("Primary provisioning profile mapping:")
      UI.verbose(primary_mapping)
      UI.verbose("Secondary provisioning profile mapping:")
      UI.verbose(secondary_mapping)
      UI.verbose("Resulting in the following mapping:")
      UI.verbose(final_mapping)

      return final_mapping
    end

    # Helper method to remove "-" and " " and downcase app identifier
    # and compare if an app identifier includes a certain string
    # We do some `gsub`bing, because we can't really know the profile type, so we'll just look at the name and see if it includes
    # the export method (which it usually does, but with different notations)
    def app_identifier_contains?(str, contains)
      # Account for differences in export method and expected identifier names.
      case contains
      when ExportMethod::APP_STORE
        contains = 'app-store'
      end

      return str.to_s.gsub("-", "").gsub(" ", "").gsub("InHouse", "enterprise").downcase.include?(contains.to_s.gsub("-", "").gsub(" ", "").downcase)
    end

    def test_target?(build_settings)
      return (!build_settings["TEST_TARGET_NAME"].nil? || !build_settings["TEST_HOST"].nil?)
    end

    def same_platform?(sdkroot)
      destination = Gym.config[:destination].dup
      destination.slice!("generic/platform=")
      destination_sdkroot = []
      case destination
      when "macosx"
        destination_sdkroot = ["macosx"]
      when "iOS"
        destination_sdkroot = ["iphoneos", "watchos"]
      when "tvOS"
        destination_sdkroot = ["appletvos"]
      end

      # Catalyst projects will always have an "iphoneos" sdkroot
      # Need to force a same platform when trying to build as macos
      if Gym.building_mac_catalyst_for_mac?
        return true
      end

      return destination_sdkroot.include?(sdkroot)
    end

    def detect_configuration_for_archive
      extract_from_scheme = lambda do
        if self.project.workspace?
          available_schemes = self.project.workspace.schemes.reject { |k, v| v.include?("Pods/Pods.xcodeproj") }
          project_path = available_schemes[Gym.config[:scheme]]
        else
          project_path = self.project.path
        end

        if project_path
          scheme_path = File.join(project_path, "xcshareddata", "xcschemes", "#{Gym.config[:scheme]}.xcscheme")
          Xcodeproj::XCScheme.new(scheme_path).archive_action.build_configuration if File.exist?(scheme_path)
        end
      end

      configuration = Gym.config[:configuration]
      configuration ||= extract_from_scheme.call if Gym.config[:scheme]
      configuration ||= self.project.default_build_settings(key: "CONFIGURATION")
      return configuration
    end

    def detect_project_profile_mapping
      provisioning_profile_mapping = {}
      specified_configuration = detect_configuration_for_archive

      self.project.project_paths.each do |project_path|
        UI.verbose("Parsing project file '#{project_path}' to find selected provisioning profiles")
        UI.verbose("Finding provision profiles for '#{specified_configuration}'") if specified_configuration

        begin
          # Storing bundle identifiers with duplicate profiles
          # for informing user later on
          bundle_identifiers_with_duplicates = []

          project = Xcodeproj::Project.open(project_path)
          project.targets.each do |target|
            target.build_configuration_list.build_configurations.each do |build_configuration|
              current = build_configuration.build_settings
              next if test_target?(current)
              sdkroot = build_configuration.resolve_build_setting("SDKROOT", target)
              next unless same_platform?(sdkroot)
              next unless specified_configuration == build_configuration.name

              # Catalyst apps will have some build settings that will have a configuration
              # that is specific for macos so going to do our best to capture those
              #
              # There are other platform filters besides "[sdk=macosx*]" that we could use but
              # this is the default that Xcode will use so this will also be our default
              sdk_specifier = Gym.building_mac_catalyst_for_mac? ? "[sdk=macosx*]" : ""

              # Look for sdk specific bundle identifier (if set) and fallback to general configuration if none
              bundle_identifier = build_configuration.resolve_build_setting("PRODUCT_BUNDLE_IDENTIFIER#{sdk_specifier}", target)
              bundle_identifier ||= build_configuration.resolve_build_setting("PRODUCT_BUNDLE_IDENTIFIER", target)
              next unless bundle_identifier

              # Xcode prefixes "maccatalyst." if building a Catalyst app for mac and
              # if DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER is set to YES
              if Gym.building_mac_catalyst_for_mac? && build_configuration.resolve_build_setting("DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER", target) == "YES"
                bundle_identifier = "maccatalyst.#{bundle_identifier}"
              end

              # Look for sdk specific provisioning profile specifier (if set) and fallback to general configuration if none
              provisioning_profile_specifier = build_configuration.resolve_build_setting("PROVISIONING_PROFILE_SPECIFIER#{sdk_specifier}", target)
              provisioning_profile_specifier ||= build_configuration.resolve_build_setting("PROVISIONING_PROFILE_SPECIFIER", target)

              # Look for sdk specific provisioning profile uuid (if set) and fallback to general configuration if none
              provisioning_profile_uuid = build_configuration.resolve_build_setting("PROVISIONING_PROFILE#{sdk_specifier}", target)
              provisioning_profile_uuid ||= build_configuration.resolve_build_setting("PROVISIONING_PROFILE", target)

              has_profile_specifier = provisioning_profile_specifier.to_s.length > 0
              has_profile_uuid = provisioning_profile_uuid.to_s.length > 0

              # Stores bundle identifiers that have already been mapped to inform user
              if provisioning_profile_mapping[bundle_identifier] && (has_profile_specifier || has_profile_uuid)
                bundle_identifiers_with_duplicates << bundle_identifier
              end

              # Creates the mapping for a bundle identifier and profile specifier/uuid
              if has_profile_specifier
                provisioning_profile_mapping[bundle_identifier] = provisioning_profile_specifier
              elsif has_profile_uuid
                provisioning_profile_mapping[bundle_identifier] = provisioning_profile_uuid
              end
            end

            # Alerting user to explicitly specify a mapping if cannot be determined
            next if bundle_identifiers_with_duplicates.empty?
            UI.error("Couldn't automatically detect the provisioning profile mapping")
            UI.error("There were multiple profiles for bundle identifier(s): #{bundle_identifiers_with_duplicates.uniq.join(', ')}")
            UI.error("You need to provide an explicit mapping of what provisioning")
            UI.error("profile to use for each bundle identifier of your app")
          end
        rescue => ex
          # We catch errors here, as we might run into an exception on one included project
          # But maybe the next project actually contains the information we need
          if Helper.xcode_at_least?("9.0")
            UI.error("Couldn't automatically detect the provisioning profile mapping")
            UI.error("Since Xcode 9 you need to provide an explicit mapping of what")
            UI.error("provisioning profile to use for each target of your app")
            UI.error(ex)
            UI.verbose(ex.backtrace.join("\n"))
          end
        end
      end

      return provisioning_profile_mapping
    end
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
