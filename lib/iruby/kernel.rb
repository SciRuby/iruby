require 'ffi-rzmq'
require 'json'
require 'ostruct'
require 'term/ansicolor'

require 'iruby/kernel_completer'
require 'iruby/session'
require 'iruby/out_stream'
require 'iruby/display_hook'
require 'iruby/output/html'


class String
  include Term::ANSIColor
end

module IRuby

  class ResponseWithMime
    def initialize(response, mime)
      @response = response
      @mime = mime
    end
    attr_reader :mime
    def inspect
      @response.inspect
    end
    def to_s
      @response.to_s
    end
  end

  class BindingWithMime < OpenStruct
    def mime_type=(v)
      @mime_type = v
    end
    def mime_type
      @mime_type || 'text/plain'
    end
  end


  class Kernel
    attr_accessor :user_ns

    def self.html(s)
      @output_mime = "text/html"
      s
    end

    def execution_count
      @execution_count
    end

    def output_mime
      @output_mime
    end

    def initialize session, reply_socket, pub_socket
      @session = session
      @reply_socket = reply_socket
      @pub_socket = pub_socket
      @user_ns = BindingWithMime.new.send(:binding)
      @history = []
      @execution_count = 0
      #@compiler = CommandCompiler.new()
      @completer = KernelCompleter.new(@user_ns)

      # Build dict of handlers for message types
      @handlers = {}
      ['execute_request', 'complete_request', 'kernel_info_request'].each do |msg_type|
        @handlers[msg_type] = msg_type
      end
    end

    def abort_queue
      while true
        #begin
          ident = @reply_socket.recv(ZMQ::NOBLOCK)
        #rescue Exception => e
          #if e.errno == ZMQ::EAGAIN
            #break
          #else
            #assert self.reply_socket.rcvmore(), "Unexpected missing message part."
            #msg = self.reply_socket.recv_json()
          #end
        #end
        msg_type = msg['header']['msg_type']
        reply_type = msg_type.split('_')[0] + '_reply'
        @session.send(@reply_socket, reply_type, {status: 'aborted'}, msg)
        # reply_msg = @session.msg(reply_type, {status: 'aborted'}, msg)
        # @reply_socket.send(ident,ZMQ::SNDMORE)
        # @reply_socket.send(reply_msg.to_json)
        # We need to wait a bit for requests to come in. This can probably
        # be set shorter for true asynchronous clients.
        sleep(0.1)
      end
    end

    def kernel_info_request(ident, parent)
      reply_content = {
        protocol_version: [4, 0],

        # Language version number (mandatory).
        # It is Python version number (e.g., [2, 7, 3]) for the kernel
        # included in IPython.
        language_version: RUBY_VERSION.split('.').map { |x| x.to_i },

        # Programming language in which kernel is implemented (mandatory).
        # Kernel included in IPython returns 'python'.
        language: "ruby"
      }
      reply_msg = @session.send(@reply_socket, 'kernel_info_reply',
            reply_content, parent, ident
      )
    end
    
    def send_status(status, parent)
      @session.send(@pub_socket, "status", {execution_state: status}, parent)
    end

    def execute_request(ident, parent)
      begin
        code = parent['content']['code']
      rescue
        STDERR.puts "Got bad msg: "
        STDERR.puts parent
        return
      end
      # pyin_msg = @session.msg()
      if ! parent['content'].fetch('silent', false)
        @execution_count += 1
      end
      self.send_status("busy", parent)
      @session.send(@pub_socket, 'pyin', {code: code}, parent)
      reply_content = {status: 'ok',
          payload: [],
          user_variables: {},
          user_expressions: {},
        }
      begin
        # STDERR.puts 'parent: '
        # STDERR.puts parent.inspect
        comp_code = code#compiler(code, '<zmq-kernel>')
        $displayhook.set_parent(parent)
        $stdout.set_parent(parent)

        eval("@mime_type=nil",@user_ns)
        response = eval(comp_code, @user_ns)
        output = ResponseWithMime.new(response, eval("@mime_type",@user_ns))

        # $stdout.puts(output.inspect) if output
      rescue Exception => e
        # $stderr.puts e.inspect
        #etype, evalue, tb = sys.exc_info()
        ename, evalue, tb = e.class.to_s, e.message, e.backtrace
        tb = format_exception(ename, evalue, tb)
        #tb = "1, 2, 3"
        exc_content = {
          ename: ename,
          evalue: evalue,
          traceback: tb,
          #etype: etype,
          #status: 'error',
        }
        # STDERR.puts exc_content
        @session.send(@pub_socket, 'pyerr', exc_content, parent)

        reply_content = exc_content
      end
      reply_content['execution_count'] = @execution_count
      
      # reply_msg = @session.msg('execute_reply', reply_content, parent)
      #$stdout.puts reply_msg
      #$stderr.puts reply_msg
      #@session.send(@reply_socket, ident + reply_msg)
      reply_msg = @session.send(@reply_socket, 'execute_reply', reply_content, parent, ident)
      if reply_msg['content']['status'] == 'error'
        abort_queue
      end
      if ! parent['content']['silent']
        $displayhook.__call__(output)
      end
      self.send_status("idle", parent)
    end

    def complete_request(ident, parent)
      matches = {
        matches: @completer.complete(parent['content']['line'], parent['content']['text']),
        status: 'ok',
        matched_text: parent['content']['line'],
      }
      completion_msg = @session.send(@reply_socket, 'complete_reply',
                                     matches, parent, ident)
      return nil
    end

    def start(displayhook)
      self.send_status("starting", nil)
      while true
        ident, msg = @session.recv(@reply_socket, 0)
        begin
          handler = @handlers[msg['header']['msg_type']]
        rescue
          handler = nil
        end
        if handler.nil?
          STDERR.puts "UNKNOWN MESSAGE TYPE: #{msg['header']['msg_type']} #{msg}"
        else
          # STDERR.puts 'handling ' + omsg.inspect
          send(handler, ident, msg)
        end
      end
    end

  private
    def format_exception(name, value, backtrace)
      tb = []
      tb << "#{name.red}: #{value}"
      tb.concat(backtrace.map { |l| l.white })
      tb
    end
  end
end
