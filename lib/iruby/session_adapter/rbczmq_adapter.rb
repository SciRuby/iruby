module IRuby
  module SessionAdapter
    class RbczmqAdapter < BaseAdapter
      def self.load_requirements
        require 'rbczmq'
      end

      def send(sock, data)
        sock.send_message(ZMQ::Message(*data))
      end

      def recv(sock)
        sock.recv_message
      end

      def heartbeat_loop(sock)
        ZMQ.proxy(socket, socket)
      end

      private

      def make_socket(type, protocol, host, port)
        zmq_context.socket(type).tap do |sock|
          sock.bind("#{protocol}://#{host}:#{port}")
        end
      end

      def zmq_context
        @zmq_context ||= ZMQ::Context.new
      end
    end
  end
end
