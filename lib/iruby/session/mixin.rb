module IRuby
  module SessionSerialize
    DELIM = '<IDS|MSG>'

    private

    def serialize(idents, header, content)
      msg = [MultiJson.dump(header),
             MultiJson.dump(@last_recvd_msg ? @last_recvd_msg[:header] : {}),
             '{}',
             MultiJson.dump(content || {})]
      frames = ([*idents].compact.map(&:to_s) << DELIM << sign(msg)) + msg
      IRuby.logger.debug "Sent #{frames.inspect}"
      frames
    end

    def unserialize(msg)
      raise 'no message received' unless msg
      frames = msg.to_a.map(&:to_s)
      IRuby.logger.debug "Received #{frames.inspect}"

      i = frames.index(DELIM)
      idents, msg_list = frames[0..i-1], frames[i+1..-1]

      minlen = 5
      raise "malformed message, must have at least #{minlen} elements" unless msg_list.length >= minlen
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
