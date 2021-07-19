require "iruby"
require "json"
require 'multi_json'
require "pathname"
require "test/unit"
require "test/unit/rr"
require "tmpdir"


IRuby.logger = IRuby::MultiLogger.new(*Logger.new(STDERR, level: Logger::Severity::INFO))

module IRubyTest
  class TestBase < Test::Unit::TestCase
    def self.startup
      @__config_dir = Dir.mktmpdir("iruby-test")
      @__config_path = Pathname.new(@__config_dir) + "config.json"
      File.write(@__config_path, {
        control_port: 50160,
        shell_port: 57503,
        transport: "tcp",
        signature_scheme: "hmac-sha256",
        stdin_port: 52597,
        hb_port: 42540,
        ip: "127.0.0.1",
        iopub_port: 40885,
        key: "a0436f6c-1916-498b-8eb9-e81ab9368e84"
      }.to_json)

      @__original_kernel_instance = IRuby::Kernel.instance
    end

    def self.shutdown
      FileUtils.remove_entry_secure(@__config_dir)
    end

    def self.test_config_filename
      @__config_path.to_s
    end

    def self.restore_kernel
      IRuby::Kernel.instance = @__original_kernel_instance
    end

    def teardown
      self.class.restore_kernel
    end

    def with_session_adapter(session_adapter_name)
      IRuby::Kernel.new(self.class.test_config_filename, session_adapter_name)
      $stdout = STDOUT
      $stderr = STDERR
    end

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
      omit('apple only test') unless apple?
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
