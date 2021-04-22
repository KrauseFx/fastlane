describe Fastlane do
  describe Fastlane::FastFile do
    build_log_path = File.expand_path("#{FastlaneCore::Helper.buildlog_path}/fastlane/xcbuild/#{Time.now.strftime('%F')}/#{Process.pid}/xcodebuild.log")

    describe "Xcodebuild Integration" do
      before :each do
        Fastlane::Actions.lane_context.delete(:IPA_OUTPUT_PATH)
        Fastlane::Actions.lane_context.delete(:XCODEBUILD_ARCHIVE)
      end

      it "works with all parameters" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xcodebuild(
            analyze: true,
            archive: true,
            build: true,
            clean: true,
            install: true,
            installsrc: true,
            test: true,
            arch: 'architecture',
            alltargets: true,
            archive_path: './build/MyApp.xcarchive',
            configuration: 'Debug',
            derivedDataPath: '/derived/data/path',
            destination: 'name=iPhone 5s,OS=8.1',
            destination_timeout: 240,
            dry_run: true,
            enable_address_sanitizer: true,
            enable_thread_sanitizer: false,
            enable_code_coverage: true,
            export_archive: true,
            export_format: 'ipa',
            export_installer_identity: true,
            export_options_plist: '/path/to/plist',
            export_path: './build/MyApp',
            export_profile: 'MyApp Distribution',
            export_signing_identity: 'Distribution: MyCompany, LLC',
            export_with_original_signing_identity: true,
            hide_shell_script_environment: true,
            jobs: 5,
            parallelize_targets: true,
            keychain: '/path/to/My.keychain',
            project: 'MyApp.xcodeproj',
            result_bundle_path: '/result/bundle/path',
            scheme: 'MyApp',
            sdk: 'iphonesimulator',
            skip_unavailable_actions: true,
            target: 'MyAppTarget',
            toolchain: 'toolchain name',
            workspace: 'MyApp.xcworkspace',
            xcconfig: 'my.xcconfig',
            buildlog_path: 'mypath',
            raw_buildlog: false,
            xcpretty_output: 'test',
            xcargs: '-newArgument YES'
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && xcodebuild analyze archive build clean install installsrc test -arch \"architecture\" " \
          "-alltargets -archivePath \"./build/MyApp.xcarchive\" -configuration \"Debug\" -derivedDataPath \"/derived/data/path\" " \
          "-destination \"name=iPhone 5s,OS=8.1\" -destination-timeout \"240\" -dry-run -exportArchive -exportFormat \"ipa\" " \
          "-exportInstallerIdentity -exportOptionsPlist \"/path/to/plist\" -exportPath \"./build/MyApp\" -exportProvisioningProfile " \
          "\"MyApp Distribution\" -exportSigningIdentity \"Distribution: MyCompany, LLC\" -exportWithOriginalSigningIdentity " \
          "-hideShellScriptEnvironment -jobs \"5\" -parallelizeTargets OTHER_CODE_SIGN_FLAGS=\"--keychain /path/to/My.keychain\" -project " \
          "\"MyApp.xcodeproj\" -resultBundlePath \"/result/bundle/path\" -scheme \"MyApp\" -sdk \"iphonesimulator\" -skipUnavailableActions -target " \
          "\"MyAppTarget\" -toolchain \"toolchain name\" -workspace \"MyApp.xcworkspace\" -xcconfig \"my.xcconfig\" -newArgument YES -enableAddressSanitizer " \
          "\"YES\" -enableThreadSanitizer \"NO\" -enableCodeCoverage \"YES\" | tee 'mypath/xcodebuild.log' | xcpretty --color --test"
        )
      end

      it "works with a destination list" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xcodebuild(
            destination: [
              'name=iPhone 5s,OS=8.1',
              'name=iPhone 4,OS=7.1',
            ],
            destination_timeout: 240,
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace'
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-destination \"name=iPhone 5s,OS=8.1\" " \
          + "-destination \"name=iPhone 4,OS=7.1\" " \
          + "-destination-timeout \"240\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "| tee '#{build_log_path}' | xcpretty --color --simple"
        )
      end

      it "works with build settings" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xcodebuild(
            build_settings: {
              'CODE_SIGN_IDENTITY' => 'iPhone Developer: Josh',
              'JOBS' => 16,
              'PROVISIONING_PROFILE' => 'JoshIsCoolProfile',
              'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) NDEBUG=1'
            },
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace'
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "CODE_SIGN_IDENTITY=\"iPhone Developer: Josh\" " \
          + "JOBS=\"16\" " \
          + "PROVISIONING_PROFILE=\"JoshIsCoolProfile\" " \
          + "GCC_PREPROCESSOR_DEFINITIONS=\"\\$(inherited) NDEBUG=1\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "| tee '#{build_log_path}' | xcpretty --color --simple"
        )

        # expect(result).to include('CODE_SIGN_IDENTITY="iPhone Developer: Josh"')
        # expect(result).to include('JOBS="16"')
        # expect(result).to include('PROVISIONING_PROFILE="JoshIsCoolProfile"')
      end

      it "works with export_options_plist as hash" do
        FastlaneSpec::Env.with_env_values(XCODE_BUILD_PATH: "./build-dir") do
          result = Fastlane::FastFile.new.parse("lane :test do
            xcodebuild(
              build_path: './build-dir/',
              archive_path: './build-dir/MyApp.xcarchive',
              export_archive: true,
              export_options_plist: {
                method: \"ad-hoc\",
                thinning: \"<thin-for-all-variants>\",
                teamID: \"1234567890\",
                manifest: {
                  appURL: \"https://example.com/path/MyApp Name.ipa\",
                  displayImageURL: \"https://example.com/display image.png\",
                  fullSizeImageURL: \"https://example.com/fullSize image.png\",
                },
              }
            )
          end").runner.execute(:test)

          expect(result).to start_with(
            "set -o pipefail && " \
            + "xcodebuild " \
            + "-archivePath \"./build-dir/MyApp.xcarchive\" " \
            + "-exportArchive " \
          )
          expect(result).to match(/-exportOptionsPlist \".*\.plist\"/)
          expect(result).to end_with(
            "-exportPath \"./build-dir/MyApp\" " \
            + "| tee '#{build_log_path}' | xcpretty --color --simple"
          )
        end
      end

      it "works with export_options_plist as hash which contains no manifest" do
        FastlaneSpec::Env.with_env_values(XCODE_BUILD_PATH: "./build-dir") do
          result = Fastlane::FastFile.new.parse("lane :test do
            xcodebuild(
              archive_path: './build-dir/MyApp.xcarchive',
              export_archive: true,
              export_options_plist: {
                method: \"ad-hoc\",
                thinning: \"<thin-for-all-variants>\",
                teamID: \"1234567890\",
              }
            )
          end").runner.execute(:test)

          expect(result).to start_with(
            "set -o pipefail && " \
            + "xcodebuild " \
            + "-archivePath \"./build-dir/MyApp.xcarchive\" " \
            + "-exportArchive " \
          )
          expect(result).to match(/-exportOptionsPlist \".*\.plist\"/)
          expect(result).to end_with(
            "-exportPath \"./build-dir/MyApp\" " \
            + "| tee '#{build_log_path}' | xcpretty --color --simple"
          )
        end
      end

      it "when archiving, should cache the archive path for a later export step" do
        Fastlane::FastFile.new.parse("lane :test do
        xcodebuild(
          archive: true,
          archive_path: './build/MyApp.xcarchive',
          scheme: 'MyApp',
          workspace: 'MyApp.xcworkspace'
        )
      end").runner.execute(:test)

        expect(Fastlane::Actions.lane_context[:XCODEBUILD_ARCHIVE]).to eq("./build/MyApp.xcarchive")
      end

      it "when exporting, should use the cached archive path from a previous archive step" do
        result = Fastlane::FastFile.new.parse("lane :test do
        xcodebuild(
          archive: true,
          archive_path: './build-dir/MyApp.xcarchive',
          scheme: 'MyApp',
          workspace: 'MyApp.xcworkspace'
        )

        xcodebuild(
          export_archive: true,
          export_path: './build-dir/MyApp'
        )
      end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-exportArchive " \
          + "-exportPath \"./build-dir/MyApp\" " \
          + "-archivePath \"./build-dir/MyApp.xcarchive\" " \
          + "| tee '#{build_log_path}' | xcpretty --color --simple"
        )
      end

      it "when exporting, should cache the ipa path for a later deploy step" do
        Fastlane::FastFile.new.parse("lane :test do
          xcodebuild(
            archive_path: './build-dir/MyApp.xcarchive',
            export_archive: true,
            export_path: './build-dir/MyApp'
          )
        end").runner.execute(:test)

        expect(Fastlane::Actions.lane_context[:IPA_OUTPUT_PATH]).to eq("./build-dir/MyApp.ipa")
      end

      it "when exporting Mac app, should cache the app path for a later deploy step" do
        Fastlane::FastFile.new.parse("lane :test do
          xcodebuild(
            archive_path: './build-dir/MyApp.xcarchive',
            export_archive: true,
            export_format: 'app',
            export_path: './build-dir/MyApp'
          )
        end").runner.execute(:test)

        expect(Fastlane::Actions.lane_context[:IPA_OUTPUT_PATH]).to eq("./build-dir/MyApp.app")
      end

      context "when using environment variables" do
        it "can archive" do
          FastlaneSpec::Env.with_env_values(
            XCODE_BUILD_PATH: './build-dir/',
            XCODE_SCHEME: 'MyApp',
            XCODE_WORKSPACE: 'MyApp.xcworkspace'
          ) do
            result = Fastlane::FastFile.new.parse("lane :test do
              xcodebuild(
                archive: true
              )
            end").runner.execute(:test)

            expect(result).to eq(
              "set -o pipefail && " \
              + "xcodebuild " \
              + "archive " \
              + "-scheme \"MyApp\" " \
              + "-workspace \"MyApp.xcworkspace\" " \
              + "-archivePath \"./build-dir/MyApp.xcarchive\" " \
              + "| tee '#{build_log_path}' | xcpretty --color --simple"
            )
          end
        end

        it "can export" do
          FastlaneSpec::Env.with_env_values(
            XCODE_BUILD_PATH: './build-dir/',
            XCODE_SCHEME: nil,
            XCODE_WORKSPACE: nil
          ) do
            result = Fastlane::FastFile.new.parse("lane :test do
              xcodebuild(
                archive_path: './build-dir/MyApp.xcarchive',
                export_archive: true
              )
            end").runner.execute(:test)

            expect(result).to eq(
              "set -o pipefail && " \
              + "xcodebuild " \
              + "-archivePath \"./build-dir/MyApp.xcarchive\" " \
              + "-exportArchive " \
              + "-exportPath \"./build-dir/MyApp\" " \
              + "| tee '#{build_log_path}' | xcpretty --color --simple"
            )
          end
        end
      end
    end

    describe "xcarchive" do
      it "is equivalent to 'xcodebuild archive'" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xcarchive(
            archive_path: './build-dir/MyApp.xcarchive',
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace'
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-archivePath \"./build-dir/MyApp.xcarchive\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "archive " \
          + "| tee '#{build_log_path}' | xcpretty --color --simple"
        )
      end
    end

    describe "xcbuild" do
      it "is equivalent to 'xcodebuild build'" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xcbuild(
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace'
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "build " \
          + "| tee '#{build_log_path}' | xcpretty --color --simple"
        )
      end
    end

    describe "xcbuild without xpretty" do
      it "is equivalent to 'xcodebuild build'" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xcbuild(
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace',
            raw_buildlog: true
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "build " \
          + "| tee '#{build_log_path}' "
        )
      end
    end

    # describe "xcbuild without xpretty and with test" do
    #   it "is equivalent to 'xcodebuild build'" do
    #     result = Fastlane::FastFile.new.parse("lane :test do
    #       xcbuild(
    #         scheme: 'MyApp',
    #         workspace: 'MyApp.xcworkspace',
    #         raw_buildlog: true,
    #         test: true
    #       )
    #     end").runner.execute(:test)

    #     expect(result).to eq(
    #       "set -o pipefail && " \
    #       + "xcodebuild " \
    #       + "-scheme \"MyApp\" " \
    #       + "-workspace \"MyApp.xcworkspace\" " \
    #       + "build test " \
    #       + "| tee '#{build_log_path}' "
    #     )
    #   end
    # end

    describe "xcbuild without xpretty and with test and reports" do
      it "is equivalent to 'xcodebuild build'" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xcbuild(
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace',
            raw_buildlog: true,
            report_formats: ['html'],
            test: true
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "cat '#{build_log_path}' " \
          + "| xcpretty --color --report html --test > /dev/null"
        )
      end
    end

    describe "xcclean" do
      it "is equivalent to 'xcodebuild clean'" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xcclean
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && xcodebuild clean | tee '#{build_log_path}' | xcpretty --color --simple"
        )
      end
    end

    # describe "xcexport" do
    #   it "is equivalent to 'xcodebuild -exportArchive'" do
    #     result = Fastlane::FastFile.new.parse("lane :test do
    #       xcexport(
    #         archive_path: './build-dir/MyApp.xcarchive',
    #         export_path: './build-dir/MyApp',
    #       )
    #     end").runner.execute(:test)

    #     expect(result).to eq(
    #       "set -o pipefail && " \
    #       + "xcodebuild " \
    #       + "-archivePath \"./build-dir/MyApp.xcarchive\" " \
    #       + "-exportArchive " \
    #       + "-exportPath \"./build-dir/MyApp\" " \
    #       + "| tee '#{build_log_path}' | xcpretty --color --simple"
    #     )
    #   end
    # end

    describe "xctest" do
      it "is equivalent to 'xcodebuild build test'" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xctest(
            destination: 'name=iPhone 5s,OS=8.1',
            destination_timeout: 240,
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace'
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-destination \"name=iPhone 5s,OS=8.1\" " \
          + "-destination-timeout \"240\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "build " \
          + "test " \
          + "| tee '#{build_log_path}' | xcpretty --color --test"
        )
      end
    end

    describe "address sanitizer" do
      it "address sanitizer is enabled" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xctest(
            destination: 'name=iPhone 5s,OS=8.1',
            destination_timeout: 240,
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace',
            enable_address_sanitizer: true
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-destination \"name=iPhone 5s,OS=8.1\" " \
          + "-destination-timeout \"240\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "build " \
          + "test " \
          + "-enableAddressSanitizer \"YES\" " \
          + "| tee '#{build_log_path}' | xcpretty --color --test"
        )
      end

      it "address sanitizer is disabled" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xctest(
            destination: 'name=iPhone 5s,OS=8.1',
            destination_timeout: 240,
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace',
            enable_address_sanitizer: false
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-destination \"name=iPhone 5s,OS=8.1\" " \
          + "-destination-timeout \"240\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "build " \
          + "test " \
          + "-enableAddressSanitizer \"NO\" " \
          + "| tee '#{build_log_path}' | xcpretty --color --test"
        )
      end
    end

    describe "thread sanitizer" do
      it "thread sanitizer is enabled" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xctest(
            destination: 'name=iPhone 5s,OS=8.1',
            destination_timeout: 240,
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace',
            enable_thread_sanitizer: true
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-destination \"name=iPhone 5s,OS=8.1\" " \
          + "-destination-timeout \"240\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "build " \
          + "test " \
          + "-enableThreadSanitizer \"YES\" " \
          + "| tee '#{build_log_path}' | xcpretty --color --test"
        )
      end

      it "thread sanitizer is disabled" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xctest(
            destination: 'name=iPhone 5s,OS=8.1',
            destination_timeout: 240,
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace',
            enable_thread_sanitizer: false
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-destination \"name=iPhone 5s,OS=8.1\" " \
          + "-destination-timeout \"240\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "build " \
          + "test " \
          + "-enableThreadSanitizer \"NO\" " \
          + "| tee '#{build_log_path}' | xcpretty --color --test"
        )
      end
    end

    describe "test code coverage" do
      it "code coverage is enabled" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xctest(
            destination: 'name=iPhone 5s,OS=8.1',
            destination_timeout: 240,
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace',
            enable_code_coverage: true
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-destination \"name=iPhone 5s,OS=8.1\" " \
          + "-destination-timeout \"240\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "build " \
          + "test " \
          + "-enableCodeCoverage \"YES\" " \
          + "| tee '#{build_log_path}' | xcpretty --color --test"
        )
      end

      it "code coverage is disabled" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xctest(
            destination: 'name=iPhone 5s,OS=8.1',
            destination_timeout: 240,
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace',
            enable_code_coverage: false
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-destination \"name=iPhone 5s,OS=8.1\" " \
          + "-destination-timeout \"240\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "build " \
          + "test " \
          + "-enableCodeCoverage \"NO\" " \
          + "| tee '#{build_log_path}' | xcpretty --color --test"
        )
      end
    end

    describe "test reporting" do
      it "should work with xcpretty report params" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xctest(
            destination: 'name=iPhone 5s,OS=8.1',
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace',
            report_formats: ['junit'],
            report_path: './build-dir/test-report'
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-destination \"name=iPhone 5s,OS=8.1\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "build " \
          + "test " \
          + "| tee '#{build_log_path}' | xcpretty --color " \
          + "--report junit " \
          + "--output \"./build-dir/test-report\" " \
          + "--test"
        )
      end

      it "should save reports to BUILD_PATH + \"/report\" by default" do
        FastlaneSpec::Env.with_env_values(XCODE_BUILD_PATH: "./build") do
          result = Fastlane::FastFile.new.parse("lane :test do
            xctest(
              destination: 'name=iPhone 5s,OS=8.1',
              scheme: 'MyApp',
              workspace: 'MyApp.xcworkspace',
              report_formats: ['html'],
              report_screenshots: true
            )
          end").runner.execute(:test)

          expect(result).to eq(
            "set -o pipefail && " \
            + "xcodebuild " \
            + "-destination \"name=iPhone 5s,OS=8.1\" " \
            + "-scheme \"MyApp\" " \
            + "-workspace \"MyApp.xcworkspace\" " \
            + "build " \
            + "test " \
            + "| tee '#{build_log_path}' | xcpretty --color " \
            + "--report html " \
            + "--screenshots " \
            + "--output \"./build/report\" " \
            + "--test"
          )
        end
      end

      it "should support multiple output formats" do
        result = Fastlane::FastFile.new.parse("lane :test do
          xctest(
            destination: 'name=iPhone 5s,OS=8.1',
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace',
            report_formats: [ 'html', 'junit', 'json-compilation-database' ]
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-destination \"name=iPhone 5s,OS=8.1\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "build " \
          + "test " \
          + "| tee '#{build_log_path}' | xcpretty --color " \
          + "--report html " \
          + "--report json-compilation-database " \
          + "--report junit " \
          + "--test"
        )
      end

      it "should support multiple reports " do
        result = Fastlane::FastFile.new.parse("lane :test do
          xctest(
            destination: 'name=iPhone 5s,OS=8.1',
            scheme: 'MyApp',
            workspace: 'MyApp.xcworkspace',
            reports: [{
              report: 'html',
              output: './build-dir/test-report.html',
              screenshots: 1
            },
            {
              report: 'junit',
              output: './build-dir/test-report.xml'
            }],
          )
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "-destination \"name=iPhone 5s,OS=8.1\" " \
          + "-scheme \"MyApp\" " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "build " \
          + "test " \
          + "| tee '#{build_log_path}' | xcpretty --color " \
          + "--report html " \
          + "--output \"./build-dir/test-report.html\" " \
          + "--screenshots " \
          + "--report junit " \
          + "--output \"./build-dir/test-report.xml\" " \
          + "--test"
        )
      end

      it "should support omitting output when specifying multiple reports " do
        FastlaneSpec::Env.with_env_values(XCODE_BUILD_PATH: "./build") do
          result = Fastlane::FastFile.new.parse("lane :test do
            xctest(
              destination: 'name=iPhone 5s,OS=8.1',
              scheme: 'MyApp',
              workspace: 'MyApp.xcworkspace',
              reports: [{
                report: 'html',
              },
              {
                report: 'junit',
              }],
            )
          end").runner.execute(:test)

          expect(result).to eq(
            "set -o pipefail && " \
            + "xcodebuild " \
            + "-destination \"name=iPhone 5s,OS=8.1\" " \
            + "-scheme \"MyApp\" " \
            + "-workspace \"MyApp.xcworkspace\" " \
            + "build " \
            + "test " \
            + "| tee '#{build_log_path}' | xcpretty --color " \
            + "--report html " \
            + "--output \"./build/report/report.html\" " \
            + "--report junit " \
            + "--output \"./build/report/report.xml\" " \
            + "--test"
          )
        end
      end

      it "should detect and use the workspace, when a workspace is present" do
        allow(Dir).to receive(:glob).with("*.xcworkspace").and_return(["MyApp.xcworkspace"])

        result = Fastlane::FastFile.new.parse("lane :test do
          xcbuild
        end").runner.execute(:test)

        expect(result).to eq(
          "set -o pipefail && " \
          + "xcodebuild " \
          + "build " \
          + "-workspace \"MyApp.xcworkspace\" " \
          + "| tee '#{build_log_path}' | xcpretty --color " \
          + "--simple"
        )
      end
    end
  end
end
