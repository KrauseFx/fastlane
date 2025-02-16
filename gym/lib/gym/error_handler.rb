# coding: utf-8

require 'fastlane_core/print_table'
require_relative 'module'
require_relative 'export_method'

module Gym
  # This classes methods are called when something goes wrong in the building process
  class ErrorHandler
    class << self
      # @param [String] The output of the errored build
      # This method should raise an exception in any case, as the return code indicated a failed build
      def handle_build_error(output)
        # The order of the handling below is important
        case output
        when /Your build settings specify a provisioning profile with the UUID/
          print("Invalid code signing settings")
          print("Your project defines a provisioning profile which doesn't exist on your local machine")
          print("You can use sigh (https://docs.fastlane.tools/actions/sigh/) to download and install the provisioning profile")
          print("Follow this guide: https://docs.fastlane.tools/codesigning/GettingStarted/")
        when /Provisioning profile does not match bundle identifier/
          print("Invalid code signing settings")
          print("Your project defines a provisioning profile that doesn't match the bundle identifier of your app")
          print("Make sure you use the correct provisioning profile for this app")
          print("Take a look at the output above for more information")
          print("You can follow this guide: https://docs.fastlane.tools/codesigning/GettingStarted/")
        when /provisioning profiles matching the bundle identifier .(.*)./ # the . around the (.*) are for the strange "
          print("You don't have the provisioning profile for '#{$1}' installed on the local machine")
          print("Make sure you have the profile on this computer and it's properly installed")
          print("You can use sigh (https://docs.fastlane.tools/actions/sigh/) to download and install the provisioning profile")
          print("Follow this guide: https://docs.fastlane.tools/codesigning/GettingStarted/")
        when /matching the bundle identifier .(.*). were found/ # the . around the (.*) are for the strange "
          print("You don't have a provisioning profile for the bundle identifier '#{$1}' installed on the local machine")
          print("Make sure you have the profile on this computer and it's properly installed")
          print("You can use sigh (https://docs.fastlane.tools/actions/sigh/) to download and install the provisioning profile")
          print("Follow this guide: https://docs.fastlane.tools/codesigning/GettingStarted/")

        # Insert more code signing specific errors here
        when /code signing is required/
          print("Your project settings define invalid code signing settings")
          print("To generate an ipa file you need to enable code signing for your project")
          print("Additionally make sure you have a code signing identity set")
          print("Follow this guide: https://docs.fastlane.tools/codesigning/GettingStarted/")
        when /US\-ASCII/
          print("Your shell environment is not correctly configured")
          print("Instead of UTF-8 your shell uses US-ASCII")
          print("Please add the following to your '~/.bashrc':")
          print("")
          print("       export LANG=en_US.UTF-8")
          print("       export LANGUAGE=en_US.UTF-8")
          print("       export LC_ALL=en_US.UTF-8")
          print("")
          print("You'll have to restart your shell session after updating the file.")
          print("If you are using zshell or another shell, make sure to edit the correct bash file.")
          print("For more information visit this stackoverflow answer:")
          print("https://stackoverflow.com/a/17031697/445598")
        end
        print_xcode_path_instructions
        print_xcode_version
        print_full_log_path
        print_environment_information
        print_build_error_instructions

        # This error is rather common and should be below the other (a little noisy) output
        case output
        when /Code signing is required for product/
          print("Seems like Xcode is not happy with the code signing setup")
          print("Please make sure to check out the raw `xcodebuild` output")
          UI.important(Gym::BuildCommandGenerator.xcodebuild_log_path)
          print("The very bottom of the file will tell you the raw Xcode error message")
          print("indicating on why the code signing step failed")
        end

        UI.build_failure!("Error building the application - see the log above", error_info: output)
      end

      # @param [Array] The output of the errored build (line by line)
      # This method should raise an exception in any case, as the return code indicated a failed build
      def handle_package_error(output)
        case output
        when /single\-bundle/
          print("Your project does not contain a single–bundle application or contains multiple products")
          print("Please read the documentation provided by Apple: https://developer.apple.com/library/ios/technotes/tn2215/_index.html")
        when /no signing identity matches '(.*)'/
          print("Could not find code signing identity '#{$1}'")
          print("Make sure the name of the code signing identity is correct")
          print("and it matches a locally installed code signing identity")
          print("You can pass the name of the code signing identity using the")
          print("`codesigning_identity` option")
        when /no provisioning profile matches '(.*)'/
          print("Could not find provisioning profile with the name '#{$1}'")
          print("Make sure the name of the provisioning profile is correct")
          print("and it matches a locally installed profile")
        when /mismatch between specified provisioning profile and signing identity/
          print("Mismatch between provisioning profile and code signing identity")
          print("This means, the specified provisioning profile was not created using")
          print("the specified certificate.")
          print("Run cert and sigh before gym to make sure to have all signing resources ready")
        when /requires a provisioning profile/
          print("No provisioning profile provided")
          print("Make sure to pass a valid provisioning for each required target")
          print("Check out the docs on how to fix this: https://docs.fastlane.tools/actions/gym/#export-options")
        # insert more specific code signing errors here
        when /Codesign check fails/
          print("A general code signing error occurred. Make sure you passed a valid")
          print("provisioning profile and code signing identity.")
        end
        print_xcode_version
        print_full_log_path
        print_environment_information
        print_build_error_instructions
        print_xcode9_plist_warning
        UI.build_failure!("Error packaging up the application", error_info: output)
      end

      def handle_empty_archive
        print("The generated archive is invalid, this can have various reasons:")
        print("Usually it's caused by the `Skip Install` option in Xcode, set it to `NO`")
        print("For more information visit https://developer.apple.com/library/ios/technotes/tn2215/_index.html")
        print("Also, make sure to have a valid code signing identity and provisioning profile installed")
        print("Follow this guide to setup code signing https://docs.fastlane.tools/codesigning/GettingStarted/")
        print("If your intention was only to export an ipa be sure to provide a valid archive at the archive path.")
        print("This error might also happen if your workspace/project file is not in the root directory of your project.")
        print("To workaround that issue, you can wrap your calls to gym with")
        print("`Dir.chdir('../path/to/dir/containing/proj') do`")
        print("For an example you can check out")
        print("https://github.com/artsy/emission-nebula/commit/44fe51a7fea8f7d52f0f77d6c3084827fe5dd59e")
        UI.build_failure!("Archive invalid")
      end

      def handle_empty_ipa
        UI.build_failure!("IPA invalid")
      end

      def handle_empty_pkg
        UI.build_failure!("PKG invalid")
      end

      private

      # Just to make things easier
      def print(text)
        UI.error(text)
      end

      def print_full_log_path
        return if Gym.config[:disable_xcpretty]

        log_path = Gym::BuildCommandGenerator.xcodebuild_log_path
        return unless File.exist?(log_path)

        # `xcodebuild` doesn't properly mark lines as failure reason or important information
        # so we assume that the last few lines show the error message that's relevant
        # (at least that's what was correct during testing)
        log_content = File.read(log_path).split("\n").last(5)
        log_content.each do |row|
          UI.command_output(row)
        end

        UI.message("")
        UI.error("⬆️  Check out the few lines of raw `xcodebuild` output above for potential hints on how to solve this error")
        UI.important("📋  For the complete and more detailed error log, check the full log at:")
        UI.important("📋  #{log_path}")
      end

      def print_xcode9_plist_warning
        return unless Helper.xcode_at_least?("9.0")

        # prevent crash in case of packaging error AND if you have set export_options to a path.
        return unless Gym.config[:export_options].kind_of?(Hash)

        export_options = Gym.config[:export_options] || {}
        provisioning_profiles = export_options[:provisioningProfiles] || []
        if provisioning_profiles.count == 0
          UI.error("Looks like no provisioning profile mapping was provided")
          UI.error("Please check the complete output, in particular the very top")
          UI.error("and see if you can find more information. You can also run fastlane")
          UI.error("with the `--verbose` flag.")
          UI.error("Alternatively you can provide the provisioning profile mapping manually")
          UI.error("https://docs.fastlane.tools/codesigning/xcode-project/#xcode-9-and-up")
        end
      end

      def print_xcode_version
        # lots of the times, the user didn't set the correct Xcode version to their Xcode path
        # since many users don't look at the table of summary before running a tool, let's make
        # sure they are aware of the Xcode version and SDK they're using
        values = {
          xcode_path: File.expand_path("../..", FastlaneCore::Helper.xcode_path),
          gym_version: Fastlane::VERSION,
          export_method: Gym.config[:export_method]
        }

        sdk_path = Gym.project.build_settings(key: "SDKROOT")
        values[:sdk] = File.basename(sdk_path) if sdk_path.to_s.length > 0

        FastlaneCore::PrintTable.print_values(config: values,
                                           hide_keys: [],
                                               title: "Build environment".yellow)
      end

      def print_xcode_path_instructions
        xcode_path = File.expand_path("../..", FastlaneCore::Helper.xcode_path)
        default_xcode_path = "/Applications/"

        xcode_installations_in_default_path = Dir[File.join(default_xcode_path, "Xcode*.app")]
        return unless xcode_installations_in_default_path.count > 1
        UI.message("")
        UI.important("Maybe the error shown is caused by using the wrong version of Xcode")
        UI.important("Found multiple versions of Xcode in '#{default_xcode_path}'")
        UI.important("Make sure you selected the right version for your project")
        UI.important("This build process was executed using '#{xcode_path}'")
        UI.important("If you want to update your Xcode path, either")
        UI.message("")

        UI.message("- Specify the Xcode version in your Fastfile")
        UI.command_output("xcversion(version: \"8.1\") # Selects Xcode 8.1.0")
        UI.message("")

        UI.message("- Specify an absolute path to your Xcode installation in your Fastfile")
        UI.command_output("xcode_select \"/Applications/Xcode8.app\"")
        UI.message("")

        UI.message("- Manually update the path using")
        UI.command_output("sudo xcode-select -s /Applications/Xcode.app")
        UI.message("")
      end

      def print_environment_information
        export_method = Gym.config[:export_method].to_s
        if [ExportMethod::DEBUGGING, ExportMethod::DEBUGGING_DEPRECATED].include?(export_method)
          UI.message("")
          UI.error("Your `export_method` in gym is defined as `#{export_method}`")
          UI.error("which might cause problems when signing your application")
          UI.error("Are you sure want to build and export for development?")
          UI.error("Please make sure to define the correct export methods when calling")
          UI.error("gym in your Fastfile or from the command line")
          UI.message("")
        elsif Gym.config[:export_options] && Gym.config[:export_options].kind_of?(Hash)
          # We want to tell the user if there is an obvious mismatch between the selected
          # `export_method` and the selected provisioning profiles
          selected_export_method = Gym.config[:export_method].to_s
          selected_provisioning_profiles = Gym.config[:export_options][:provisioningProfiles] || []
          # We could go ahead and find all provisioning profiles that match that name
          # and then get its type, however that's not 100% reliable, as we can't distinguish between
          # Ad Hoc and Development profiles for example.
          # As an easier and more obvious alternative, we'll take the provisioning profile names
          # and see if it contains the export_method name and see if there is a mismatch

          # The reason we have multiple variations of the spelling is that
          # the provisioning profile might be called anything below
          # There is no 100% good way to detect the profile type based on the name
          available_export_types = {
            "app-store" => ExportMethod::APP_STORE,
            "app store" => ExportMethod::APP_STORE,
            "appstore" => ExportMethod::APP_STORE,
            "enterprise" => ExportMethod::ENTERPRISE,
            "in-house" => ExportMethod::ENTERPRISE,
            "in house" => ExportMethod::ENTERPRISE,
            "inhouse" => ExportMethod::ENTERPRISE,
            "ad-hoc" => ExportMethod::RELEASE_TESTING,
            "adhoc" => ExportMethod::RELEASE_TESTING,
            "ad hoc" => ExportMethod::RELEASE_TESTING,
            "development" => ExportMethod::DEBUGGING
          }

          selected_provisioning_profiles.each do |current_bundle_identifier, current_profile_name|
            available_export_types.each do |current_to_try, matching_type|
              next unless current_profile_name.to_s.downcase.include?(current_to_try.to_s.downcase)

              # Check if there is a mismatch between the name and the selected export method
              # Example
              #
              #   current_profile_name = "me.themoji.app.beta App Store""
              #   current_to_try = "app store"
              #   matching_type = :appstore
              #   selected_export_method = "enterprise"
              #
              # As seen above, there is obviously a mismatch, the user selected an App Store
              # profile, but the export method that's being passed to Xcode is "enterprise"

              break if matching_type.to_s == selected_export_method
              UI.message("")
              UI.error("There seems to be a mismatch between your provided `export_method` in gym")
              UI.error("and the selected provisioning profiles. You passed the following options:")
              UI.important("  export_method:      #{selected_export_method}")
              UI.important("  Bundle identifier:  #{current_bundle_identifier}")
              UI.important("  Profile name:       #{current_profile_name}")
              UI.important("  Profile type:       #{matching_type}")
              UI.error("Make sure to either change the `export_method` passed from your Fastfile or CLI")
              UI.error("or select the correct provisioning profiles by updating your Xcode project")
              UI.error("or passing the profiles to use by using match or manually via the `export_options` hash")
              UI.message("")
              break
            end
          end
        end
      end

      # Indicate that code signing errors are not caused by fastlane
      # and that fastlane only runs `xcodebuild` commands
      def print_build_error_instructions
        UI.message("")
        UI.error("Looks like fastlane ran into a build/archive error with your project")
        UI.error("It's hard to tell what's causing the error, so we wrote some guides on how")
        UI.error("to troubleshoot build and signing issues: https://docs.fastlane.tools/codesigning/getting-started/")
        UI.error("Before submitting an issue on GitHub, please follow the guide above and make")
        UI.error("sure your project is set up correctly.")
        UI.error("fastlane uses `xcodebuild` commands to generate your binary, you can see the")
        UI.error("the full commands printed out in yellow in the above log.")
        UI.error("Make sure to inspect the output above, as usually you'll find more error information there")
        UI.message("")
      end
    end
  end
end
