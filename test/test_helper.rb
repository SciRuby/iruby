require 'iruby'
require 'tmpdir'
require 'minitest/autorun'

module IRubyTest
  class TestBase < Minitest::Test
    private

    def ignore_warning
      saved, $VERBOSE = $VERBOSE , nil
      yield
    ensure
      $VERBOSE = saved
    end
    def with_env(env)
      keys = env.keys
      saved_values = ENV.values_at(*keys)
      ENV.update(env)
      yield
    ensure
      if keys && saved_values
        keys.zip(saved_values) do |k, v|
          ENV[k] = v
        end
      end
    end

    def windows_only
      skip('windows only test') unless windows?
    end

    def apple_only
      skip('apple only test') unless windows?
    end

    def unix_only
      skip('unix only test') if windows? || apple?
    end

    def windows?
      /mingw|mswin/ =~ RUBY_PLATFORM
    end

    def apple?
      /darwin/ =~ RUBY_PLATFORM
    end
  end
end
