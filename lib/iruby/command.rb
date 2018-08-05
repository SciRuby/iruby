require 'fileutils'
require 'multi_json'

module IRuby
  class Command
    def initialize(args)
      @args = args
      @kernel_name = 'ruby'
      @iruby_path = File.expand_path $0
    end

    def run
      case @args.first
      when 'version', '-v', '--version'
        require 'iruby/version'
        puts "IRuby #{IRuby::VERSION}, Ruby #{RUBY_VERSION}"
      when 'help', '-h', '--help'
        print_help
      when 'register'
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
    iruby register        Register IRuby kernel in #{@kernel_file}.
    iruby unregister      Unregister IRuby kernel.
    iruby console         Launch the IRuby terminal-based console.
    iruby notebook        Launch the IRuby HTML notebook server.
    ...                   Same as IPython.

Please note that IRuby accepts the same parameters as IPython.
Try `ipython help` for more information.
}
    end

    def run_kernel
      require 'iruby/logger'
      IRuby.logger = MultiLogger.new(*Logger.new(STDOUT))
      @args.reject! {|arg| arg =~ /\A--log=(.*)\Z/ && IRuby.logger.loggers << Logger.new($1) }
      IRuby.logger.level = @args.delete('--debug') ? Logger::DEBUG : Logger::INFO

      raise(ArgumentError, 'Not enough arguments to the kernel') if @args.size < 2 || @args.size > 4
      config_file, boot_file, working_dir = @args[1..-1]
      Dir.chdir(working_dir) if working_dir

      require boot_file if boot_file

      require 'iruby'
      Kernel.new(config_file).run
    rescue Exception => e
      IRuby.logger.fatal "Kernel died: #{e.message}\n#{e.backtrace.join("\n")}"
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
      # If no command is given, we use the console to launch the whole 0MQ-client-server stack
      @args = %w(console) + @args if @args.first.to_s !~ /\A\w/
      @args += %w(--kernel ruby) if %w(console qtconsole).include? @args.first

      check_version

      Kernel.exec('jupyter', *@args)
    end

    def register_kernel
      require 'tmpdir'

      Dir.mktmpdir do |dir|
        kernel_file = File.join(dir, 'kernel.json')

        File.write(kernel_file, MultiJson.dump(
          argv: [ @iruby_path, 'kernel', '{connection_file}' ],
          display_name: "Ruby #{RUBY_VERSION}", language: 'ruby'
        ))

        FileUtils.copy(Dir[File.join(__dir__, 'assets', '*')], dir) rescue nil

        `jupyter kernelspec install --user --replace --name=#{@kernel_name} #{dir}`
      end
    end

    def unregister_kernel
      `jupyter kernelspec uninstall -f #{@kernel_name}`
    end
  end
end
