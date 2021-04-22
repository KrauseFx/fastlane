require 'plist'

require_relative 'client_stubbing'
require_relative 'connect_api/provisioning/provisioning_stubbing'
require_relative 'connect_api/testflight/testflight_stubbing'
require_relative 'connect_api/tunes/tunes_stubbing'
require_relative 'connect_api/users/users_stubbing'
require_relative 'portal/portal_stubbing'
require_relative 'tunes/tunes_stubbing'
require_relative 'du/du_stubbing'
# Ensure that no ENV vars which interfere with testing are set
#
set_auth_vars = [
  'FASTLANE_SESSION',
  'FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD',
  'FASTLANE_PASSWORD'
].select { |var| ENV.key?(var) }

if set_auth_vars.any?
  abort("[!] Please `unset` the following ENV vars which interfere with spaceship testing: #{set_auth_vars.join(', ')}".red)
end

@cache_paths = [
  File.expand_path("/tmp/spaceship_itc_service_key.txt")
]

def try_delete(path)
  FileUtils.rm_f(path) if File.exist?(path)
end

def before_each_spaceship
  @cache_paths.each { |path| try_delete(path) }

  TunesStubbing.itc_stub_login
  PortalStubbing.adp_stub_login

  PortalStubbing.adp_stub_app_groups
  PortalStubbing.adp_stub_apps

  PortalStubbing.adp_stub_provisioning
  PortalStubbing.adp_stub_certificates
  PortalStubbing.adp_stub_devices
  PortalStubbing.adp_stub_persons
  PortalStubbing.adp_stub_website_pushes
  PortalStubbing.adp_stub_passbooks

  TunesStubbing.itc_stub_applications
  TunesStubbing.itc_stub_app_versions
  TunesStubbing.itc_stub_build_trains
  TunesStubbing.itc_stub_testers
  TunesStubbing.itc_stub_testflight
  TunesStubbing.itc_stub_app_version_ref
  TunesStubbing.itc_stub_user_detail
  TunesStubbing.itc_stub_sandbox_testers
  TunesStubbing.itc_stub_create_sandbox_tester
  TunesStubbing.itc_stub_delete_sandbox_tester
  TunesStubbing.itc_stub_candidate_builds
  TunesStubbing.itc_stub_pricing_tiers
  TunesStubbing.itc_stub_release_to_store
  TunesStubbing.itc_stub_release_to_all_users
  TunesStubbing.itc_stub_promocodes
  TunesStubbing.itc_stub_generate_promocodes
  TunesStubbing.itc_stub_promocodes_history
  TunesStubbing.itc_stub_supported_countries

  ConnectAPIStubbing::Provisioning.stub_bundle_ids
  ConnectAPIStubbing::Provisioning.stub_bundle_id
  ConnectAPIStubbing::Provisioning.stub_certificates
  ConnectAPIStubbing::Provisioning.stub_devices
  ConnectAPIStubbing::Provisioning.stub_profiles

  ConnectAPIStubbing::TestFlight.stub_apps
  ConnectAPIStubbing::TestFlight.stub_beta_app_localizations
  ConnectAPIStubbing::TestFlight.stub_beta_app_review_details
  ConnectAPIStubbing::TestFlight.stub_beta_app_review_submissions
  ConnectAPIStubbing::TestFlight.stub_beta_build_localizations
  ConnectAPIStubbing::TestFlight.stub_beta_build_metrics
  ConnectAPIStubbing::TestFlight.stub_beta_feedbacks
  ConnectAPIStubbing::TestFlight.stub_beta_feedbacks_delete
  ConnectAPIStubbing::TestFlight.stub_beta_groups
  ConnectAPIStubbing::TestFlight.stub_beta_testers
  ConnectAPIStubbing::TestFlight.stub_beta_tester_metrics
  ConnectAPIStubbing::TestFlight.stub_build_beta_details
  ConnectAPIStubbing::TestFlight.stub_build_deliveries
  ConnectAPIStubbing::TestFlight.stub_builds
  ConnectAPIStubbing::TestFlight.stub_pre_release_versions

  ConnectAPIStubbing::Tunes.stub_app_store_version_release_request

  ConnectAPIStubbing::Users.stub_users
end

def clear_client_instance_cache_recurisvely(klass)
  klass.subclasses.compact.each do |subclass|
    subclass.client = nil
    clear_client_instance_cache_recurisvely(subclass) if subclass.subclasses
  end
end

def after_each_spaceship
  # Clear client caches that may cause dependencies among unit test cases each other
  Spaceship::ConnectAPI.client = nil
  Spaceship::Tunes.client = nil
  Spaceship::Portal.client = nil
  clear_client_instance_cache_recurisvely(Spaceship::Base)

  @cache_paths.each { |path| try_delete(path) }
end

def around_each_spaceship(current_test)
  FastlaneSpec::Env.with_env_values(
    DELIVER_USER: 'spaceship@krausefx.com',
    DELIVER_PASSWORD: 'so_secret',
    SPACESHIP_AVOID_XCODE_API: 'true',
    FASTLANE_USER: nil
  ) do
    current_test.run
  end
end

RSpec.configure do |config|
  def mock_client_response(method_name, with: anything)
    mock_method = allow(mock_client).to receive(method_name)
    mock_method = mock_method.with(with)
    if block_given?
      mock_method.and_return(JSON.parse(yield.to_json))
    else
      mock_method
    end
  end
end
