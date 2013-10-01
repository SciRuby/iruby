module IRuby
  class Session
    DELIM = '<IDS|MSG>'

    def initialize(username, key, sign_scheme)
      @username = username
      @session = SecureRandom.uuid
      @msg_id = 0
      if key && sign_scheme
        raise 'Unknown signature scheme' unless sign_scheme =~ /\Ahmac-(.*)\Z/
        @hmac = OpenSSL::HMAC.new(key, OpenSSL::Digest::Digest.new($1))
      end
    end

    # Build and send a message
    def send(socket, type, content, ident=nil)
      header = {
        msg_type: type,
        msg_id:   @msg_id,
        username: @username,
        session:  @session
      }
      @msg_id += 1

      list = serialize(header, content, ident)
      list.each_with_index do |part, i|
        socket.send_string(part, i == list.size - 1 ? 0 : ZMQ::SNDMORE)
      end
    end

    # Receive a message and decode it
    def recv(socket, mode)
      msg = []
      while msg.empty? || socket.more_parts?
        begin
          frame = ''
          rc = socket.recv_string(frame, mode)
          ZMQ::Util.error_check('zmq_msg_send', rc)
          msg << frame
        rescue
        end
      end

      i = msg.index(DELIM)
      idents, msg_list = msg[0..i-1], msg[i+1..-1]
      msg = unserialize(msg_list)
      @last_received_header = msg[:header]
      return idents, msg
    end

    private

    def serialize(header, content, ident)
      msg = [MultiJson.dump(header),
             MultiJson.dump(@last_received_header || {}),
             '{}',
             MultiJson.dump(content || {})]
      ([ident].flatten.compact << DELIM << sign(msg)) + msg
    end

    def unserialize(msg_list)
      minlen = 5
      raise 'malformed message, must have at least #{minlen} elements' unless msg_list.length >= minlen
      s, header, parent_header, metadata, content, buffers = *msg_list
      raise 'Invalid signature' unless s == sign(msg_list[1..-1])
      {
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
