require_relative "helper"

module IRubyTest::ApplicationTests
  class ConsoleTest < ApplicationTestBase
    def setup
      Dir.mktmpdir do |tmpdir|
        @fake_bin_dir = File.join(tmpdir, "bin")
        FileUtils.mkdir_p(@fake_bin_dir)

        @fake_data_dir = File.join(tmpdir, "data")
        FileUtils.mkdir_p(@fake_data_dir)

        new_path = [@fake_bin_dir, ENV["PATH"]].join(File::PATH_SEPARATOR)
        with_env("PATH" => new_path,
                 "JUPYTER_DATA_DIR" => @fake_data_dir) do
          yield
        end
      end
    end

    sub_test_case("there is the default IRuby kernel in JUPYTER_DATA_DIR") do
      def setup
        super do
          ensure_iruby_kernel_is_installed
          yield
        end
      end

      test("run `jupyter console` with the default IRuby kernel") do
        out, status = Open3.capture2e(*iruby_command("console"), in: :close)
        assert status.success?
        assert_match(/^Jupyter console [\d\.]+$/, out)
        assert_match(/^#{Regexp.escape("IRuby #{IRuby::VERSION}")}\b/, out)
      end
    end

    # NOTE: this case checks the priority of the default IRuby kernel when both kernels are available
    sub_test_case("there are both the default IRuby kernel and IRuby kernel named `ruby` in JUPYTER_DATA_DIR") do
      def setup
        super do
          ensure_iruby_kernel_is_installed
          ensure_iruby_kernel_is_installed("ruby")
          yield
        end
      end

      test("run `jupyter console` with the default IRuby kernel") do
        out, status = Open3.capture2e(*iruby_command("console"), in: :close)
        assert status.success?
        assert_match(/^Jupyter console [\d\.]+$/, out)
        assert_match(/^#{Regexp.escape("IRuby #{IRuby::VERSION}")}\b/, out)
      end
    end

    # NOTE: this case checks the availability of the old kernel name
    sub_test_case("there is the IRuby kernel, which is named `ruby`, in JUPYTER_DATA_DIR") do
      def setup
        super do
          ensure_iruby_kernel_is_installed("ruby")
          yield
        end
      end

      test("run `jupyter console` with the IRuby kernel `ruby`") do
        out, status = Open3.capture2e(*iruby_command("console"), in: :close)
        assert status.success?
        assert_match(/^Jupyter console [\d\.]+$/, out)
        assert_match(/^#{Regexp.escape("IRuby #{IRuby::VERSION}")}\b/, out)
      end
    end

    sub_test_case("with --kernel option") do
      test("run `jupyter console` command with the given kernel name") do
        kernel_name = "other-kernel-#{Process.pid}"
        out, status = Open3.capture2e(*iruby_command("console", "--kernel=#{kernel_name}"))
        refute status.success?
        assert_match(/\bNo such kernel named #{Regexp.escape(kernel_name)}\b/, out)
      end
    end

    sub_test_case("no subcommand") do
      def setup
        super do
          ensure_iruby_kernel_is_installed
          yield
        end
      end

      test("Run jupyter console command with the default IRuby kernel") do
        out, status = Open3.capture2e(*iruby_command, in: :close)
        assert status.success?
        assert_match(/^Jupyter console [\d\.]+$/, out)
        assert_match(/^#{Regexp.escape("IRuby #{IRuby::VERSION}")}\b/, out)
      end
    end
  end
end
