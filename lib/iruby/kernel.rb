module IRuby
  class Kernel
    RED = "\e[31m"
    WHITE = "\e[37m"
    RESET = "\e[0m"

    def initialize(config_file)
      config = MultiJson.load(File.read(config_file))

      #puts 'Starting the kernel'
      #puts config
      #puts 'Use Ctrl-\\ (NOT Ctrl-C!) to terminate.'

      c = ZMQ::Context.new

      connection = "#{config['transport']}://#{config['ip']}:%d"
      @reply_socket = c.socket(ZMQ::XREP)
      @reply_socket.bind(connection % config['shell_port'])

      @pub_socket = c.socket(ZMQ::PUB)
      @pub_socket.bind(connection % config['iopub_port'])

      @hb_thread = Thread.new do
        hb_socket = c.socket(ZMQ::REP)
        hb_socket.bind(connection % config['hb_port'])
        ZMQ::Device.new(ZMQ::FORWARDER, hb_socket, hb_socket)
      end

      @session = Session.new('kernel', config['key'], config['signature_scheme'])

      $stdout = OStream.new(@session, @pub_socket, 'stdout')
      $stderr = OStream.new(@session, @pub_socket, 'stderr')

      @execution_count = 0
      @completer = Completer.new
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
        data = {}
        data[obj.respond_to?(:mime) ? obj.mime : (options[:mime] || 'text/plain')] = obj.to_s
        content = { data: data, metadata: {}, execution_count: @execution_count }
        @session.send(@pub_socket, 'pyout', content)
      end
      nil
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
      content = {
        status: 'ok',
        payload: [],
        user_variables: {},
        user_expressions: {},
      }
      result = nil
      begin
        result = TOPLEVEL_BINDING.eval(code)
      rescue Exception => e
        content = {
          ename: e.class.to_s,
          evalue: e.message,
          etype: e.class.to_s,
          status: 'error',
          traceback: ["#{RED}#{e.class}#{RESET}: #{e.message}", *e.backtrace.map { |l| "#{WHITE}#{l}#{RESET}" }],
        }
        @session.send(@pub_socket, 'pyerr', content)
      end
      content[:execution_count] = @execution_count

      @session.send(@reply_socket, 'execute_reply', content, ident)
      display(result) if result && !msg[:content]['silent']
      send_status('idle')
    end

    def complete_request(ident, msg)
      content = {
        matches: @completer.complete(msg[:content]['line'], msg[:content]['text']),
        status: 'ok',
        matched_text: msg[:content]['line'],
      }
      @session.send(@reply_socket, 'complete_reply', content, ident)
    end
  end

  module Hooks
    def display(obj, options={})
      $iruby_kernel.display(obj, options)
    end
  end
end

include IRuby::Hooks
