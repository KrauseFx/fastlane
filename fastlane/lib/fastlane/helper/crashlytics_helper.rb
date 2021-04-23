require 'shellwords'

module Fastlane
  module Helper
    class CrashlyticsHelper
      class << self
        def discover_crashlytics_path(params)
          path = params[:crashlytics_path]

          # Finding submit binary inside of given Crashlytics path (for backwards compatibility)
          if path
            if File.basename(path) != "submit"
              path = Dir[File.join(path, '**', 'submit')].last
              UI.verbose(":crashlytics_path passed through parameters did not point to a submit binary. Using this submit binary on that path instead: '#{path}'")
            else
              UI.verbose("Using :crashlytics_path passed in through parameters: '#{path}'")
            end
          end

          # Check for submit binary outside of Crashlytics.framework (for Crashlytics 3.4.1 and over)
          path ||= Dir["./Pods/Crashlytics/submit"].first

          # Check for submit binary in Crashlytics.framework (for Crashlytics 3.4.1 and under)
          path ||= Dir["./Pods/iOS/Crashlytics/Crashlytics.framework/submit"].last
          path ||= Dir["./**/Crashlytics.framework/submit"].last

          downcase_path = path ? path.downcase : nil
          if downcase_path && downcase_path.include?("pods") && downcase_path.include?("crashlytics.framework")
            UI.deprecated("Crashlytics has moved the submit binary outside of Crashlytics.framework directory as of 3.4.1. Please change :crashlytics_path to `<PODS_ROOT>/Crashlytics/submit`")
          end

          return path
        end

        def generate_ios_command(params)
          submit_binary = discover_crashlytics_path(params)
          unless submit_binary
            UI.user_error!("Couldn't find Crashlytics' submit binary in current directory. Make sure to add the 'Crashlytics' pod to your 'Podfile' and run `pod update`")
          end
          if File.basename(submit_binary) != "submit"
            UI.user_error!("Invalid crashlytics path was detected with '#{submit_binary}'. Path must point to the `submit` binary (example: './Pods/Crashlytics/submit')")
          end
          submit_binary = "Crashlytics.framework/submit" if Helper.test?

          command = []
          command << submit_binary.shellescape
          command << params[:api_token]
          command << params[:build_secret]
          command << "-ipaPath '#{params[:ipa_path]}'"
          command << "-emails '#{params[:emails]}'" if params[:emails]
          command << "-notesPath '#{params[:notes_path]}'" if params[:notes_path]
          command << "-groupAliases '#{params[:groups]}'" if params[:groups]
          command << "-notifications #{params[:notifications] ? 'YES' : 'NO'}"
          command << "-debug #{params[:debug] ? 'YES' : 'NO'}"

          return command
        end

        def generate_android_command(params, android_manifest_path)
          params[:crashlytics_path] = download_android_tools unless params[:crashlytics_path]

          UI.user_error!("The `crashlytics_path` must be a jar file for Android") unless params[:crashlytics_path].end_with?(".jar") || Helper.test?

          if ENV['JAVA_HOME'].nil?
            command = ["java"]
          else
            command = [File.join(ENV['JAVA_HOME'], "/bin/java").shellescape]
          end
          command << "-jar #{File.expand_path(params[:crashlytics_path])}"
          command << "-androidRes ."
          command << "-apiKey #{params[:api_token]}"
          command << "-apiSecret #{params[:build_secret]}"
          command << "-uploadDist #{File.expand_path(params[:apk_path]).shellescape}"
          command << "-androidManifest #{File.expand_path(android_manifest_path).shellescape}"

          # Optional
          command << "-betaDistributionEmails #{params[:emails].shellescape}" if params[:emails]
          command << "-betaDistributionReleaseNotesFilePath #{File.expand_path(params[:notes_path]).shellescape}" if params[:notes_path]
          command << "-betaDistributionGroupAliases #{params[:groups].shellescape}" if params[:groups]
          command << "-betaDistributionNotifications #{params[:notifications] ? 'true' : 'false'}"

          return command
        end

        def download_android_tools
          containing = File.join(File.expand_path("~/Library"), "CrashlyticsAndroid")
          zip_path = File.join(containing, "crashlytics-devtools.zip")
          jar_path = File.join(containing, "crashlytics-devtools.jar")

          url = "https://ssl-download-crashlytics-com.s3.amazonaws.com/android/ant/crashlytics.zip"
          require 'net/http'

          FileUtils.mkdir_p(containing)

          begin
            # Work around ruby defect, where HTTP#get_response and HTTP#post_form don't use ENV proxy settings
            # https://bugs.ruby-lang.org/issues/12724
            uri = URI(url)
            http_conn = Net::HTTP.new(uri.host, uri.port)
            http_conn.use_ssl = true
            result = http_conn.request_head(uri.path)

            # ETag is returned with quotes, which net/http does not handle. Clean that up
            etag = result['ETag'] && result['ETag'].tr('"', '')

            # This is a no-op if the current version on disk matches the file on S3
            return jar_path if File.exist?(zip_path) && etag == Digest::MD5.file(zip_path).hexdigest

            UI.important("Downloading Crashlytics Support Library - this might take a minute...")
            result = http_conn.request_get(uri.path)
            UI.error("#{result.message} (#{result.code})") unless result.kind_of?(Net::HTTPSuccess)
            File.write(zip_path, result.body)

            # Now unzip the file
            Action.sh("unzip -o '#{zip_path}' -d '#{containing}'")

            UI.user_error!("Couldn't find 'crashlytics-devtools.jar'") unless File.exist?(jar_path)

            UI.success("Successfully downloaded Crashlytics Support Library to '#{jar_path}'")
          rescue => ex
            UI.user_error!("Error fetching remote file: #{ex}")
          end

          return jar_path
        end

        def generate_android_manifest_tempfile
          # We have to generate an empty XML file to make the crashlytics CLI happy :)
          write_to_tempfile('<?xml version="1.0" encoding="utf-8"?><manifest></manifest>', 'xml')
        end

        def write_to_tempfile(value, tempfilename)
          require 'tempfile'

          Tempfile.new(tempfilename).tap do |t|
            t.write(value)
            t.close
          end
        end
      end
    end
  end
end

# java \
# -jar ~/Desktop/crashlytics-devtools.jar \
# -androidRes . \
# -uploadDist /Users/fkrause/AndroidStudioProjects/AppName/app/build/outputs/apk/app-release.apk \
# -androidManifest /Users/fkrause/Downloads/manifest.xml \
# -apiKey api_key \
# -apiSecret secret_key \

# -betaDistributionReleaseNotes "Yeah" \
# -betaDistributionEmails "something11@krausefx.com" \
# -betaDistributionGroupAliases "testgroup" \
# -betaDistributionNotifications false
# -projectPath . \
