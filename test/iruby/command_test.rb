require 'test_helper'
require 'iruby/command'

module IRubyTest
  class CommandTest < TestBase
    def test_with_empty_argv
      with_env('JUPYTER_DATA_DIR' => nil,
               'IPYTHONDIR' => nil) do
        assert_output(nil, /\A\z/) do
          @command = IRuby::Command.new([])
          kernel_dir = File.join(IRuby::Jupyter.kernelspec_dir, 'ruby')
          assert_equal(kernel_dir, @command.kernel_dir)
          assert_equal(File.join(kernel_dir, 'kernel.json'), @command.kernel_file)
        end
      end
    end

    def test_with_JUPYTER_DATA_DIR
      Dir.mktmpdir do |tmpdir|
        with_env('JUPYTER_DATA_DIR' => tmpdir,
                 'IPYTHONDIR' => nil) do
          assert_output(nil, /\A\z/) do
            @command = IRuby::Command.new([])
            kernel_dir = File.join(tmpdir, 'kernels', 'ruby')
            assert_equal(kernel_dir, @command.kernel_dir)
            assert_equal(File.join(kernel_dir, 'kernel.json'), @command.kernel_file)
          end
        end
      end
    end

    def test_with_IPYTHONDIR
      Dir.mktmpdir do |tmpdir|
        with_env('JUPYTER_DATA_DIR' => nil,
                 'IPYTHONDIR' => tmpdir) do
          assert_output(nil, /IPYTHONDIR is deprecated\. Use JUPYTER_DATA_DIR instead\./) do
            @command = IRuby::Command.new([])
            kernel_dir = File.join(tmpdir, 'kernels', 'ruby')
            assert_equal(kernel_dir, @command.kernel_dir)
            assert_equal(File.join(kernel_dir, 'kernel.json'), @command.kernel_file)
          end
        end
      end
    end

    def test_with_JUPYTER_DATA_DIR_and_IPYTHONDIR
      Dir.mktmpdir do |tmpdir|
        with_env('JUPYTER_DATA_DIR' => tmpdir,
                 'IPYTHONDIR' => tmpdir) do
          assert_output(nil, /both JUPYTER_DATA_DIR and IPYTHONDIR are supplied; IPYTHONDIR is ignored\./) do
            @command = IRuby::Command.new([])
            kernel_dir = File.join(tmpdir, 'kernels', 'ruby')
            assert_equal(kernel_dir, @command.kernel_dir)
            assert_equal(File.join(kernel_dir, 'kernel.json'), @command.kernel_file)
          end
        end
      end
    end

    def test_with_ipython_dir_option
      Dir.mktmpdir do |tmpdir|
        with_env('JUPYTER_DATA_DIR' => nil,
                 'IPYTHONDIR' => nil) do
          assert_output(nil, /--ipython-dir is deprecated\. Use JUPYTER_DATA_DIR environment variable instead\./) do
            @command = IRuby::Command.new(%W[--ipython-dir=#{tmpdir}])
            kernel_dir = File.join(tmpdir, 'kernels', 'ruby')
            assert_equal(kernel_dir, @command.kernel_dir)
            assert_equal(File.join(kernel_dir, 'kernel.json'), @command.kernel_file)
          end
        end
      end
    end

    def test_register_and_unregister_with_JUPYTER_DATA_DIR
      Dir.mktmpdir do |tmpdir|
        with_env('JUPYTER_DATA_DIR' => tmpdir) do
          assert_output(nil, nil) do
            @command = IRuby::Command.new(['register'])
            kernel_dir = File.join(tmpdir, 'kernels', 'ruby')
            kernel_file = File.join(kernel_dir, 'kernel.json')
            assert(!File.file?(kernel_file))

            @command.run
            assert(File.file?(kernel_file))

            @command = IRuby::Command.new(['unregister'])
            @command.run
            assert(!File.file?(kernel_file))
          end
        end
      end
    end

    def test_register_and_unregister_with_IPYTHONDIR
      Dir.mktmpdir do |tmpdir|
        with_env('IPYTHONDIR' => tmpdir) do
          ignore_warning do
            @command = IRuby::Command.new(['register'])
            kernel_dir = File.join(tmpdir, 'kernels', 'ruby')
            kernel_file = File.join(kernel_dir, 'kernel.json')
            assert(!File.file?(kernel_file))

            @command.run
            assert(File.file?(kernel_file))

            @command = IRuby::Command.new(['unregister'])
            @command.run
            assert(!File.file?(kernel_file))
          end
        end
      end
    end
  end
end
