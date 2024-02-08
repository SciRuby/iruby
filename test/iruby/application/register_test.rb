require_relative "helper"

module IRubyTest::ApplicationTests
  class RegisterTest < ApplicationTestBase
    sub_test_case("when the existing IRuby kernel is in IPython's kernels directory") do
      def setup
        Dir.mktmpdir do |tmpdir|
          ipython_dir = File.join(tmpdir, ".ipython")
          # prepare the existing IRuby kernel with the default name
          with_env("JUPYTER_DATA_DIR" => ipython_dir) do
            ensure_iruby_kernel_is_installed
          end

          fake_bin_dir = File.join(tmpdir, "bin")
          fake_jupyter = File.join(fake_bin_dir, "jupyter")
          FileUtils.mkdir_p(fake_bin_dir)
          IO.write(fake_jupyter, <<-FAKE_JUPYTER)
#!/usr/bin/env ruby
puts "Fake Jupyter"
          FAKE_JUPYTER
          File.chmod(0o755, fake_jupyter)

          new_path = [fake_bin_dir, ENV["PATH"]].join(File::PATH_SEPARATOR)
          with_env(
            "HOME" => tmpdir,
            "PATH" => new_path,
            "JUPYTER_DATA_DIR" => nil,
            "IPYTHONDIR" => nil
          ) do
            yield
          end
        end
      end

      test("IRuby warns the existence of the kernel in IPython's kernels directory and executes `jupyter kernelspec install` command") do
        out, status = Open3.capture2e(*iruby_command("register"))
        assert status.success?
        assert_match(/^Fake Jupyter$/, out)
        assert_match(/^#{Regexp.escape("IRuby kernel `#{DEFAULT_KERNEL_NAME}` already exists in the deprecated IPython's data directory.")}$/,
                     out)
      end
    end

    sub_test_case("when the existing IRuby kernel is in Jupyter's default kernels directory") do
      # TODO
    end

    sub_test_case("JUPYTER_DATA_DIR is supplied") do
      def setup
        Dir.mktmpdir do |tmpdir|
          @kernel_json = File.join(tmpdir, "kernels", DEFAULT_KERNEL_NAME, "kernel.json")
          with_env(
            "JUPYTER_DATA_DIR" => tmpdir,
            "IPYTHONDIR" => nil
          ) do
            yield
          end
        end
      end

      test("a new IRuby kernel `#{DEFAULT_KERNEL_NAME}` will be installed in JUPYTER_DATA_DIR") do
        assert_path_not_exist @kernel_json

        out, status = Open3.capture2e(*iruby_command("register"))
        assert status.success?
        assert_path_exist @kernel_json

        kernel = JSON.load(File.read(@kernel_json))
        assert_equal DEFAULT_DISPLAY_NAME, kernel["display_name"]
      end

      sub_test_case("there is a IRuby kernel in JUPYTER_DATA_DIR") do
        def setup
          super do
            FileUtils.mkdir_p(File.dirname(@kernel_json))
            File.write(@kernel_json, '"dummy kernel"')
            assert_equal '"dummy kernel"', File.read(@kernel_json)
            yield
          end
        end

        test("warn the existence of the kernel") do
          out, status = Open3.capture2e(*iruby_command("register"))
          refute status.success?
          assert_match(/^#{Regexp.escape("IRuby kernel named `#{DEFAULT_KERNEL_NAME}` already exists!")}$/,
                       out)
          assert_match(/^#{Regexp.escape("Use --force to force register the new kernel.")}$/,
                       out)
        end

        test("the existing kernel is not overwritten") do
          _out, status = Open3.capture2e(*iruby_command("register"))
          refute status.success?
          assert_equal '"dummy kernel"', File.read(@kernel_json)
        end

        sub_test_case("`--force` option is specified") do
          test("the existing kernel is overwritten by the new kernel") do
            out, status = Open3.capture2e(*iruby_command("register", "--force"))
            assert status.success?
            assert_not_match(/^#{Regexp.escape("IRuby kernel named `#{DEFAULT_KERNEL_NAME}` already exists!")}$/,
                             out)
            assert_not_match(/^#{Regexp.escape("Use --force to force register the new kernel.")}$/,
                             out)
            assert_not_equal '"dummy kernel"', File.read(@kernel_json)
          end
        end
      end
    end

    sub_test_case("both JUPYTER_DATA_DIR and IPYTHONDIR are supplied") do
      def setup
        Dir.mktmpdir do |tmpdir|
          Dir.mktmpdir do |tmpdir2|
            with_env(
              "JUPYTER_DATA_DIR" => tmpdir,
              "IPYTHONDIR" => tmpdir2
            ) do
              yield
            end
          end
        end
      end

      test("warn for IPYTHONDIR") do
        out, status = Open3.capture2e(*iruby_command("register"))
        assert status.success?
        assert_match(/^#{Regexp.escape("both JUPYTER_DATA_DIR and IPYTHONDIR are supplied; IPYTHONDIR is ignored.")}$/,
                     out)
      end

      test("a new kernel is installed in JUPYTER_DATA_DIR") do
        _out, status = Open3.capture2e(*iruby_command("register"))
        assert status.success?
        assert_path_exist File.join(ENV["JUPYTER_DATA_DIR"], "kernels", DEFAULT_KERNEL_NAME, "kernel.json")
      end
    end
  end
end
