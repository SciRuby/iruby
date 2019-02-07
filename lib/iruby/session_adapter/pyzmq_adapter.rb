module IRuby
  module SessionAdapter
    class PyzmqAdapter < BaseAdapter
      def self.load_requirements
        require 'pycall'
        @zmq = PyCall.import_module('zmq')
      rescue PyCall::PyError => error
        raise LoadError, error.message
      end

      class << self
        attr_reader :zmq
      end

      def make_router_socket(protocol, host, port)
        make_socket(:ROUTER, protocol, host, port)
      end

      def make_pub_socket(protocol, host, port)
        make_socket(:PUB, protocol, host, port)
      end

      def make_pub_socket(protocol, host, port)
        make_socket(:REP, protocol, host, port)
      end


      private

      def socket_type(type_symbol)
        case type_symbol
        when :ROUTER, :PUB
          zmq.__getattr__(type_symbol)
        else
          if zmq.__hasattr__(type_symbol)
            raise ArgumentError, "Unsupported ZMQ socket type: #{type_symbol}"
          else
            raise ArgumentError, "Unknown ZMQ socket type: #{type_symbol}"
          end
        end
      end

      def make_socket(type_symbol, protocol, host, port)
        type = socket_type(type_symbol)
        zmq_context.socket(type)
        bind_socket(sock, protocol, host, port)
      end

      def bind_socket(sock, protocol, host, port)
        iface = "#{protocol}://#{host}"
        case protocol
        when 'tcp'
          if port <= 0
            port = sock.bind_to_random_port(iface)
          else
            sock.bind("#{iface}:#{port}")
          end
        else
          raise ArgumentError, "Unsupported protocol: #{protocol}"
        end
        [sock, port]
      end

      def zmq_context
        zmq.Context.instance.()
      end

      def zmq
        self.class.zmq
      end
    end
  end
end
