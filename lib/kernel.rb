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

class OutStream
  #A file like object that publishes the stream to a 0MQ PUB socket.

  def initialize session, pub_socket, name, max_buffer=200
    @session = session
    @pub_socket = pub_socket
    @name = name
    @_buffer = []
    @_buffer_len = 0
    @max_buffer = max_buffer
    @parent_header = {}
  end

  def set_parent parent
    @parent_header = extract_header(parent)
  end

  def close
    @pub_socket = nil
  end

  def flush
    if self.pub_socket.nil?
      raise 'I/O operation on closed file'
    else
      if @_buffer
        data = ''.join(@_buffer)
        content = { name: @name, data: data }
        msg = session.msg('stream', content, @parent_header)
        # FIXME: Wha?
        STDOUT.puts msg
        @pub_socket.send_json(msg)
        @_buffer_len = 0
        @_buffer = []
      end
    end
  end

  def isattr
    return false
  end

  def next
    raise 'Read not supported on a write only stream.'
  end

  def read size=0
    raise 'Read not supported on a write only stream.'
  end
  alias readline read

  def write s
    if @pub_socket.nil?
      raise 'I/O operation on closed file'
    else
      @_buffer.append(s)
      @_buffer_len += len(s)
      _maybe_send
    end
  end

  def _maybe_send
    if self._buffer[-1].include?('\n')
      flush
    end
    if @_buffer_len > @max_buffer
      flush
    end
  end

  def writelines sequence
    if @pub_socket.nil?
      raise 'I/O operation on closed file'
    else
      sequence.each do |s|
        write(s)
      end
    end
  end
end

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
    msg = @session.msg('pyout', {data:repr(obj)}, @parent_header)
    @pub_socket.send_json(msg)
  end

  def set_parent parent
    @parent_header = extract_header(parent)
  end
end

class RawInput
  def initialize session, socket
    @session = session
    @socket = socket
  end

  def __call__ prompt=nil
    msg = @session.msg('raw_input')
    @socket.send_json(msg)
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
  def initialize session, reply_socket, pub_socket
    @session = session
    @reply_socket = reply_socket
    @pub_socket = pub_socket
    @user_ns = {}
    @history = []
    @compiler = CommandCompiler()
    @completer = KernelCompleter(self.user_ns)

    # Build dict of handlers for message types
    @handlers = {}
    ['execute_request', 'complete_request'].each do |msg_type|
      @handlers[msg_type] = getattr(msg_type)
    end
  end

  def abort_queue
    while true
      begin
        ident = @reply_socket.recv(ZMQ::NOBLOCK)
      rescue Exception => e
        if e.errno == ZMQ::EAGAIN
          break
        else
          assert self.reply_socket.rcvmore(), "Unexpected missing message part."
          msg = self.reply_socket.recv_json()
        end
      end
      STDOUT.puts "Aborting:"
      STDOUT.puts msg
      msg_type = msg['msg_type']
      reply_type = msg_type.split('_')[0] + '_reply'
      reply_msg = @session.msg(reply_type, {status: 'aborted'}, msg)
      STDOUT.puts reply_msg
      @reply_socket.send(ident,ZMQ::SNDMORE)
      @reply_socket.send_json(reply_msg)
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
    pyin_msg = @session.msg('pyin',{code: code}, parent=parent)
    @pub_socket.send_json(pyin_msg)
    begin
      comp_code = compiler(code, '<zmq-kernel>')
      sys.displayhook.set_parent(parent)
      eval(comp_code,  @user_ns)
    rescue
      result = 'error'
      etype, evalue, tb = sys.exc_info()
      tb = traceback.format_exception(etype, evalue, tb)
      exc_content = {
          status: 'error',
          traceback: tb,
          etype: unicode(etype),
          evalue: unicode(evalue)
      }
      exc_msg = self.session.msg('pyerr', exc_content, parent)
      self.pub_socket.send_json(exc_msg)
      reply_content = exc_content
    end
    reply_msg = @session.msg('execute_reply', reply_content, parent)
    STDOUT.puts reply_msg
    @reply_socket.send(ident, ZMQ::SNDMORE)
    @reply_socket.send_json(reply_msg)
    if reply_msg['content']['status'] == 'error'
      @abort_queue
    end
  end

  def complete_request(ident, parent)
    matches = { matches: complete(parent), status: 'ok' }
    completion_msg = @session.send(@reply_socket, 'complete_reply',
                                       matches, parent, ident)
    STDOUT.puts completion_msg
  end

  def complete(msg)
    raise 'no completion, lol'
    return @completer.complete(msg.content.line, msg.content.text)
  end

  def start
    while true
      ident = @reply_socket.recv()
      assert @reply_socket.rcvmore(), "Unexpected missing message part."
      msg = @reply_socket.recv_json()
      omsg = msg
      STDOUT.puts omsg
      handler = @handlers[omsg.msg_type]
      if handler.nil?
        STDERR.puts "UNKNOWN MESSAGE TYPE: #{omsg}"
      else
        handler(ident, omsg)
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

  STDOUT.puts "Starting the kernel..."
  STDOUT.puts "On:",rep_conn, pub_conn

  session = Session.new('kernel')

  reply_socket = c.socket(ZMQ::XREP)
  reply_socket.bind(rep_conn)

  pub_socket = c.socket(ZMQ::PUB)
  pub_socket.bind(pub_conn)

  stdout = OutStream.new(session, pub_socket, 'stdout')
  stderr = OutStream.new(session, pub_socket, 'stderr')
  sys.stdout = stdout
  sys.stderr = stderr

  display_hook = new DisplayHook(session, pub_socket)
  sys.displayhook = display_hook

  kernel = RKernel.new(session, reply_socket, pub_socket)

  # For debugging convenience, put sleep and a string in the namespace, so we
  # have them every time we start.
  kernel.user_ns['sleep'] = time.sleep
  kernel.user_ns['s'] = 'Test string'

  STDOUT.puts "Use Ctrl-\\ (NOT Ctrl-C!) to terminate."
  kernel.start()
end


if __FILE__ == $0
  main()
end
