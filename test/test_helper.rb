require 'iruby'
require 'tmpdir'
require 'minitest/autorun'

module IRubyTest
  class TestBase < Minitest::Test
    private

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
  end
end
