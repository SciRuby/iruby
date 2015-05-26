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
        rescue Exception => ex
          IRuby.logger.fatal "Kernel heartbeat died: #{ex.message}\n#{ex.backtrace.join("\n")}"
        end
      end

      @sockets = { publish: pub_socket, reply: reply_socket }
      @session = SecureRandom.uuid
      @msg_id = 0
      if config['key'] && config['signature_scheme']
        raise 'Unknown signature scheme' unless config['signature_scheme'] =~ /\Ahmac-(.*)\Z/
        @hmac = OpenSSL::HMAC.new(config['key'], OpenSSL::Digest.new($1))
      end
    end

    # Build and send a message
    def send(socket, type, content, ident=nil)
      header = {
        msg_type: type,
        msg_id:   @msg_id,
        username: 'kernel',
        session:  @session,
        version:  '5.0'
      }
      @msg_id += 1

      @sockets[socket].send_message(serialize(header, content, ident))
    end

    # Receive a message and decode it
    def recv(socket)
      idents, msg = unserialize(@sockets[socket].recv_message)
      @last_received_header = msg[:header]
      return idents, msg
    end

    private

    def serialize(header, content, ident)
      msg = [MultiJson.dump(header),
             MultiJson.dump(@last_received_header || {}),
             '{}',
             MultiJson.dump(content || {})]
      #STDERR.puts "SEND #{(([ident].flatten.compact << DELIM << sign(msg)) + msg).inspect}"
      ZMQ::Message(*(([ident].flatten.compact << DELIM << sign(msg)) + msg))
    end

    def unserialize(msg)
      raise 'no message received' unless msg
      parts = []
      while frame = msg.popstr
        parts << frame
      end
      #STDERR.puts "RECV #{parts.inspect}"

      i = parts.index(DELIM)
      idents, msg_list = parts[0..i-1], parts[i+1..-1]

      minlen = 5
      raise 'malformed message, must have at least #{minlen} elements' unless msg_list.length >= minlen
      s, header, parent_header, metadata, content, buffers = *msg_list
      raise 'Invalid signature' unless s == sign(msg_list[1..-1])
      return idents, {
        header: MultiJson.load(header),
        parent_header: MultiJson.load(parent_header),
        metadata: MultiJson.load(metadata),
        content: MultiJson.load(content),
        buffers: buffers
      }
    end

    # Sign using HMAC
    def sign(list)
      if @hmac
        @hmac.reset
        list.each {|m| @hmac.update(m) }
        @hmac.hexdigest
      else
        ''
      end
    end
  end
end
