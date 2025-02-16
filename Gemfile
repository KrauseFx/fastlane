source("https://rubygems.org")

# Needed for the Fastlane::RUBOCOP_REQUIREMENT below
require_relative "fastlane/lib/fastlane/version.rb"

# Please don't add line breaks between the gems and their comments, as RuboCop won't be able to sort these alphabetically.

# Allows fine-grained control of environment variables.
gem "climate_control", "~> 0.2.0"
# A tool for integrating Coveralls.io with Ruby apps.
gem "coveralls", "~> 0.8.13"
# Automates code review chores.
gem "danger", "~> 8.0"
# Plugin for Danger that reports JUnit test results.
gem "danger-junit", "~> 1.0"
# A fake filesystem.
# Version 1.9+ requires Ruby >=2.7, while fastlane uses a `required_ruby_version` of `>= 2.6`.
gem "fakefs", "1.8"
# for file uploads with Faraday
gem "mime-types", ['>= 1.16', '< 4.0']
# Fast XML parser and object marshaller.
if RUBY_VERSION < '2.7.0'
  gem "ox", "2.13.2"
else
  gem "ox", "2.14.16"
end
# Provides an interactive debugging environment for Ruby.
gem "pry"
# A plugin for pry that adds step-by-step debugging and stack navigation.
gem "pry-byebug"
# A pry rescue environment to automatically open pry when a test fails.
gem "pry-rescue"
# A plugin for pry that enables exploring the call stack.
gem "pry-stack_explorer"
# A simple task automation tool.
gem "rake"
# A readline implementation in Ruby
# See: https://github.com/deivid-rodriguez/byebug/issues/289#issuecomment-251383465
gem "rb-readline"
# Behavior-driven testing tool for Ruby.
gem "rspec", "~> 3.10"
# Formatter for RSpec to generate JUnit compatible reports.
gem "rspec_junit_formatter", "~> 0.4.1"
# A Ruby static code analyzer and formatter.
gem "rubocop", Fastlane::RUBOCOP_REQUIREMENT
# A collection of RuboCop cops for performance optimizations.
gem "rubocop-performance"
# A RuboCop extension focused on enforcing tools.
gem "rubocop-require_tools"
# Used to mock servers.
gem "sinatra", [">= 2.2.3", "< 3.0"]
# A library for stubbing and setting expectations on HTTP requests.
gem "webmock", "~> 3.18"
# Needed for running xcode-install related tests.
gem "xcode-install", ">= 2.6.7"
# Used for xcov's parameters generation: https://github.com/fastlane/fastlane/pull/12416
gem "xcov", "~> 1.4.1"
# A documentation generation tool for Ruby.
gem "yard", "~> 0.9.11"

gemspec(path: ".")

plugins_path = File.join(File.expand_path("..", __FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path)
