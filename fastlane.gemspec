# coding: utf-8

lib = File.expand_path('../fastlane/lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/version'

# Copy over the latest .rubocop.yml style guide
require 'yaml'
rubocop_config = File.expand_path('../.rubocop.yml', __FILE__)
config = YAML.safe_load(open(rubocop_config), aliases: true)
config['require'] = [
  'rubocop/require_tools',
  'rubocop-performance'
]
config.delete('inherit_from')
config.delete('CrossPlatform/ForkUsage')
config.delete('Lint/IsStringUsage')

File.write("#{lib}/fastlane/plugins/template/.rubocop.yml", YAML.dump(config))

Gem::Specification.new do |spec|
  spec.name          = "fastlane"
  spec.version       = Fastlane::VERSION
  # list of authors is regenerated and resorted on each release
  spec.authors       = ["Matthew Ellis",
                        "Jimmy Dee",
                        "Stefan Natchev",
                        "Roger Oba",
                        "Kohki Miki",
                        "Fumiya Nakamura",
                        "Josh Holtz",
                        "Iulian Onofrei",
                        "Andrew McBurney",
                        "Maksym Grebenets",
                        "Manu Wallner",
                        "Jérôme Lacoste",
                        "Felix Krause",
                        "Łukasz Grabowski",
                        "Jan Piotrowski",
                        "Max Ott",
                        "Helmut Januschka",
                        "Joshua Liebowitz",
                        "Danielle Tomlinson",
                        "Daniel Jankowski",
                        "Olivier Halligon",
                        "Satoshi Namai",
                        "Luka Mirosevic",
                        "Jorge Revuelta H",
                        "Manish Rathi",
                        "Aaron Brager"]

  spec.email         = ["fastlane@krausefx.com"]
  spec.summary       = Fastlane::SUMMARY
  spec.description   = Fastlane::DESCRIPTION
  spec.homepage      = "https://fastlane.tools"
  spec.license       = "MIT"
  spec.metadata      = {
    "bug_tracker_uri" => "https://github.com/fastlane/fastlane/issues",
    "changelog_uri" => "https://github.com/fastlane/fastlane/releases",
    "documentation_uri" => "https://docs.fastlane.tools/",
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/fastlane/fastlane"
  }

  spec.required_ruby_version = '>= 2.7'

  spec.files = Dir.glob("*/lib/**/*", File::FNM_DOTMATCH) + Dir["fastlane/swift/**/*"] + Dir["bin/*"] + Dir["*/README.md"] + %w(README.md LICENSE .yardopts) - Dir["fastlane/lib/fastlane/actions/device_grid/assets/*"] - Dir["fastlane/lib/fastlane/actions/docs/assets/*"]
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = Dir["*/lib"]

  spec.add_dependency('addressable', '>= 2.8', '< 3.0.0') # Support for URI templates
  spec.add_dependency('artifactory', '~> 3.0') # Used to export to an artifactory server
  spec.add_dependency('aws-sdk-s3', '~> 1.0') # Used for S3 storage in fastlane match
  spec.add_dependency('babosa', '>= 1.0.3', '< 2.0.0') # library for creating human-friendly identifiers, aka "slugs"
  spec.add_dependency('bundler', '>= 1.12.0', '< 3.0.0') # Used for fastlane plugins
  spec.add_dependency('CFPropertyList', '>= 2.3', '< 4.0.0') # Needed to be able to read binary plist format
  spec.add_dependency('colored', '~> 1.2') # colored terminal output
  spec.add_dependency('commander', '~> 4.6') # CLI parser
  spec.add_dependency('dotenv', '>= 2.1.1', '< 3.0.0')
  spec.add_dependency('emoji_regex', '>= 0.1', '< 4.0') # Used to scan for Emoji in the changelog
  spec.add_dependency('excon', '>= 0.71.0', '< 1.0.0') # Great HTTP Client
  spec.add_dependency('faraday_middleware', '~> 1.0') # Same as faraday
  spec.add_dependency('faraday-cookie_jar', '~> 0.0.6')
  spec.add_dependency('faraday', '~> 1.0') # The faraday gem is used for deploygate, hockey and testfairy actions.
  spec.add_dependency('fastimage', '>= 2.1.0', '< 3.0.0') # fetch the image sizes from the screenshots
  spec.add_dependency('gh_inspector', '>= 1.1.2', '< 2.0.0') # search for issues on GitHub when something goes wrong
  spec.add_dependency('google-apis-androidpublisher_v3', '~> 0.3') # Google API Client to access Play Publishing API
  spec.add_dependency('google-apis-playcustomapp_v1', '~> 0.1') # Google API Client to access Custom app Publishing API
  spec.add_dependency('google-cloud-env', '>= 1.6.0', '< 2.0.0') # Must be < 2.0.0 to support Ruby 2.6
  spec.add_dependency('google-cloud-storage', '~> 1.31') # Access Google Cloud Storage for match
  spec.add_dependency('highline', '~> 2.0') # user inputs (e.g. passwords)
  spec.add_dependency('http-cookie', '~> 1.0.5') # Must be 1.0.5+ for Ruby 3 compatibility: https://github.com/sparklemotion/http-cookie/commit/d12449a983d3dd660c5fe1f2b135c35e83755cc3
  spec.add_dependency('json', '< 3.0.0') # Because sometimes it's just not installed
  spec.add_dependency('jwt', '>= 2.1.0', '< 3') # Used for generating authentication tokens for App Store Connect API
  spec.add_dependency('mini_magick', '>= 4.9.4', '< 5.0.0') # To open, edit and export PSD files
  spec.add_dependency('multipart-post', '>= 2.0.0', '< 3.0.0') # Needed for uploading builds to appetize
  spec.add_dependency('naturally', '~> 2.2') # Used to sort strings with numbers in a human-friendly way
  spec.add_dependency('optparse', '>= 0.1.1', '< 1.0.0') # Used to parse options with Commander
  spec.add_dependency('plist', '>= 3.1.0', '< 4.0.0') # Needed for set_build_number_repository and get_info_plist_value actions
  spec.add_dependency('rubyzip', '>= 2.0.0', '< 3.0.0') # fix swift/ipa in gym
  spec.add_dependency('security', '= 0.1.5') # macOS Keychain manager, a dead project, no updates expected
  spec.add_dependency('simctl', '~> 1.6.3') # Used for querying and interacting with iOS simulators
  spec.add_dependency('terminal-notifier', '>= 2.0.0', '< 3.0.0') # macOS notifications
  spec.add_dependency('terminal-table', '~> 3') # Actions documentation
  spec.add_dependency('tty-screen', '>= 0.6.3', '< 1.0.0') # detect the terminal width
  spec.add_dependency('tty-spinner', '>= 0.8.0', '< 1.0.0') # loading indicators
  spec.add_dependency('word_wrap', '~> 1.0.0') # to add line breaks for tables with long strings
  spec.add_dependency('xcodeproj', '>= 1.13.0', '< 2.0.0') # Modify Xcode projects
  spec.add_dependency('xcpretty-travis-formatter', '>= 0.0.3', '< 2.0.0')
  spec.add_dependency('xcpretty', '~> 0.3.0') # prettify xcodebuild output
end
