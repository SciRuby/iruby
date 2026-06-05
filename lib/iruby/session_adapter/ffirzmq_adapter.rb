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
        # Avoid ZMQ::Device in #357; call libzmq's proxy directly.
        rc = LibZMQ.zmq_proxy(sock.socket, sock.socket, nil)
        errno = ZMQ::Util.errno
        return if rc == -1 && (zmq_errno?(:ETERM, errno) || zmq_errno?(:EINTR, errno))

        ZMQ::Util.error_check('zmq_proxy', rc)
      end

      def shutdown_heartbeat(sock)
        if @zmq_context&.context && LibZMQ.respond_to?(:zmq_ctx_shutdown)
          LibZMQ.zmq_ctx_shutdown(@zmq_context.context)
        else
          close_socket(sock)
        end
      end

      def close
        @zmq_context&.terminate
        @zmq_context = nil
      end

      private

      def make_socket(type_symbol, protocol, host, port)
        case type_symbol
        when :ROUTER, :PUB, :REP
          type = ZMQ.const_get(type_symbol)
        else
          if ZMQ.const_defined?(type_symbol)
            raise ArgumentError, "Unsupported ZMQ socket type: #{type_symbol}"
          else
            raise ArgumentError, "Invalid ZMQ socket type: #{type_symbol}"
          end
        end
        zmq_context.socket(type).tap do |sock|
          sock.setsockopt(ZMQ::LINGER, 0) if type_symbol == :REP
          sock.bind("#{protocol}://#{host}:#{port}")
        end
      end

      def zmq_context
        @zmq_context ||= ZMQ::Context.new
      end

      def zmq_errno?(name, errno)
        ZMQ.const_defined?(name) && ZMQ.const_get(name) == errno
      end
    end
  end
end
