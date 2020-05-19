require_relative 'lib/iruby/version'

Gem::Specification.new do |s|
  s.name          = 'iruby'
  s.version       = IRuby::VERSION
  s.authors       = ['Daniel Mendler', 'The SciRuby developers']
  s.email         = ['mail@daniel-mendler.de']
  s.summary       = 'Ruby Kernel for Jupyter'
  s.description   = 'A Ruby kernel for Jupyter environment. Try it at try.jupyter.org.'
  s.homepage      = 'https://github.com/SciRuby/iruby'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^test/})
  s.require_paths = %w[lib]

  s.required_ruby_version = '>= 2.3.0'

  s.add_dependency 'data_uri', '~> 0.1'
  s.add_dependency 'ffi-rzmq'
  s.add_dependency 'mimemagic', '~> 0.3'
  s.add_dependency 'multi_json', '~> 1.11'

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'pycall', '>= 1.2.1'
  s.add_development_dependency 'rake'
end
