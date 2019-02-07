module IRuby
  module SessionAdapter
    class CztopAdapter < BaseAdapter
      def self.load_requirements
        require 'cztop'
      end

      def send(sock, data)
        sock << data
      end

      def recv(sock)
        sock.receive
      end

      def heartbeat_loop(sock)
        loop do
          message = sock.receive
          sock << message
        end
      end

      private

      def socket_type_class(type_symbol)
        case type_symbol
        when :ROUTER, :PUB, :REP
          CZTop::Socket.const_get(type_symbol)
        else
          if CZTop::Socket.const_defined?(type_symbol)
            raise ArgumentError, "Unsupported ZMQ socket type: #{type_symbol}"
          else
            raise ArgumentError, "Invalid ZMQ socket type: #{type_symbol}"
          end
        end
      end

      def make_socket(type_symbol, protocol, host, port)
        uri = "#{protocol}://#{host}:#{port}"
        socket_class = socket_type_class(type_symbol)
        socket_class.new(uri)
      end
    end
  end
end
