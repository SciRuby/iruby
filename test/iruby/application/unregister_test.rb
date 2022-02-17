require_relative "helper"

module IRubyTest::ApplicationTests
  class UnregisterTest < ApplicationTestBase
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

    sub_test_case("when there is no IRuby kernel in JUPYTER_DATA_DIR") do
      test("the command succeeds") do
        assert system(*iruby_command("unregister", "-f", DEFAULT_KERNEL_NAME),
                      out: File::NULL, err: File::NULL)
      end
    end

    sub_test_case("when the existing IRuby kernel in JUPYTER_DATA_DIR") do
      def setup
        super do
          ensure_iruby_kernel_is_installed
          yield
        end
      end

      test("uninstall the existing kernel") do
        assert system(*iruby_command("unregister", "-f", DEFAULT_KERNEL_NAME),
                      out: File::NULL, err: File::NULL)
        assert_path_not_exist @kernel_json
      end
    end

    sub_test_case("when the existing IRuby kernel in IPython's kernels directory") do
      def setup
        super do
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
              "IPYTHONDIR" => nil
            ) do
              yield
            end
          end
        end
      end

      test("the kernel in IPython's kernels directory is not removed") do
        assert system(*iruby_command("unregister", "-f"), out: File::NULL, err: File::NULL)
        assert_path_exist File.join(File.expand_path("~/.ipython"), "kernels", DEFAULT_KERNEL_NAME, "kernel.json")
      end
    end
  end
end
