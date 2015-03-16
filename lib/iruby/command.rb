require 'shellwords'
require 'pathname'

module IRuby
  class Command
    WINDOWS_REGEXP = /mswin(?!ce)|mingw|cygwin/

    def initialize(args)
      @args = args.map { |e| e.dup } # unfreeze

      ENV['IPYTHONDIR'] ||= ENV['IRUBYDIR']
      @ipython_dir = ENV['IPYTHONDIR'] || '~/.ipython'
      @args.each do |arg|
        arg.sub!(/\A--iruby-dir=(.*)\Z/, '--ipython-dir=\1')
        @ipython_dir ||= $1
      end
      @ipython_dir = Pathname.new(@ipython_dir).expand_path
    end

    def run
      case @args.first
      when 'version', '-v', '--version'
        require 'iruby/version'
        puts IRuby::VERSION
      when 'help', '-h', '--help'
        print_help
      when 'register'
        register_iruby_kernel
      when 'unregister'
        unregister_iruby_kernel
      when 'kernel'
        run_kernel
      else
        run_ipython
      end
    end

    private

    def ipython_register_file
      @ipython_register_file ||= @ipython_dir / "kernels" / "ruby" / "kernel.json"
    end

    def print_help
      puts <<-EOF.chomp
Usage:
    iruby register        Register IRuby kernel into #{@ipython_dir}.
    iruby unregister      Remove #{ipython_register_file}.
    iruby console         Launch the IRuby terminal-based console.
    iruby notebook        Launch the IRuby HTML notebook server.
    ...                   Same as IPython.

Please note that IRuby accepts the same parameters as IPython.
Try `ipython help` for more information.
EOF
    end

    def run_kernel
      raise "Currently `iruby kernel` can only be called by a frontend." if @args.size == 1
      raise(ArgumentError, 'Not enough arguments to the kernel') if @args.size < 2 || @args.size > 4
      config_file, boot_file, working_dir = @args[1..-1]
      Dir.chdir(working_dir) if working_dir
      require boot_file if boot_file
      require 'iruby'
      Kernel.new(config_file).run
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
      register_iruby_kernel if %w(console qtconsole notebook).include? @args.first
      @args += %w(--kernel ruby) if %w(console qtconsole).include? @args.first

      Kernel.exec('ipython', *@args)
    end

    def register_iruby_kernel
      ipython_register_file.parent.mkpath
      ipython_register_file.write <<-EOF.chomp
{
"argv": [ "#{File.expand_path $0}", "kernel", "{connection_file}" ],
"display_name": "Ruby",
"language": "ruby"
}
EOF
    end

    def unregister_iruby_kernel
      ipython_register_file.delete
    end
  end
end
