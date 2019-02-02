require 'test_helper'
require 'iruby/command'

module IRubyTest
  class CommandTest < TestBase
    def setup
      ipython_dir = File.expand_path('~/.ipython')
      @kernel_dir = File.join(ipython_dir, 'kernels', 'ruby')
    end

    def test_with_empty_argv
      with_env('IPYTHONDIR' => nil) do
        @command = IRuby::Command.new([])
        ipython_dir = File.expand_path('~/.ipython')
        kernel_dir = File.join(ipython_dir, 'kernels', 'ruby')
        assert_equal(kernel_dir, @command.instance_variable_get(:@kernel_dir))
      end
    end

    def test_with_IPYTHONDIR
      Dir.mktmpdir do |tmpdir|
        with_env('IPYTHONDIR' => tmpdir) do
          @command = IRuby::Command.new([])
          kernel_dir = File.join(tmpdir, 'kernels', 'ruby')
          assert_equal(kernel_dir, @command.instance_variable_get(:@kernel_dir))
        end
      end
    end

    def test_register_and_unregister
      Dir.mktmpdir do |tmpdir|
        with_env('IPYTHONDIR' => tmpdir) do
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
