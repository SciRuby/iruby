require 'zmq'
require 'em-websocket'
require 'stringio'
require File.expand_path('../console', __FILE__)
require File.expand_path('../interactive_client', __FILE__)
require File.expand_path('../session', __FILE__)

EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8123) do |ws|
  class BrowserIO < StringIO
    def initialize(socket)
      @socket = socket
    end

    def write s
      @socket.send(s.dup)
    end
    alias puts write
    alias print write
  end

  @stdout = BrowserIO.new(ws)
  #@stderr = BrowserIO.new(ws)

  $stdout = @stdout
  STDOUT = @stdout
  #$stderr = @stderr

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
    @client = InteractiveClient.new(sess, request_socket, sub_socket)
    #client.interact()
  end

  main() # LOL GLOBALS

  def handle_message(msg)
    @client.runcode(msg)
  end

  ws.onopen { ws.send "Hello Client" }
  ws.onmessage do |msg|
    out = handle_message(msg)
    ws.send(out) unless out.nil?
  end
  ws.onclose { puts "Websocket closed" }
end
