module IRuby
  module SessionAdapter
    class FfirzmqAdapter < BaseAdapter
      def self.load_requirements
        require 'ffi-rzmq'
      end

      def send(sock, data)
        data.each_with_index do |part, i|
          sock.send_string(part, i == data.size - 1 ? 0 : ZMQ::SNDMORE)
        end
      end

      def recv(sock)
        msg = []
        while msg.empty? || sock.more_parts?
          begin
            frame = ''
            rc = sock.recv_string(frame)
            ZMQ::Util.error_check('zmq_msg_recv', rc)
            msg << frame
          rescue
          end
        end
        msg
      end

      def heartbeat_loop(sock)
        @heartbeat_device = ZMQ::Device.new(sock, sock)
      end

      private

      def make_socket(type, protocol, host, port)
        case type
        when :ROUTER, :PUB, :REP
          type = ZMQ.const_get(type)
        else
          if ZMQ.const_defined?(type)
            raise ArgumentError, "Unsupported ZMQ socket type: #{type_symbol}"
          else
            raise ArgumentError, "Invalid ZMQ socket type: #{type_symbol}"
          end
        end
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
