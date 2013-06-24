class Message
  # A simple message object that maps dict keys to attributes.

  # A Message can be created from a dict and a dict from a Message instance
  # simply by calling dict(msg_obj)."""

  def initialize msg_dict
    @dct = {}
    msg_dict.each_pair do |k, v|
      if v.is_a?(Hash)
        v = Message.new(v)
      end
      @dct[k] = v
    end
  end

  def method_missing(m, *args, &block)
    @dct[m.to_s]
  end

  def self.msg_header(msg_id, username, session)
    return {
      msg_id: msg_id,
      username: username,
      session: session
    }
  end

  def self.extract_header(msg_or_header)
    # Given a message or header, return the header.
    if msg_or_header.nil?
      return {}
    end
    # See if msg_or_header is the entire message.
    h = msg_or_header['header']
    # See if msg_or_header is just the header
    #h ||= msg_or_header['msg_id']
    h ||= msg_or_header

    return h
  end
end
