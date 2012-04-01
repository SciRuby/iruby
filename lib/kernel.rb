#!/usr/bin/env ruby
=begin
A simple interactive kernel that talks to a frontend over 0MQ.

Things to do:

* Finish implementing `raw_input`.
* Implement `set_parent` logic. Right before doing exec, the Kernel should
  call set_parent on all the PUB objects with the message about to be executed.
* Implement random port and security key logic.
* Implement control messages.
* Implement event loop and poll version.
=end

require 'zmq'
require 'json'
require 'ostruct'
require File.expand_path('../session', __FILE__)
require File.expand_path('../outstream', __FILE__)

class DisplayHook
  def initialize session, pub_socket
    @session = session
    @pub_socket = pub_socket
    @parent_header = {}
  end

  def __call__(obj)
    if obj.nil?
      return
    end

    __builtin__._ = obj
    STDERR.puts "displayhook call:"
    STDERR.puts @parent_header.inspect
    msg = @session.msg('pyout', {data:repr(obj)}, @parent_header)
    @pub_socket.send(msg.to_json)
  end

  def set_parent parent
    @parent_header = Message.extract_header(parent)
  end
end

class RawInput
  def initialize session, socket
    @session = session
    @socket = socket
  end

  def __call__ prompt=nil
    msg = @session.msg('raw_input')
    @socket.send(msg.to_json)
    while true
      begin
        reply = @socket.recv_json(ZMQ::NOBLOCK)
      rescue Exception => e
        if e.errno == ZMQ::EAGAIN
          pass
        else
          raise
        end
      end
    end

    return reply['content']['data']
  end
end

class RKernel
  attr_accessor :user_ns

  def initialize session, reply_socket, pub_socket
    @session = session
    @reply_socket = reply_socket
    @pub_socket = pub_socket
    @user_ns = OpenStruct.new.send(:binding)
    @history = []
    #@compiler = CommandCompiler.new()
    #@completer = KernelCompleter(@user_ns)

    # Build dict of handlers for message types
    @handlers = {}
    ['execute_request', 'complete_request'].each do |msg_type|
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
      reply_msg = @session.msg(reply_type, {status: 'aborted'}, msg)
      @reply_socket.send(ident,ZMQ::SNDMORE)
      @reply_socket.send(reply_msg.to_json)
      # We need to wait a bit for requests to come in. This can probably
      # be set shorter for true asynchronous clients.
      sleep(0.1)
    end
  end

  def execute_request(ident, parent)
    begin
      code = parent['content']['code']
    rescue
      STDERR.puts "Got bad msg: "
      STDERR.puts parent
      return
    end
    pyin_msg = @session.msg('pyin',{code: code}, parent)
    #$stderr.puts pyin_msg.to_json
    @pub_socket.send(pyin_msg.to_json)
    begin
      STDERR.puts 'parent: '
      STDERR.puts parent.inspect
      comp_code = code#compiler(code, '<zmq-kernel>')
      $displayhook.set_parent(parent)
      $stdout.set_parent(parent)

      eval(comp_code, @user_ns)
    rescue Exception => e
      #$stderr.puts e.inspect
      result = 'error'
      #etype, evalue, tb = sys.exc_info()
      etype, evalue, tb = e.class.to_s, e.message, e.backtrace
      #tb = traceback.format_exception(etype, evalue, tb)
      #tb = "1, 2, 3"
      exc_content = {
          status: 'error',
          traceback: tb.join("\n"),
          etype: etype,
          evalue: evalue
      }
      exc_msg = @session.msg('pyerr', exc_content, parent)
      @pub_socket.send(exc_msg.to_json)
      reply_content = exc_content
    end
    reply_content = {status: 'ok'}
    reply_msg = @session.msg('execute_reply', reply_content, parent)
    #$stdout.puts reply_msg
    #$stderr.puts reply_msg
    @reply_socket.send(ident, ZMQ::SNDMORE)
    @reply_socket.send(reply_msg.to_json)
    if reply_msg['content']['status'] == 'error'
      abort_queue
    end
  end

  def complete_request(ident, parent)
    matches = { matches: complete(parent), status: 'ok' }
    completion_msg = @session.send(@reply_socket, 'complete_reply',
                                       matches, parent, ident)
    $stdout.puts completion_msg
  end

  def complete(msg)
    raise 'no completion, lol'
    return @completer.complete(msg.content.line, msg.content.text)
  end

  def start(displayhook)
    while true
      ident = @reply_socket.recv()
      #assert @reply_socket.rcvmore(), "Unexpected missing message part."
      msg = @reply_socket.recv()
      msg = JSON.parse(msg) if msg
      omsg = msg
      handler = @handlers[omsg['header']['msg_type']]
      if handler.nil?
        err.puts "UNKNOWN MESSAGE TYPE: #{omsg}"
      else
        displayhook.__call__(send(handler, ident, omsg))
      end
    end
  end
end

def main
  c = ZMQ::Context.new

  ip = '127.0.0.1'
  port_base = 5555
  connection = ('tcp://%s' % ip) + ':%i'
  rep_conn = connection % port_base
  pub_conn = connection % (port_base+1)

  $stdout.puts "Starting the kernel..."
  $stdout.puts "On:",rep_conn, pub_conn

  session = Session.new('kernel')

  reply_socket = c.socket(ZMQ::XREP)
  reply_socket.bind(rep_conn)

  pub_socket = c.socket(ZMQ::PUB)
  pub_socket.bind(pub_conn)

  stdout = OutStream.new(session, pub_socket, 'stdout')
  #stderr = OutStream.new(session, pub_socket, 'stderr')
  old_stdout = STDOUT
  $stdout = stdout
  #$stderr = stderr

  display_hook = DisplayHook.new(session, pub_socket)
  $displayhook = display_hook

  kernel = RKernel.new(session, reply_socket, pub_socket)

  # For debugging convenience, put sleep and a string in the namespace, so we
  # have them every time we start.
  #kernel.user_ns['sleep'] = sleep
  #kernel.user_ns['s'] = 'Test string'

  old_stdout.puts "Use Ctrl-\\ (NOT Ctrl-C!) to terminate."
  kernel.start(display_hook)
end


if __FILE__ == $0
  main()
end
