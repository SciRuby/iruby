module IRuby
  module SessionAdapter
    class FfirzmqAdapter < BaseAdapter
      def self.load_requirements
        require 'ffi-rzmq'
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
