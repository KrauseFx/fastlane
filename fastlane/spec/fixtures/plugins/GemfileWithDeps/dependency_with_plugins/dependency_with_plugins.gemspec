# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name        = 'dependency_with_plugins'
  spec.version     = '1.0.0'
  spec.authors     = ["fastlane team"]

  spec.required_ruby_version = '>= 2.6'

  spec.summary = "fake gem for fastlane tests"

  spec.add_dependency('fastlane')
  spec.add_dependency('fastlane-plugin-appcenter')
end
