source("https://rubygems.org")

gem "xcode-install", ">= 2.2.1" # needed for running xcode-install related tests

gem "danger", ">= 4.2.1", "< 5.0.0"
gem "danger-junit", ">= 0.7.3", "< 1.0.0"

gemspec(path: ".")

plugins_path = File.join(File.expand_path("..", __FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path)

# THIS IS TEMPORARY TO MAKE SURE MY CHANGES FAIL/PASS PROPERLY
gem "simctl", git: "https://github.com/joshdholtz/simctl.git", ref: "1f8e20459a5cc1f66dd1f247560edcc6b48adeac"