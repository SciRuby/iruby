module IRuby
  module SessionAdapter
    class PyzmqAdapter < BaseAdapter

      class << self
        def load_requirements
          require 'pycall'
          import_pyzmq
        end

        def import_pyzmq
          @zmq = PyCall.import_module('zmq')
        rescue PyCall::PyError => error
          raise LoadError, error.message
        end

        attr_reader :zmq
      end

      def make_router_socket(protocol, host, port)
        make_socket(:ROUTER, protocol, host, port)
      end

      def make_pub_socket(protocol, host, port)
        make_socket(:PUB, protocol, host, port)
      end

      def heartbeat_loop(sock)
        PyCall.sys.path.append(File.expand_path('../pyzmq', __FILE__))
        heartbeat = PyCall.import_module('iruby.heartbeat')
        @heartbeat_thread = heartbeat.Heartbeat.new(sock)
        @heartbeat_thread.start
      end

      private

      def socket_type(type_symbol)
        case type_symbol
        when :ROUTER, :PUB, :REP
          zmq[type_symbol]
        else
          raise ArgumentError, "Unknown ZMQ socket type: #{type_symbol}"
        end
      end

      def make_socket(type_symbol, protocol, host, port)
        type = socket_type(type_symbol)
        sock = zmq_context.socket(type)
        bind_socket(sock, protocol, host, port)
        sock
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
        zmq.Context.instance
      end

      def zmq
        self.class.zmq
      end
    end
  end
end
