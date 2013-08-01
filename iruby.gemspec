# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'iruby/version'

Gem::Specification.new do |spec|
  spec.name          = "iruby"
  spec.version       = IRuby::VERSION
  spec.authors       = ["Damián Silvani", "Min RK", "martin sarsale", "Josh Adams"]
  spec.email         = ["benjaminrk@gmail.com"]
  spec.description   = %q{Ruby Kernel for IPython}
  spec.summary       = %q{A Ruby kernel for IPython frontends (notebook console, etc.)}
  spec.homepage      = "https://github.com/minrk/iruby"
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
  spec.add_runtime_dependency "gruff"
end
