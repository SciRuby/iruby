require 'zmq'
require 'em-websocket'
require 'stringio'
require 'cgi'
require File.expand_path('../console', __FILE__)
require File.expand_path('../interactive_client', __FILE__)
require File.expand_path('../session', __FILE__)

EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8123) do |ws|
  $ws = ws

  class BrowserIO < StringIO
    def initialize(session, socket, name)
      @session = session
      @socket = socket
      @name = name
    end

    def write s
      content = { name: @name, data: s }
      msg = @session.msg('stream', content, @parent_header) if @session
      @socket.send(msg.to_json)
    end
    alias puts write
    alias print write
  end

  def main
    ip = '127.0.0.1'
    #ip = '99.146.222.252'
    port_base = 5555
    connection = ('tcp://%s' % ip) + ':%i'
    req_conn = connection % port_base
    sub_conn = connection % (port_base+1)

    # Create initial sockets
    c = ZMQ::Context.new
    request_socket = c.socket(ZMQ::XREQ)
    request_socket.connect(req_conn)

    sub_socket = c.socket(ZMQ::SUB)
    sub_socket.connect(sub_conn)
    sub_socket.setsockopt(ZMQ::SUBSCRIBE, '')

    # Make session and user-facing client
    sess = Session.new

    @stdout = BrowserIO.new(sess, $ws, 'stdout')
    @stderr = BrowserIO.new(sess, $ws, 'stderr')

    Object.const_set("STDOUT", @stdout)
    Object.const_set("STDERR", @stderr)

    @client = InteractiveClient.new(sess, request_socket, sub_socket)
    #client.interact()
  end

  main() # LOL GLOBALS

  def handle_message(msg)
    @client.runcode(msg)
  end

  ws.onopen { } #ws.send "Hello Client" }
  ws.onmessage do |msg|
    handle_message(msg)
  end
  ws.onclose { puts "Websocket closed" }
end
