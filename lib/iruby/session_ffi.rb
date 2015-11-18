# This file is for the compativility with ffi-rzmq which was replaced by rbczmq in IRuby v0.2.0
module IRuby
  class Session
    def initialize(config)
      c = ZMQ::Context.new

      connection = "#{config['transport']}://#{config['ip']}:%d"
      reply_socket = c.socket(ZMQ::XREP)
      reply_socket.bind(connection % config['shell_port'])

      pub_socket = c.socket(ZMQ::PUB)
      pub_socket.bind(connection % config['iopub_port'])

      Thread.new do
        begin
          hb_socket = c.socket(ZMQ::REP)
          hb_socket.bind(connection % config['hb_port'])
          ZMQ::Device.new(hb_socket, hb_socket)
        rescue Exception => e
          IRuby.logger.fatal "Kernel heartbeat died: #{e.message}\n#{e.backtrace.join("\n")}"
        end
      end

      @sockets = { publish: pub_socket, reply: reply_socket }
      @session = SecureRandom.uuid
      unless config['key'].to_s.empty? || config['signature_scheme'].to_s.empty?
        raise 'Unknown signature scheme' unless config['signature_scheme'] =~ /\Ahmac-(.*)\Z/
        @hmac = OpenSSL::HMAC.new(config['key'], OpenSSL::Digest.new($1))
      end
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
      socket = @sockets[socket]
      list = serialize(header, content, idents)
      list.each_with_index do |part, i|
        socket.send_string(part, i == list.size - 1 ? 0 : ZMQ::SNDMORE)
      end
    end

    # Receive a message and decode it
    def recv(socket)
      @last_recvd_msg = unserialize(@sockets[socket].recv_message)
    end

    private

    def serialize(idents, header, content)
      msg = [MultiJson.dump(header),
             MultiJson.dump(@last_recvd_msg ? @last_recvd_msg[:header] : {}),
             '{}',
             MultiJson.dump(content || {})]
      frames = ([*idents].compact.map(&:to_s) << DELIM << sign(msg)) + msg
      IRuby.logger.debug "Sent #{frames.inspect}"
      ZMQ::Message(*frames)
    end
  end
end
