# coding: utf-8
require File.dirname(__FILE__) + '/lib/iruby/version'
require 'date'

Gem::Specification.new do |s|
  s.name          = 'iruby'
  s.date          = Date.today.to_s
  s.version       = IRuby::VERSION
  s.authors       = ['The SciRuby developers']
  s.email         = ['benjaminrk@gmail.com']
  s.description   = 'Ruby Kernel for IPython'
  s.summary       = 'A Ruby kernel for IPython frontends (notebook console, etc.)'
  s.homepage      = 'https://github.com/SciRuby/iruby'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^test/})
  s.require_paths = %w(lib)

  m = "Consider installing the optional dependencies to get additional functionality:\n"
  File.read('Gemfile').scan(/gem\s+'(.*?)'/) { m << "  * #{$1}\n" }
  s.post_install_message = m << "\n"

  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'

  s.add_runtime_dependency 'bond', '~> 0.5.0'
  s.add_runtime_dependency 'ffi-rzmq', '~> 2.0'
  s.add_runtime_dependency 'multi_json', '~> 1.10.0'
  s.add_runtime_dependency 'mimemagic', '~> 0.2.0'
end
