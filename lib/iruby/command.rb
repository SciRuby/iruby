require 'shellwords'
require 'fileutils'

module IRuby
  class Command
    def initialize(args)
      @args = args

      ipython_dir = ENV['IPYTHONDIR'] || '~/.ipython'
      @args.each do |arg|
        ipython_dir = $1 if arg =~ /\A--ipython-dir=(.*)\Z/
      end
      ipython_dir = File.expand_path(ipython_dir)
      @kernel_file = File.join(ipython_dir, 'kernels', 'ruby', 'kernel.json')
    end

    def run
      case @args.first
      when 'version', '-v', '--version'
        require 'iruby/version'
        puts IRuby::VERSION
      when 'help', '-h', '--help'
        print_help
      when 'register'
        if File.exist?(@kernel_file) && !@args.include?('--force')
          STDERR.puts "#{@kernel_file} already exists!\nUse --force to force a register."
          exit 1
        end
        register_kernel
      when 'unregister'
        unregister_kernel
      when 'kernel'
        run_kernel
      else
        run_ipython
      end
    end

    private

    def print_help
      puts %{
Usage:
    iruby register        Register IRuby kernel into #{@kernel_file}.
    iruby unregister      Remove #{@kernel_file}.
    iruby console         Launch the IRuby terminal-based console.
    iruby notebook        Launch the IRuby HTML notebook server.
    ...                   Same as IPython.

Please note that IRuby accepts the same parameters as IPython.
Try `ipython help` for more information.
}
    end

    def run_kernel
      raise(ArgumentError, 'Not enough arguments to the kernel') if @args.size < 2 || @args.size > 4
      config_file = @args[1]
      require 'iruby'
      Kernel.new(config_file, debug: @args.include?("--debug")).run
    rescue Exception => ex
      STDERR.puts "Kernel died: #{ex.message}\n#{ex.backtrace.join("\n")}"
      raise
    end

    def check_version
      required = '3.0.0'
      version = `ipython --version`.chomp
      if version < required
        STDERR.puts "Your IPython version #{version} is too old, at least #{required} is required"
        exit 1
      end
    end

    def run_ipython
      check_version

      # We must use the console to launch the whole 0MQ-client-server stack
      @args = %w(console --no-banner) + @args if @args.first.to_s !~ /\A\w/
      register_kernel if %w(console qtconsole notebook).include?(@args.first) && !File.exist?(@kernel_file)
      @args += %w(--kernel ruby) if %w(console qtconsole).include? @args.first

      Kernel.exec('ipython', *@args)
    end

    def register_kernel
      FileUtils.mkpath(File.dirname(@kernel_file))
      File.write(@kernel_file, %{{
  "argv":         [ "#{File.expand_path $0}", "kernel", "{connection_file}" ],
  "display_name": "Ruby",
  "language":     "ruby"
}
})
    end

    def unregister_kernel
      File.unlink(@kernel_file)
    end
  end
end
