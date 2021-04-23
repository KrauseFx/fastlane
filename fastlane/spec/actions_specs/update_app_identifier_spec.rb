require 'xcodeproj'
include(Xcodeproj)

describe Fastlane do
  describe Fastlane::FastFile do
    describe "Update App Identifier Integration" do
      # Variables
      let(:test_path) { "/tmp/fastlane/tests/fastlane" }
      let(:fixtures_path) { "./fastlane/spec/fixtures/xcodeproj" }
      let(:proj_file) { "bundle.xcodeproj" }
      let(:identifier_key) { 'PRODUCT_BUNDLE_IDENTIFIER' }

      # Action parameters
      let(:xcodeproj) { File.join(test_path, proj_file) }
      let(:plist_path) { "Info.plist" }
      let(:plist_path_with_srcroot) { "$(SRCROOT)/Info.plist" }
      let(:app_identifier) { "com.test.plist" }

      # Is there a better place for an helper function?
      # Create an Info.plist file with a supplied bundle_identifier parameter
      def create_plist_with_identifier(bundle_identifier)
        File.write(File.join(test_path, plist_path), "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>CFBundleIdentifier</key><string>#{bundle_identifier}</string></dict></plist>")
      end

      before do
        # Create test folder
        FileUtils.mkdir_p(test_path)
        source = File.join(fixtures_path, proj_file)
        destination = File.join(test_path, proj_file)

        # Copy .xcodeproj fixture, as it will be modified during the test
        FileUtils.cp_r(source, destination)
      end

      if FastlaneCore::Helper.mac?
        it "updates the info plist when product bundle identifier not in use" do
          plist = create_plist_with_identifier('tools.fastlane.example')

          Fastlane::FastFile.new.parse("lane :test do
            update_app_identifier ({
              xcodeproj: '#{xcodeproj}',
              plist_path: '#{plist_path}',
              app_identifier: '#{app_identifier}'
            })
          end").runner.execute(:test)

          result = File.read(File.join(test_path, plist_path))
          expect(result).to include("<string>#{app_identifier}</string>")
        end

        it "updates the xcode project when product bundle identifier in use" do
          stub_project = 'stub project'
          stub_configuration_1 = 'stub config 1'
          stub_configuration_2 = 'stub config 2'
          stub_object = ['object']
          stub_settings_1 = { 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.something.else' }
          stub_settings_1['INFOPLIST_FILE'] = plist_path
          stub_settings_2 = { 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.something.entirely.else' }
          stub_settings_2['INFOPLIST_FILE'] = "Other-Info.plist"

          expect(Xcodeproj::Project).to receive(:open).with('/tmp/fastlane/tests/fastlane/bundle.xcodeproj').and_return(stub_project)
          expect(stub_project).to receive(:objects).and_return(stub_object)
          expect(stub_object).to receive(:select).and_return([stub_configuration_1, stub_configuration_2])
          expect(stub_configuration_1).to receive(:build_settings).twice.and_return(stub_settings_1)
          expect(stub_configuration_2).to receive(:build_settings).and_return(stub_settings_2)
          expect(stub_project).to receive(:save)

          create_plist_with_identifier("$(#{identifier_key})")
          Fastlane::FastFile.new.parse("lane :test do
            update_app_identifier({
              xcodeproj: '#{xcodeproj}',
              plist_path: '#{plist_path}',
              app_identifier: '#{app_identifier}'
            })
          end").runner.execute(:test)

          expect(stub_settings_1['PRODUCT_BUNDLE_IDENTIFIER']).to eq('com.test.plist')
          expect(stub_settings_2['PRODUCT_BUNDLE_IDENTIFIER']).to_not(eq('com.test.plist'))
        end

        it "updates the xcode project when product bundle identifier in use and it uses curly brackets notation" do
          stub_project = 'stub project'
          stub_configuration_1 = 'stub config 1'
          stub_configuration_2 = 'stub config 2'
          stub_object = ['object']
          stub_settings_1 = { 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.something.else' }
          stub_settings_1['INFOPLIST_FILE'] = plist_path
          stub_settings_2 = { 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.something.entirely.else' }
          stub_settings_2['INFOPLIST_FILE'] = "Other-Info.plist"

          expect(Xcodeproj::Project).to receive(:open).with('/tmp/fastlane/tests/fastlane/bundle.xcodeproj').and_return(stub_project)
          expect(stub_project).to receive(:objects).and_return(stub_object)
          expect(stub_object).to receive(:select).and_return([stub_configuration_1, stub_configuration_2])
          expect(stub_configuration_1).to receive(:build_settings).twice.and_return(stub_settings_1)
          expect(stub_configuration_2).to receive(:build_settings).and_return(stub_settings_2)
          expect(stub_project).to receive(:save)

          create_plist_with_identifier("${#{identifier_key}}")
          Fastlane::FastFile.new.parse("lane :test do
            update_app_identifier({
              xcodeproj: '#{xcodeproj}',
              plist_path: '#{plist_path}',
              app_identifier: '#{app_identifier}'
            })
          end").runner.execute(:test)

          expect(stub_settings_1['PRODUCT_BUNDLE_IDENTIFIER']).to eq('com.test.plist')
          expect(stub_settings_2['PRODUCT_BUNDLE_IDENTIFIER']).to_not(eq('com.test.plist'))
        end

        it "updates the xcode project when info plist path contains $(SRCROOT)" do
          stub_project = 'stub project'
          stub_configuration_1 = 'stub config 1'
          stub_configuration_2 = 'stub config 2'
          stub_object = ['object']
          stub_settings_1 = { 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.something.else' }
          stub_settings_1['INFOPLIST_FILE'] = plist_path_with_srcroot
          stub_settings_2 = { 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.something.entirely.else' }
          stub_settings_2['INFOPLIST_FILE'] = "Other-Info.plist"

          expect(Xcodeproj::Project).to receive(:open).with('/tmp/fastlane/tests/fastlane/bundle.xcodeproj').and_return(stub_project)
          expect(stub_project).to receive(:objects).and_return(stub_object)
          expect(stub_object).to receive(:select).and_return([stub_configuration_1, stub_configuration_2])
          expect(stub_configuration_1).to receive(:build_settings).twice.and_return(stub_settings_1)
          expect(stub_configuration_2).to receive(:build_settings).and_return(stub_settings_2)
          expect(stub_project).to receive(:save)

          create_plist_with_identifier("$(#{identifier_key})")
          Fastlane::FastFile.new.parse("lane :test do
            update_app_identifier({
              xcodeproj: '#{xcodeproj}',
              plist_path: '#{plist_path_with_srcroot}',
              app_identifier: '#{app_identifier}'
            })
          end").runner.execute(:test)

          expect(stub_settings_1['PRODUCT_BUNDLE_IDENTIFIER']).to eq('com.test.plist')
          expect(stub_settings_2['PRODUCT_BUNDLE_IDENTIFIER']).to_not(eq('com.test.plist'))
        end

        it "updates the xcode project when info plist path not contains $(SRCROOT)" do
          stub_project = 'stub project'
          stub_configuration_1 = 'stub config 1'
          stub_configuration_2 = 'stub config 2'
          stub_object = ['object']
          stub_settings_1 = { 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.something.else' }
          stub_settings_1['INFOPLIST_FILE'] = plist_path_with_srcroot
          stub_settings_2 = { 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.something.entirely.else' }
          stub_settings_2['INFOPLIST_FILE'] = "Other-Info.plist"

          expect(Xcodeproj::Project).to receive(:open).with('/tmp/fastlane/tests/fastlane/bundle.xcodeproj').and_return(stub_project)
          expect(stub_project).to receive(:objects).and_return(stub_object)
          expect(stub_object).to receive(:select).and_return([stub_configuration_1, stub_configuration_2])
          expect(stub_configuration_1).to receive(:build_settings).twice.and_return(stub_settings_1)
          expect(stub_configuration_2).to receive(:build_settings).and_return(stub_settings_2)
          expect(stub_project).to receive(:save)

          create_plist_with_identifier("$(#{identifier_key})")
          Fastlane::FastFile.new.parse("lane :test do
            update_app_identifier({
              xcodeproj: '#{xcodeproj}',
              plist_path: '#{plist_path}',
              app_identifier: '#{app_identifier}'
            })
          end").runner.execute(:test)

          expect(stub_settings_1['PRODUCT_BUNDLE_IDENTIFIER']).to eq('com.test.plist')
          expect(stub_settings_2['PRODUCT_BUNDLE_IDENTIFIER']).to_not(eq('com.test.plist'))
        end

        it "should raise an exception when PRODUCT_BUNDLE_IDENTIFIER in info plist but project doesn't use this info plist" do
          stub_project = 'stub project'
          stub_configuration = 'stub config'
          stub_object = ['object']
          stub_settings = { 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.something.else' }

          expect(Xcodeproj::Project).to receive(:open).with('/tmp/fastlane/tests/fastlane/bundle.xcodeproj').and_return(stub_project)
          expect(stub_project).to receive(:objects).and_return(stub_object)
          expect(stub_object).to receive(:select).and_return([stub_configuration])
          expect(stub_configuration).to receive(:build_settings).and_return(stub_settings)

          create_plist_with_identifier("$(#{identifier_key})")
          expect do
            Fastlane::FastFile.new.parse("lane :test do
              update_app_identifier({
                xcodeproj: '#{xcodeproj}',
                plist_path: '#{plist_path}',
                app_identifier: '#{app_identifier}'
              })
            end").runner.execute(:test)
          end.to raise_error("Xcodeproj doesn't have configuration with info plist #{plist_path}.")
        end

        it "should raise an exception when PRODUCT_BUNDLE_IDENTIFIER in info plist but not project" do
          stub_project = 'stub project'
          stub_configuration = 'stub config'
          stub_object = ['object']

          expect(Xcodeproj::Project).to receive(:open).with('/tmp/fastlane/tests/fastlane/bundle.xcodeproj').and_return(stub_project)
          expect(stub_project).to receive(:objects).and_return(stub_object)
          expect(stub_object).to receive(:select).and_return([])

          create_plist_with_identifier("$(#{identifier_key})")
          expect do
            Fastlane::FastFile.new.parse("lane :test do
            update_app_identifier({
              xcodeproj: '#{xcodeproj}',
              plist_path: '#{plist_path}',
              app_identifier: '#{app_identifier}'
            })
            end").runner.execute(:test)
          end.to raise_error("Info plist uses #{identifier_key}, but xcodeproj does not")
        end
      end

      after do
        # Clean up files
        FileUtils.rm_r(test_path)
      end
    end
  end
end
