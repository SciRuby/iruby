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
  s.bindir        = "exe"
  s.executables   = %w[iruby]
  s.test_files    = s.files.grep(%r{^test/})
  s.require_paths = %w[lib]
  s.extensions    = %w[ext/Rakefile]

  s.required_ruby_version = '>= 2.3.0'

  s.add_dependency 'data_uri', '~> 0.1'
  s.add_dependency 'ffi-rzmq'
  s.add_dependency 'irb'
  s.add_dependency 'logger'
  s.add_dependency 'mime-types', '>= 3.3.1'
  s.add_dependency 'multi_json', '~> 1.11'
  s.add_dependency 'native-package-installer'

  s.add_development_dependency 'pycall', '>= 1.2.1'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'test-unit-rr'

  s.metadata['msys2_mingw_dependencies'] = 'zeromq'
end
