source("https://rubygems.org")

gem "xcode-install", ">= 2.6.7" # needed for running xcode-install related tests

gem "danger", "~> 8.0"
gem "danger-junit", "~> 1.0"
gem "ox", "2.13.2"

# Locking this in until Ruby 2.4 is no longer officially supported by fastlane
gem "google-apis-core", "< 0.3.0"
gem "google-apis-iamcredentials_v1", "< 0.2.0"
gem "google-apis-storage_v1", "< 0.3.0"
gem "googleauth", "< 0.16.0"
gem "google-cloud-core", "< 1.6.0"
gem "google-cloud-env", "< 1.5.0"
gem "google-cloud-errors", "< 1.1.0"
gem "google-cloud-storage", "< 1.31.0"
gem "signet", "< 0.15.0"

gemspec(path: ".")

plugins_path = File.join(File.expand_path("..", __FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path)
