require 'iruby/session_adapter'
require 'iruby/session/mixin'

require 'securerandom'
require 'time'

module IRuby
  class Session
    include SessionSerialize

    def initialize(config, adapter_name=nil)
      @config = config
      @adapter = create_session_adapter(config, adapter_name)
      @last_recvd_msg = nil

      setup
      setup_sockets
      setup_heartbeat
      setup_security
    end

    attr_reader :adapter, :config

    def description
      "#{@adapter.name} session adapter"
    end

    def setup
    end

    def setup_sockets
      protocol, host = config.values_at('transport', 'ip')
      shell_port = config['shell_port']
      iopub_port = config['iopub_port']
      stdin_port = config['stdin_port']

      @shell_socket, @shell_port = @adapter.make_router_socket(protocol, host, shell_port)
      @iopub_socket, @iopub_port = @adapter.make_pub_socket(protocol, host, iopub_port)
      @stdin_socket, @stdin_port = @adapter.make_router_socket(protocol, host, stdin_port)

      @sockets = {
        publish: @iopub_socket,
        reply:   @shell_socket,
        stdin:   @stdin_socket
      }
    end

    def setup_heartbeat
      protocol, host = config.values_at('transport', 'ip')
      hb_port = config['hb_port']
      @hb_socket, @hb_port = @adapter.make_rep_socket(protocol, host, hb_port)
      @heartbeat_thread = Thread.start do
        begin
          # NOTE: this loop is copied from CZTop's old session code
          @adapter.heartbeat_loop(@hb_socket)
        rescue Exception => e
          IRuby.logger.fatal "Kernel heartbeat died: #{e.message}\n#{e.backtrace.join("\n")}"
        end
      end
    end

    def setup_security
      @session_id = SecureRandom.uuid
      unless config['key'].empty? || config['signature_scheme'].empty?
        unless config['signature_scheme'] =~ /\Ahmac-/
          raise "Unknown signature_scheme: #{config['signature_scheme']}"
        end
        digest_algorithm = config['signature_scheme'][/\Ahmac-(.*)\Z/, 1]
        @hmac = OpenSSL::HMAC.new(config['key'], OpenSSL::Digest.new(digest_algorithm))
      end
    end

    def send(socket_type, message_type, content)
      sock = check_socket_type(socket_type)
      idents = if socket_type == :reply && @last_recvd_msg
                 @last_recvd_msg[:idents]
               else
                 message_type == :stream ? "stream.#{content[:name]}" : message_type
               end
      header = {
        msg_type: message_type,
        msg_id:   SecureRandom.uuid,
        date:     Time.now.utc.iso8601,
        username: 'kernel',
        session:  @session_id,
        version:  '5.0'
      }
      @adapter.send(sock, serialize(idents, header, content))
    end

    def recv(socket_type)
      sock = check_socket_type(socket_type)
      data = @adapter.recv(sock)
      @last_recvd_msg = unserialize(data)
    end

    def recv_input
      sock = check_socket_type(:stdin)
      data = @adapter.recv(sock)
      unserialize(data)[:content]["value"]
    end

    private

    def check_socket_type(socket_type)
      case socket_type
      when :publish, :reply, :stdin
        @sockets[socket_type]
      else
        raise ArgumentError, "Invalid socket type #{socket_type}"
      end
    end

    def create_session_adapter(config, adapter_name)
      adapter_class = SessionAdapter.select_adapter_class(adapter_name)
      adapter_class.new(config)
    end
  end
end
