module IRuby
  class KernelApplication
    def initialize(argv)
      parse_command_line(argv)
    end

    def run
      if @test_mode
        dump_connection_file
        return
      end

      run_kernel
    end

    DEFAULT_CONNECTION_FILE = "kernel-#{Process.pid}.json".freeze

    private def parse_command_line(argv)
      opts = OptionParser.new
      opts.banner = "Usage: #{$PROGRAM_NAME} [options] [subcommand] [options]"

      @connection_file = nil
      opts.on(
        "-f CONNECTION_FILE", String,
        "JSON file in which to store connection info (default: kernel-<pid>.json)"
      ) {|v| @connection_file = v }

      @test_mode = false
      opts.on(
        "--test",
        "Run as test mode; dump the connection file and exit."
      ) { @test_mode = true }

      @log_file = nil
      opts.on(
        "--log=FILE", String,
        "Specify the log file."
      ) {|v| @log_file = v }

      @log_level = Logger::INFO
      opts.on(
        "--debug",
        "Set log-level debug"
      ) { @log_level = Logger::DEBUG }

      opts.order!(argv)

      if @connection_file.nil?
        # Without -f option, the connection file is at the beginning of the rest arguments
        if argv.length <= 3
          @connection_file, @boot_file, @work_dir = argv
        else
          raise ArgumentError, "Too many commandline arguments"
        end
      else
        if argv.length <= 2
          @boot_file, @work_dir = argv
        else
          raise ArgumentError, "Too many commandline arguments"
        end
      end

      @connection_file ||= DEFAULT_CONNECTION_FILE
    end

    private def dump_connection_file
      puts File.read(@connection_file)
    end

    private def run_kernel
      IRuby.logger = MultiLogger.new(*Logger.new(STDOUT))
      STDOUT.sync = true # FIXME: This can make the integration test.

      IRuby.logger.loggers << Logger.new(@log_file) unless @log_file.nil?
      IRuby.logger.level = @log_level

      if @work_dir
        IRuby.logger.debug("iruby kernel") { "Change the working directory: #{@work_dir}" }
        Dir.chdir(@work_dir)
      end

      if @boot_file
        IRuby.logger.debug("iruby kernel") { "Load the boot file: #{@boot_file}" }
        require @boot_file
      end

      check_bundler {|e| IRuby.logger.warn "Could not load bundler: #{e.message}" }

      require "iruby"
      Kernel.new(@connection_file).run
    rescue Exception => e
      IRuby.logger.fatal "Kernel died: #{e.message}\n#{e.backtrace.join("\n")}"
      exit 1
    end

    private def check_bundler
      require "bundler"
      unless Bundler.definition.specs.any? {|s| s.name == "iruby" }
        raise %{IRuby is missing from Gemfile. This might not work.  Add `gem "iruby"` in your Gemfile to fix it.}
      end
      Bundler.setup
    rescue LoadError
      # do nothing
    rescue Exception => e
      yield e
    end
  end
end
