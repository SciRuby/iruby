require 'iruby/jupyter'

module IRubyTest
  class JupyterDefaultKernelSpecDirectoryTest < TestBase
    sub_test_case("with JUPYTER_DATA_DIR") do
      def test_default
        assert_equal(File.join(ENV["JUPYTER_DATA_DIR"], "kernels"),
                     IRuby::Jupyter.kernelspec_dir)
      end
    end

    sub_test_case("without JUPYTER_DATA_DIR environment variable") do
      def setup
        with_env("JUPYTER_DATA_DIR" => nil) do
          @kernelspec_dir = IRuby::Jupyter.kernelspec_dir
          yield
        end
      end

      def test_default_windows
        windows_only
        appdata = IRuby::Jupyter.send :windows_user_appdata
        assert_equal(File.join(appdata, 'jupyter/kernels'), @kernelspec_dir)
      end

      def test_default_apple
        apple_only
        assert_equal(File.expand_path('~/Library/Jupyter/kernels'), @kernelspec_dir)
      end

      def test_default_unix
        unix_only
        with_env('XDG_DATA_HOME' => nil) do
          assert_equal(File.expand_path('~/.local/share/jupyter/kernels'), @kernelspec_dir)
        end
      end
    end
  end
end
