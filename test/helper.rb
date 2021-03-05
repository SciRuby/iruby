require "iruby"
require "test/unit"
require "test/unit/rr"
require "tmpdir"

module IRubyTest
  class TestBase < Test::Unit::TestCase
    def assert_output(stdout=nil, stderr=nil)
      flunk "assert_output requires a block to capture output." unless block_given?

      out, err = capture_io do
        yield
      end

      y = check_assert_output_result(stderr, err, "stderr")
      x = check_assert_output_result(stdout, out, "stdout")

      (!stdout || x) && (!stderr || y)
    end

    private

    def capture_io
      captured_stdout = StringIO.new
      captured_stderr = StringIO.new

      orig_stdout, $stdout = $stdout, captured_stdout
      orig_stderr, $stderr = $stderr, captured_stderr

      yield

      return captured_stdout.string, captured_stderr.string
    ensure
      $stdout = orig_stdout
      $stderr = orig_stderr
    end

    def check_assert_output_result(expected, actual, name)
      if expected
        message = "In #{name}"
        case expected
        when Regexp
          assert_match(expected, actual, message)
        else
          assert_equal(expected, actual, message)
        end
      end
    end

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
      omit('windows only test') unless windows?
    end

    def apple_only
      omit('apple only test') unless windows?
    end

    def unix_only
      omit('unix only test') if windows? || apple?
    end

    def windows?
      /mingw|mswin/ =~ RUBY_PLATFORM
    end

    def apple?
      /darwin/ =~ RUBY_PLATFORM
    end
  end
end
