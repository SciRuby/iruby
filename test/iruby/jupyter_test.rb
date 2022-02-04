require 'iruby/jupyter'

module IRubyTest
  class JupyterDefaultKernelSpecDirectoryTest < TestBase
    def setup
      @kernelspec_dir = IRuby::Jupyter.kernelspec_dir
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
