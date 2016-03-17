# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'featureswitches/version'

Gem::Specification.new do |spec|
  spec.name          = "featureswitches"
  spec.version       = Featureswitches::VERSION
  spec.authors       = ["Joel Weirauch"]
  spec.email         = ["joel@featureswitches.com"]

  spec.summary       = %q{Ruby client for FeatureSwitches.com, feature flags as a service.}
  spec.homepage      = "https://github.com/featureswitches/featureswitches-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "ruby-cache", "~> 0.3"
  spec.add_dependency "nestful", "~> 1.1"
end
