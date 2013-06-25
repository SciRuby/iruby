# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'iruby/version'

Gem::Specification.new do |spec|
  spec.name          = "iruby"
  spec.version       = Iruby::VERSION
  spec.authors       = ["Damián Silvani"]
  spec.email         = ["munshkr@gmail.com"]
  spec.description   = %q{IPython Notebook for Ruby}
  spec.summary       = %q{Create an IPython Notebook profile for using Ruby as kernel}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "bond"
  spec.add_runtime_dependency "ffi-rzmq"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "term-ansicolor"
  spec.add_runtime_dependency "trollop"
  spec.add_runtime_dependency "uuid"
end
