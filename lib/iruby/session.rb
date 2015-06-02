module IRuby
  class Session
    DELIM = '<IDS|MSG>'

    def initialize(config)
      c = ZMQ::Context.new

      connection = "#{config['transport']}://#{config['ip']}:%d"
      reply_socket = c.socket(:ROUTER)
      reply_socket.bind(connection % config['shell_port'])

      pub_socket = c.socket(:PUB)
      pub_socket.bind(connection % config['iopub_port'])

      Thread.new do
        begin
          hb_socket = c.socket(:REP)
          hb_socket.bind(connection % config['hb_port'])
          ZMQ.proxy(hb_socket, hb_socket)
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
      @sockets[socket].send_message(serialize(idents, header, content))
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

    def unserialize(msg)
      raise 'no message received' unless msg
      frames = msg.to_a.map(&:to_s)
      IRuby.logger.debug "Received #{frames.inspect}"

      i = frames.index(DELIM)
      idents, msg_list = frames[0..i-1], frames[i+1..-1]

      minlen = 5
      raise 'malformed message, must have at least #{minlen} elements' unless msg_list.length >= minlen
      s, header, parent_header, metadata, content, buffers = *msg_list
      raise 'Invalid signature' unless s == sign(msg_list[1..-1])
      {
        idents:        idents,
        header:        MultiJson.load(header),
        parent_header: MultiJson.load(parent_header),
        metadata:      MultiJson.load(metadata),
        content:       MultiJson.load(content),
        buffers:       buffers
      }
    end

    # Sign using HMAC
    def sign(list)
      return '' unless @hmac
      @hmac.reset
      list.each {|m| @hmac.update(m) }
      @hmac.hexdigest
    end
  end
end
