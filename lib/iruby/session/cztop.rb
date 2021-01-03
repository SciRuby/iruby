require 'cztop'

module IRuby
  class Session
    include SessionSerialize

    def initialize(config)
      connection = "#{config['transport']}://#{config['ip']}:%d"

      reply_socket = CZTop::Socket::ROUTER.new(connection % config['shell_port'])
      pub_socket = CZTop::Socket::PUB.new(connection % config['iopub_port'])
      stdin_socket = CZTop::Socket::ROUTER.new(connection % config['stdin_port'])

      Thread.new do
        begin
          hb_socket = CZTop::Socket::REP.new(connection % config['hb_port'])
          loop do
            message = hb_socket.receive
            hb_socket << message
          end
        rescue Exception => e
          IRuby.logger.fatal "Kernel heartbeat died: #{e.message}\n#{e.backtrace.join("\n")}"
        end
      end

      @sockets = {
        publish: pub_socket,
        reply: reply_socket,
        stdin: stdin_socket,
      }

      @session = SecureRandom.uuid
      unless config['key'].to_s.empty? || config['signature_scheme'].to_s.empty?
        raise 'Unknown signature scheme' unless config['signature_scheme'] =~ /\Ahmac-(.*)\Z/
        @hmac = OpenSSL::HMAC.new(config['key'], OpenSSL::Digest.new($1))
      end
    end

    def description
      'old-stle session using cztop'
    end

    # Build and send a message
    def send(socket, type, content)
      idents =
        if socket == :reply && @last_recvd_msg
          @last_recvd_msg[:idents]
        else
          type == :stream ? "stream.#{content[:name]}" : type
        end
      header = {
        msg_type: type,
        msg_id:   SecureRandom.uuid,
        username: 'kernel',
        session:  @session,
        version:  '5.0'
      }
      @sockets[socket] << serialize(idents, header, content)
    end

    # Receive a message and decode it
    def recv(socket)
      @last_recvd_msg = unserialize(@sockets[socket].receive)
    end

    def recv_input
      unserialize(@sockets[:stdin].receive)[:content]["value"]
    end
  end
end
