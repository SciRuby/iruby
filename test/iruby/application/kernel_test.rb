require_relative "helper"

module IRubyTest::ApplicationTests
  class KernelTest < ApplicationTestBase
    def setup
      Dir.mktmpdir do |tmpdir|
        @fake_bin_dir = File.join(tmpdir, "bin")
        FileUtils.mkdir_p(@fake_bin_dir)

        @fake_data_dir = File.join(tmpdir, "data")
        FileUtils.mkdir_p(@fake_data_dir)

        new_path = [@fake_bin_dir, ENV["PATH"]].join(File::PATH_SEPARATOR)
        with_env("PATH" => new_path,
                 "JUPYTER_DATA_DIR" => @fake_data_dir) do
          ensure_iruby_kernel_is_installed
          yield
        end
      end
    end

    test("--test option dumps the given connection file") do
      connection_info = {
        "control_port" => 123456,
        "shell_port" => 123457,
        "transport" => "tcp",
        "signature_scheme" => "hmac-sha256",
        "stdin_port" => 123458,
        "hb_port" => 123459,
        "ip" => "127.0.0.1",
        "iopub_port" => 123460,
        "key" => "a0436f6c-1916-498b-8eb9-e81ab9368e84"
      }
      Dir.mktmpdir do |tmpdir|
        connection_file = File.join(tmpdir, "connection.json")
        File.write(connection_file, JSON.dump(connection_info))
        out, status = Open3.capture2e(*iruby_command("kernel", "-f", connection_file, "--test"))
        assert status.success?
        assert_equal connection_info, JSON.load(out)
      end
    end

    test("the default log level is INFO") do
      Dir.mktmpdir do |tmpdir|
        boot_file = File.join(tmpdir, "boot.rb")
        File.write(boot_file, <<~BOOT_SCRIPT)
          puts "!!! INFO: \#{Logger::INFO}"
          puts "!!! LOG LEVEL: \#{IRuby.logger.level}"
          puts "!!! LOG LEVEL IS INFO: \#{IRuby.logger.level == Logger::INFO}"
        BOOT_SCRIPT

        add_kernel_options(boot_file)

        out, status = Open3.capture2e(*iruby_command("console"), in: :close)
        assert status.success?
        assert_match(/^!!! LOG LEVEL IS INFO: true$/, out)
      end
    end

    test("--debug option makes the log level DEBUG") do
      Dir.mktmpdir do |tmpdir|
        boot_file = File.join(tmpdir, "boot.rb")
        File.write(boot_file, <<~BOOT_SCRIPT)
          puts "!!! LOG LEVEL IS DEBUG: \#{IRuby.logger.level == Logger::DEBUG}"
        BOOT_SCRIPT

        add_kernel_options("--debug", boot_file)

        out, status = Open3.capture2e(*iruby_command("console"), in: :close)
        assert status.success?
        assert_match(/^!!! LOG LEVEL IS DEBUG: true$/, out)
      end
    end

    test("--log option adds a log destination file") do
      Dir.mktmpdir do |tmpdir|
        boot_file = File.join(tmpdir, "boot.rb")
        File.write(boot_file, <<~BOOT_SCRIPT)
          IRuby.logger.info("bootfile") { "!!! LOG MESSAGE FROM BOOT FILE !!!" }
        BOOT_SCRIPT

        log_file = File.join(tmpdir, "log.txt")

        add_kernel_options("--log=#{log_file}", boot_file)

        out, status = Open3.capture2e(*iruby_command("console"), in: :close)
        assert status.success?
        assert_path_exist log_file
        assert_match(/\bINFO -- bootfile: !!! LOG MESSAGE FROM BOOT FILE !!!$/, File.read(log_file))
      end
    end
  end
end
