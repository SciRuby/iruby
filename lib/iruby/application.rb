require "fileutils"
require "json"
require "optparse"
require "rbconfig"
require "singleton"

require_relative "error"
require_relative "kernel_app"

module IRuby
  class Application
    include Singleton

    # Set the application instance up.
    def setup(argv=nil)
      @iruby_executable = File.expand_path($PROGRAM_NAME)
      parse_command_line(argv)
    end

    # Parse the command line arguments
    #
    # @param argv [Array<String>, nil] The array of arguments.
    private def parse_command_line(argv)
      argv = ARGV.dup if argv.nil?
      @argv = argv  # save the original

      case argv[0]
      when "help"
        # turn `iruby help notebook` into `iruby notebook -h`
        argv = [*argv[1..-1], "-h"]
      when "version"
        # turn `iruby version` into `iruby -v`
        argv = ["-v", *argv[1..-1]]
      else
        argv = argv.dup  # prevent to break @argv
      end

      opts = OptionParser.new
      opts.program_name = "IRuby"
      opts.version = ::IRuby::VERSION
      opts.banner = "Usage: #{$PROGRAM_NAME} [options] [subcommand] [options]"

      opts.on_tail("-h", "--help") do
        print_help(opts)
        exit
      end

      opts.on_tail("-v", "--version") do
        puts opts.ver
        exit
      end

      opts.order!(argv)

      if argv.length == 0 || argv[0].start_with?("-")
        # If no subcommand is given, we use the console
        argv = ["console", *argv]
      end

      begin
        parse_sub_command(argv) if argv.length > 0
      rescue InvalidSubcommandError => err
        $stderr.puts err.message
        print_help(opts, $stderr)
        abort
      end
    end

    SUB_COMMANDS = {
      "register" => "Register IRuby kernel.",
      "unregister" => "Unregister the existing IRuby kernel.",
      "kernel" => "Launch IRuby kernel",
      "console" => "Launch jupyter console with IRuby kernel"
    }.freeze.each_value(&:freeze)

    private_constant :SUB_COMMANDS

    private def parse_sub_command(argv)
      sub_cmd, *sub_argv = argv
      case sub_cmd
      when *SUB_COMMANDS.keys
        @sub_cmd = sub_cmd.to_sym
        @sub_argv = sub_argv
      else
        raise InvalidSubcommandError.new(sub_cmd, sub_argv)
      end
    end

    private def print_help(opts, out=$stdout)
      out.puts opts.help
      out.puts
      out.puts "Subcommands"
      out.puts "==========="
      SUB_COMMANDS.each do |name, description|
        out.puts "#{name}"
        out.puts "    #{description}"
      end
    end

    def run
      case @sub_cmd
      when :register
        register_kernel(@sub_argv)
      when :unregister
        unregister_kernel(@sub_argv)
      when :console
        exec_jupyter(@sub_cmd.to_s, @sub_argv)
      when :kernel
        @sub_app = KernelApplication.new(@sub_argv)
        @sub_app.run
      else
        raise "[IRuby][BUG] Unknown subcommand: #{@sub_cmd}; this must be treated in parse_command_line."
      end
    end

    ruby_version_info = RUBY_VERSION.split('.')
    DEFAULT_KERNEL_NAME = "ruby#{ruby_version_info[0]}".freeze
    DEFAULT_DISPLAY_NAME = "Ruby #{ruby_version_info[0]} (iruby kernel)"

    RegisterParams = Struct.new(
      :name,
      :display_name,
      :profile,
      :env,
      :user,
      :prefix,
      :sys_prefix,
      :force,
      :ipython_dir
    ) do
      def initialize(*args)
        super
        self.name ||= DEFAULT_KERNEL_NAME
        self.force = false
        self.user = true
      end
    end

    def register_kernel(argv)
      params = parse_register_command_line(argv)

      if params.name != DEFAULT_KERNEL_NAME
        # `--name` is specified and `--display-name` is not
        # default `params.display_name` to `params.name`
        params.display_name ||= params.name
      end

      check_and_warn_kernel_in_default_ipython_directory(params)

      if installed_kernel_exist?(params.name, params.ipython_dir)
        unless params.force
          $stderr.puts "IRuby kernel named `#{params.name}` already exists!"
          $stderr.puts "Use --force to force register the new kernel."
          exit 1
        end
      end

      Dir.mktmpdir("iruby_kernel") do |tmpdir|
        path = File.join(tmpdir, DEFAULT_KERNEL_NAME)
        FileUtils.mkdir_p(path)

        # Stage assets
        assets_dir = File.expand_path("../assets", __FILE__)
        FileUtils.cp_r(Dir.glob(File.join(assets_dir, "*")), path)

        kernel_dict = {
          "argv" => make_iruby_cmd(),
          "display_name" => params.display_name || DEFAULT_DISPLAY_NAME,
          "language" => "ruby",
          "metadata" => {"debugger": false}
        }

        # TODO: Support params.profile
        # TODO: Support params.env

        kernel_content = JSON.pretty_generate(kernel_dict)
        File.write(File.join(path, "kernel.json"), kernel_content)

        args = ["--name=#{params.name}"]
        args << "--user" if params.user
        args << path

        # TODO: Support params.prefix
        # TODO: Support params.sys_prefix

        system("jupyter", "kernelspec", "install", *args)
      end
    end

    # Warn the existence of the IRuby kernel in the default IPython's kernels directory
    private def check_and_warn_kernel_in_default_ipython_directory(params)
      default_ipython_kernels_dir = File.expand_path("~/.ipython/kernels")
      [params.name, "ruby"].each do |name|
        if File.exist?(File.join(default_ipython_kernels_dir, name, "kernel.json"))
          warn "IRuby kernel `#{name}` already exists in the deprecated IPython's data directory."
        end
      end
    end

    alias __system__ system

    private def system(*cmdline, dry_run: false)
      $stderr.puts "EXECUTE: #{cmdline.map {|x| x.include?(' ') ? x.inspect : x}.join(' ')}"
      __system__(*cmdline) unless dry_run
    end

    private def installed_kernel_exist?(name, ipython_dir)
      kernels_dir = resolve_kernelspec_dir(ipython_dir)
      kernel_dir = File.join(kernels_dir, name)
      File.file?(File.join(kernel_dir, "kernel.json"))
    end

    private def resolve_kernelspec_dir(ipython_dir)
      if ENV.has_key?("JUPYTER_DATA_DIR")
        if ENV.has_key?("IPYTHONDIR")
          warn "both JUPYTER_DATA_DIR and IPYTHONDIR are supplied; IPYTHONDIR is ignored."
        end
        jupyter_data_dir = ENV["JUPYTER_DATA_DIR"]
        return File.join(jupyter_data_dir, "kernels")
      end

      if ipython_dir.nil? && ENV.key?("IPYTHONDIR")
        warn 'IPYTHONDIR is deprecated. Use JUPYTER_DATA_DIR instead.'
        ipython_dir = ENV["IPYTHONDIR"]
      end

      if ipython_dir
        File.join(ipython_dir, 'kerenels')
      else
        Jupyter.kernelspec_dir
      end
    end

    private def make_iruby_cmd(executable: nil, extra_arguments: nil)
      executable ||= default_executable
      extra_arguments ||= []
      [*Array(executable), "kernel", "-f", "{connection_file}", *extra_arguments]
    end

    private def default_executable
      [RbConfig.ruby, @iruby_executable]
    end

    private def parse_register_command_line(argv)
      opts = OptionParser.new
      opts.banner = "Usage: #{$PROGRAM_NAME} register [options]"

      params = RegisterParams.new

      opts.on(
        "--force",
        "Force register a new kernel spec.  The existing kernel spec will be removed."
      ) { params.force = true }

      opts.on(
        "--user",
        "Register for the current user instead of system-wide."
      ) { params.user = true }

      opts.on(
        "--name=VALUE", String,
        "Specify a name for the kernelspec. This is needed to have multiple IRuby kernels at the same time."
      ) {|v| params.name = v }

      opts.on(
        "--display-name=VALUE", String,
        "Specify the display name for the kernelspec. This is helpful when you have multiple IRuby kernels."
      ) {|v| kernel_display_name = v }

      # TODO: --profile
      # TODO: --prefix
      # TODO: --sys-prefix
      # TODO: --env

      define_ipython_dir_option(opts, params)

      opts.order!(argv)

      params
    end

    UnregisterParams = Struct.new(
      :names,
      #:profile,
      #:user,
      #:prefix,
      #:sys_prefix,
      :ipython_dir,
      :force,
      :yes
    ) do
      def initialize(*args, **kw)
        super
        self.names = []
        # self.user = true
        self.force = false
        self.yes = false
      end
    end

    def unregister_kernel(argv)
      params = parse_unregister_command_line(argv)
      opts = []
      opts << "-y" if params.yes
      opts << "-f" if params.force
      system("jupyter", "kernelspec", "uninstall", *opts, *params.names)
    end

    private def parse_unregister_command_line(argv)
      opts = OptionParser.new
      opts.banner = "Usage: #{$PROGRAM_NAME} unregister [options] NAME [NAME ...]"

      params = UnregisterParams.new

      opts.on(
        "-f", "--force",
        "Force removal, don't prompt for confirmation."
      ) { params.force = true}

      opts.on(
        "-y", "--yes",
        "Answer yes to any prompts."
      ) { params.yes = true }

      # TODO: --user
      # TODO: --profile
      # TODO: --prefix
      # TODO: --sys-prefix

      define_ipython_dir_option(opts, params)

      opts.order!(argv)

      params.names = argv.dup

      params
    end

    def exec_jupyter(sub_cmd, argv)
      opts = OptionParser.new
      opts.banner = "Usage: #{$PROGRAM_NAME} unregister [options]"

      kernel_name = resolve_installed_kernel_name(DEFAULT_KERNEL_NAME)
      opts.on(
        "--kernel=NAME", String,
        "The name of the default kernel to start."
      ) {|v| kernel_name = v }

      opts.order!(argv)

      opts = ["--kernel=#{kernel_name}"]
      exec("jupyter", "console", *opts)
    end

    private def resolve_installed_kernel_name(default_name)
      kernels = IO.popen(["jupyter", "kernelspec", "list", "--json"], "r", err: File::NULL) do |jupyter_out|
        JSON.load(jupyter_out.read)
      end
      unless kernels["kernelspecs"].key?(default_name)
        return "ruby" if kernels["kernelspecs"].key?("ruby")
      end
      default_name
    end

    private def define_ipython_dir_option(opts, params)
      opts.on(
        "--ipython-dir=DIR", String,
        "Specify the IPython's data directory (DEPRECATED)."
      ) do |v|
        if ENV.key?("JUPYTER_DATA_DIR")
          warn 'Both JUPYTER_DATA_DIR and --ipython-dir are supplied; --ipython-dir is ignored.'
        else
          warn '--ipython-dir is deprecated. Use JUPYTER_DATA_DIR environment variable instead.'
        end

        params.ipython_dir = v
      end
    end
  end
end
