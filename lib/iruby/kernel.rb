module IRuby
  class Kernel
    RED = "\e[31m"
    WHITE = "\e[37m"
    RESET = "\e[0m"

    class<< self
      attr_accessor :instance
    end

    def initialize(config_file)
      @config = MultiJson.load(File.read(config_file))

      #puts 'Starting the kernel'
      #puts config
      #puts 'Use Ctrl-\\ (NOT Ctrl-C!) to terminate.'

      Kernel.instance = self

      c = ZMQ::Context.new

      connection = "#{@config['transport']}://#{@config['ip']}:%d"
      @reply_socket = c.socket(ZMQ::XREP)
      @reply_socket.bind(connection % @config['shell_port'])

      @pub_socket = c.socket(ZMQ::PUB)
      @pub_socket.bind(connection % @config['iopub_port'])

      Thread.new do
        hb_socket = c.socket(ZMQ::REP)
        hb_socket.bind(connection % @config['hb_port'])
        ZMQ::Device.new(ZMQ::FORWARDER, hb_socket, hb_socket)
      end

      @session = Session.new('kernel', @config)

      $stdout = OStream.new(@session, @pub_socket, 'stdout')
      $stderr = OStream.new(@session, @pub_socket, 'stderr')

      @execution_count = 0
      begin
        require 'pry'
        @backend = PryBackend.new
      rescue LoadError
        @backend = PlainBackend.new
      end
    end

    def run
      send_status('starting')
      while true
        ident, msg = @session.recv(@reply_socket, 0)
        type = msg[:header]['msg_type']
        if type =~ /_request\Z/ && respond_to?(type)
          send(type, ident, msg)
        else
          STDERR.puts "Unknown message type: #{msg[:header]['msg_type']} #{msg.inspect}"
        end
      end
    end

    def display(obj, options={})
      if obj
        mime, data = display_handler(obj, options)
        content = { data: { mime => data }, metadata: {}, execution_count: @execution_count }
        @session.send(@pub_socket, 'pyout', content)
      end
      nil
    end

    def display_handler(obj, options)
      if options[:mime]
        [options[:mime], obj.to_s]
      elsif obj.respond_to?(:to_iruby)
        obj.to_iruby
      elsif (defined?(Gruff::Base) && Gruff::Base === obj) ||
          (defined?(Magick::Image) && Magick::Image === obj)
        ['image/png', [obj.to_blob].pack('m0')]
      elsif obj.respond_to?(:path) && File.readable?(obj.path)
        mime = MimeMagic.by_path(obj.path).to_s
        if %w(image/png image/jpeg text/html).include?(mime)
          [mime, [File.read(obj.path)].pack('m0')]
        else
          ['text/plain', obj.to_s]
        end
      else
        ['text/plain', obj.to_s]
      end
    end

    def kernel_info_request(ident, msg)
      content = {
        protocol_version: [4, 0],

        # Language version number (mandatory).
        # It is Python version number (e.g., [2, 7, 3]) for the kernel
        # included in IPython.
        language_version: RUBY_VERSION.split('.').map(&:to_i),

        # Programming language in which kernel is implemented (mandatory).
        # Kernel included in IPython returns 'python'.
        language: 'ruby'
      }
      @session.send(@reply_socket, 'kernel_info_reply', content, ident)
    end

    def send_status(status)
      @session.send(@pub_socket, 'status', execution_state: status)
    end

    def execute_request(ident, msg)
      begin
        code = msg[:content]['code']
      rescue
        STDERR.puts "Got bad message: #{msg.inspect}"
        return
      end
      @execution_count += 1 unless msg[:content].fetch('silent', false)
      send_status('busy')
      @session.send(@pub_socket, 'pyin', code: code)

      result = nil
      begin
        result = @backend.eval(code)
      rescue Exception => e
        content = {
          ename: e.class.to_s,
          evalue: e.message,
          etype: e.class.to_s,
          status: 'error',
          traceback: ["#{RED}#{e.class}#{RESET}: #{e.message}", *e.backtrace.map { |l| "#{WHITE}#{l}#{RESET}" }],
          execution_count: @execution_count
        }
        @session.send(@pub_socket, 'pyerr', content)
      end

      content = {
        status: 'ok',
        payload: [],
        user_variables: {},
        user_expressions: {},
        execution_count: @execution_count
      }
      @session.send(@reply_socket, 'execute_reply', content, ident)

      display(result) if result && !msg[:content]['silent']
      send_status('idle')
    end

    def complete_request(ident, msg)
      content = {
        matches: @backend.complete(msg[:content]['line'], msg[:content]['text']),
        status: 'ok',
        matched_text: msg[:content]['line'],
      }
      @session.send(@reply_socket, 'complete_reply', content, ident)
    end

    def connect_request(ident, msg)
      content = {
        shell_port: config['shell_port'],
        iopub_port: config['iopub_port'],
        stdin_port: config['stdin_port'],
        hb_port:    config['hb_port']
      }
      @session.send(@reply_socket, 'connect_reply', content, ident)
    end

    def shutdown_request(ident, msg)
      @session.send(@reply_socket, 'shutdown_reply', msg[:content], ident)
    end

    def history_request(ident, msg)
      # we will just send back empty history for now, pending clarification
      # as requested in ipython/ipython#3806
      content = {
        history: []
      }
      @session.send(@reply_socket, 'history_reply', content, ident)
    end

    def object_info_request(ident, msg)
      o = @backend.eval(msg[:content]['oname'])
      content = {
        oname: msg[:content]['oname'],
        found: true,
        ismagic: false,
        isalias: false,
        docstring: '', # TODO
        type_class: o.class.to_s,
        type_class: o.class.superclass.to_s,
        string_form: o.inspect
      }
      content[:length] = o.length if o.respond_to?(:length)
      @session.send(@reply_socket, 'object_info_reply', content, ident)
    rescue Exception
      content = {
        oname: msg[:content]['oname'],
        found: false
      }
      @session.send(@reply_socket, 'object_info_reply', content, ident)
    end
  end
end
