require 'credentials_manager/appfile_config'

describe CredentialsManager do
  describe CredentialsManager::AppfileConfig do
    describe "#load_for_lane_configuration" do
      it "overrides Appfile configuration with current driven lane." do
        FastlaneSpec::Env.with_env_values(FASTLANE_LANE_NAME: :beta.to_s) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:app_identifier]).to eq('net.sunapps.1.beta')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:team_id]).to eq('3ECBP458CC')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:itc_provider]).to eq('JoshHoltz')
        end

        FastlaneSpec::Env.with_env_values(FASTLANE_LANE_NAME: :enterprise.to_s) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:app_identifier]).to eq('enterprise.com')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:team_id]).to eq('Q2CBPJ58CC')
        end

        FastlaneSpec::Env.with_env_values(FASTLANE_PLATFORM_NAME: :ios.to_s, FASTLANE_LANE_NAME: :something.to_s) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:app_identifier]).to eq('platform.com')
        end
      end
    end

    describe "#load_for_platform_configuration" do
      it "overrides Appfile configuration with current platform." do
        FastlaneSpec::Env.with_env_values(FASTLANE_PLATFORM_NAME: :ios.to_s, FASTLANE_LANE_NAME: nil) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile2').data[:app_identifier]).to eq('net.sunapps.ios')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile2').data[:apple_id]).to eq('fabio@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile2').data[:team_id]).to eq('3ECBP458AA')
        end

        FastlaneSpec::Env.with_env_values(FASTLANE_PLATFORM_NAME: :osx.to_s, FASTLANE_LANE_NAME: nil) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile2').data[:app_identifier]).to eq('net.sunapps.osx')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile2').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile2').data[:team_id]).to eq('Q2CBPJ58AA')
        end
      end
    end

    describe "#load_for_platform_for_lane_configuration" do
      it "overrides Appfile configuration with current platform and specified lane." do
        FastlaneSpec::Env.with_env_values(FASTLANE_PLATFORM_NAME: :ios.to_s, FASTLANE_LANE_NAME: :enterprise.to_s) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile3').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile3').data[:app_identifier]).to eq('net.sunapps.enterprise')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile3').data[:team_id]).to eq('Q2CBPJ58AA')
        end
      end
    end

    describe "#load_for_platform_configurations_same_name_lane" do
      it "overrides Appfile configuration with two different specified platforms name and lanes with same name." do
        FastlaneSpec::Env.with_env_values(FASTLANE_PLATFORM_NAME: :ios.to_s, FASTLANE_LANE_NAME: :enterprise.to_s) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile4').data[:apple_id]).to eq('fabio@sunapps.ios.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile4').data[:app_identifier]).to eq('net.sunapps.ios.enterprise')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile4').data[:team_id]).to eq('Q2CBPJ58AA')
        end

        FastlaneSpec::Env.with_env_values(FASTLANE_PLATFORM_NAME: :osx.to_s, FASTLANE_LANE_NAME: :enterprise.to_s) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile4').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile4').data[:app_identifier]).to eq('net.sunapps.osx.enterprise')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile4').data[:team_id]).to eq('3ECBP458AA')
        end
      end
    end

    describe "#load_using_blocks" do
      it "can load Appfile configurations if the setters are passed blocks instead of values." do
        FastlaneSpec::Env.with_env_values(FASTLANE_PLATFORM_NAME: nil, FASTLANE_LANE_NAME: nil) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile5').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile5').data[:app_identifier]).to eq('net.sunapps.1')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile5').data[:team_id]).to eq('Q2CBPJ58CC')
        end

        FastlaneSpec::Env.with_env_values(FASTLANE_PLATFORM_NAME: :ios.to_s, FASTLANE_LANE_NAME: :enterprise.to_s) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile5').data[:apple_id]).to eq('fabio@sunapps.ios.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile5').data[:app_identifier]).to eq('net.sunapps.ios.enterprise')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile5').data[:team_id]).to eq('Q2CBPJ58AA')
        end
      end
    end

    describe "#load_default_configuration_no_lane_or_configuration_found" do
      it "loads Appfile default values for current platform and lane if no override is found" do
        FastlaneSpec::Env.with_env_values(FASTLANE_LANE_NAME: :this_is_not_something_you_find_in_the_app_file.to_s) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:app_identifier]).to eq('net.sunapps.1')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:team_id]).to eq('Q2CBPJ58CC')
        end

        FastlaneSpec::Env.with_env_values(FASTLANE_PLATFORM_NAME: :this_is_not_something_you_find_in_the_app_file.to_s) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:app_identifier]).to eq('net.sunapps.1')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:team_id]).to eq('Q2CBPJ58CC')
        end
      end
    end

    describe "#load_default_configuration" do
      it "loads Appfile default values if any lane or platform is found" do
        FastlaneSpec::Env.with_env_values(FASTLANE_LANE_NAME: nil) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:app_identifier]).to eq('net.sunapps.1')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:team_id]).to eq('Q2CBPJ58CC')
        end

        FastlaneSpec::Env.with_env_values(FASTLANE_PLATFORM_NAME: nil) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:app_identifier]).to eq('net.sunapps.1')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:team_id]).to eq('Q2CBPJ58CC')
        end
      end
    end

    describe "#load_lane_configuration_if_platform_specifier_is_blank" do
      it "ignores the platform specifier if it is blank" do
        FastlaneSpec::Env.with_env_values(FASTLANE_LANE_NAME: 'enterprise', FASTLANE_PLATFORM_NAME: '') do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:app_identifier]).to eq('enterprise.com')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:team_id]).to eq('Q2CBPJ58CC')
        end

        FastlaneSpec::Env.with_env_values(FASTLANE_LANE_NAME: 'enterprise', FASTLANE_PLATFORM_NAME: '    ') do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:app_identifier]).to eq('enterprise.com')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile1').data[:team_id]).to eq('Q2CBPJ58CC')
        end
      end
    end

    describe "#load_for_lane_configuration_with_specified_platform" do
      it "overrides Appfile configuration with current platform and specified lane." do
        FastlaneSpec::Env.with_env_values(FASTLANE_LANE_NAME: 'beta', FASTLANE_PLATFORM_NAME: 'ios') do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile6').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile6').data[:app_identifier]).to eq('com.app.beta')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile6').data[:team_id]).to eq('Q2CBPJ58CC')
        end

        FastlaneSpec::Env.with_env_values(FASTLANE_LANE_NAME: 'enterprise', FASTLANE_PLATFORM_NAME: 'ios') do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile6').data[:apple_id]).to eq('felix@sunapps.net')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile6').data[:app_identifier]).to eq('enterprise.com')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile6').data[:team_id]).to eq('Q2CBPJ58AA')
        end
      end
    end

    describe "Appfile7" do
      it "supports the old syntax too" do
        FastlaneSpec::Env.with_env_values(FASTLANE_LANE_NAME: 'beta', FASTLANE_PLATFORM_NAME: 'ios') do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile7').data[:app_identifier]).to eq('abc.xyz')
        end
      end

      it "doesn't return empty strings but nil instead" do
        FastlaneSpec::Env.with_env_values(FASTLANE_USER: nil, DELIVER_USER: nil) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile7').data[:apple_id]).to eq(nil)
        end
      end
    end

    describe "Appfile8" do
      it "allows dynamic creation of for_lane blocks" do
        FastlaneSpec::Env.with_env_values(FASTLANE_LANE_NAME: nil, FASTLANE_PLATFORM_NAME: 'ios') do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile8').data[:app_identifier]).to eq('*')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile8').data[:apple_id]).to eq('myAppleId@mail.com')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile8').data[:team_id]).to eq(nil)
        end

        FastlaneSpec::Env.with_env_values(FASTLANE_LANE_NAME: :lane_name1.to_s, FASTLANE_PLATFORM_NAME: 'ios') do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile8').data[:app_identifier]).to eq('lane_name1.*')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile8').data[:apple_id]).to eq('otherAppleId@mail.com')
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile8').data[:team_id]).to eq('TEAMID')
        end
      end
    end

    describe "Appfile9" do
      it "falls back to environment variable `FASTLANE_USER` for the username" do
        env_name = "User@#{Time.now.to_i}"
        FastlaneSpec::Env.with_env_values(FASTLANE_USER: env_name, DELIVER_USER: "This shouldn't be the value, as fastlane is more important") do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile9').data[:apple_id]).to eq(env_name)
        end
      end

      it "falls back to environment variable `DELIVER_USER` for the username" do
        env_name = "User@#{Time.now.to_i}"
        FastlaneSpec::Env.with_env_values(FASTLANE_USER: env_name) do
          expect(CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile9').data[:apple_id]).to eq(env_name)
        end
      end
    end

    describe "No Appfile" do
      it "prefills information from the environment variable" do
        env_name = "User@#{Time.now.to_i}"
        FastlaneSpec::Env.with_env_values(DELIVER_USER: env_name) do
          expect(CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)).to eq(env_name)
        end
      end
    end

    describe "'smart quotes' handling" do
      it "still gets the needed information from the Appfile" do
        config = CredentialsManager::AppfileConfig.new('credentials_manager/spec/fixtures/Appfile_smart_quotes')

        expect(config.data[:apple_id]).to eq('appfile@krausefx.com')
        expect(config.data[:app_identifier]).to eq('such.app')
      end
    end
  end
end
