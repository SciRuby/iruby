require 'iruby/session/mixin'

module IRuby
  module SessionAdapter
    class TestAdapter < BaseAdapter
      include IRuby::SessionSerialize

      DummySocket = Struct.new(:type, :protocol, :host, :port)

      def initialize(config)
        super

        unless config['key'].empty? || config['signature_scheme'].empty?
          unless config['signature_scheme'] =~ /\Ahmac-/
            raise "Unknown signature_scheme: #{config['signature_scheme']}"
          end
          digest_algorithm = config['signature_scheme'][/\Ahmac-(.*)\Z/, 1]
          @hmac = OpenSSL::HMAC.new(config['key'], OpenSSL::Digest.new(digest_algorithm))
        end

        @send_callback = nil
        @recv_callback = nil
      end

      attr_accessor :send_callback, :recv_callback

      def send(sock, data)
        unless @send_callback.nil?
          @send_callback.call(sock, unserialize(data))
        end
      end

      def recv(sock)
        unless @recv_callback.nil?
          serialize(@recv_callback.call(sock))
        end
      end

      def heartbeat_loop(sock)
      end

      private

      def make_socket(type, protocol, host, port)
        DummySocket.new(type, protocol, host, port)
      end
    end
  end
end
