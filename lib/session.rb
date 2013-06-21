#import os
#import uuid
#import pprint

require 'ffi-rzmq'
require 'uuid'
require 'json'

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

class Session
  DELIM = "<IDS|MSG>"

  def initialize username='jadams'
    @username = username
    @session = UUID.new.generate
    @msg_id = 0

    @auth = nil
  end

  def pack(s)
    s.to_json
  end

  def sign(msg_list)
    """Sign a message with HMAC digest. If no auth, return b''.

    Parameters
    ----------
    msg_list : list
        The [p_header,p_parent,p_content] part of the message list.
    """
    if @auth.nil?
      return ''
    end
    #h = self.auth.copy()
    #msg_list.each do |m|
      #h.update(m)
    #end
    #return str_to_bytes(h.hexdigest())
  end

  def msg_header
    h = Message.msg_header(@msg_id, @username, @session)
    @msg_id += 1
    return h
  end

  def msg(msg_type, content=nil, parent=nil)
    msg = {}
    msg['header'] = msg_header()
    msg['parent_header'] = parent.nil? ? {} : Message.extract_header(parent)
    msg['metadata'] = {}
    msg['header']['msg_type'] = msg_type
    msg['content'] = content || {}
    return msg
  end

  def send(stream, msg_or_type, content=nil, parent=nil, ident=nil, buffers=nil, subheader=nil, track=false, header=nil)
    """Build and send a message via stream or socket.

    The message format used by this function internally is as follows:

    [ident1,ident2,...,DELIM,HMAC,p_header,p_parent,p_content,
     buffer1,buffer2,...]

    The serialize/unserialize methods convert the nested message dict into this
    format.

    Parameters
    ----------

    stream : zmq.Socket or ZMQStream
        The socket-like object used to send the data.
    msg_or_type : str or Message/dict
        Normally, msg_or_type will be a msg_type unless a message is being
        sent more than once. If a header is supplied, this can be set to
        None and the msg_type will be pulled from the header.

    content : dict or None
        The content of the message (ignored if msg_or_type is a message).
    header : dict or None
        The header dict for the message (ignores if msg_to_type is a message).
    parent : Message or dict or None
        The parent or parent header describing the parent of this message
        (ignored if msg_or_type is a message).
    ident : bytes or list of bytes
        The zmq.IDENTITY routing path.
    subheader : dict or None
        Extra header keys for this message's header (ignored if msg_or_type
        is a message).
    buffers : list or None
        The already-serialized buffers to be appended to the message.
    track : bool
        Whether to track.  Only for use with Sockets, because ZMQStream
        objects cannot track messages.

    Returns
    -------
    msg : dict
        The constructed message.
    (msg,tracker) : (dict, MessageTracker)
        if track=True, then a 2-tuple will be returned,
        the first element being the constructed
        message, and the second being the MessageTracker

    """

    if !stream.is_a?(ZMQ::Socket)
      raise "stream must be Socket or ZMQSocket, not %r"%stream.class
    end

    if msg_or_type.is_a?(Hash)
      msg = msg_or_type
    else
      msg = self.msg(msg_or_type, content, parent)
    end

    buffers ||= []
    to_send = self.serialize(msg, ident)
    flag = 0
    if buffers.any?
      flag = ZMQ::SNDMORE
      _track = false
    else
      _track=track
    end
    if track
      to_send.each_with_index do |part, i|
        if i == to_send.length - 1
          flag = 0
        else
          flag = ZMQ::SNDMORE
        end
        stream.send_string(part, flag)
      end
    else
      to_send.each_with_index do |part, i|
        if i == to_send.length - 1
          flag = 0
        else
          flag = ZMQ::SNDMORE
        end
        stream.send_string(part, flag)
      end
    end
    # STDOUT.puts '-'*30
    # STDOUT.puts "SENDING"
    # STDOUT.puts to_send
    # STDOUT.puts to_send.length
    # STDOUT.puts '-'*30
    
    #buffers.each do |b|
      #stream.send(b, flag, copy=False)
    #end
    #if buffers:
        #if track:
            #tracker = stream.send(buffers[-1], copy=False, track=track)
        #else:
            #tracker = stream.send(buffers[-1], copy=False)

    # omsg = Message(msg)
    #if self.debug:
        #pprint.pprint(msg)
        #pprint.pprint(to_send)
        #pprint.pprint(buffers)

    #msg['tracker'] = tracker

    return msg
  end

  def recv(socket, mode=ZMQ::NOBLOCK)
    begin
      msg = []
      frame = ""
      rc = socket.recv_string(frame, mode)
      ZMQ::Util.error_check("zmq_msg_send", rc)
      
      msg << frame
      while socket.more_parts?
        begin
          frame = ""
          rc = socket.recv_string(frame, mode)
          ZMQ::Util.error_check("zmq_msg_send", rc)
          msg << frame
        rescue
        end
      end
      # Skip everything before DELIM, then munge the three json objects into the
      # one the rest of my code expects
      i = msg.index(DELIM)
      idents = msg[0..i-1]
      msg_list = msg[i+1..-1]
    end
    return idents, unserialize(msg_list)
  end

  def serialize(msg, ident=nil)
    """Serialize the message components to bytes.

    This is roughly the inverse of unserialize. The serialize/unserialize
    methods work with full message lists, whereas pack/unpack work with
    the individual message parts in the message list.

    Parameters
    ----------
    msg : dict or Message
        The nexted message dict as returned by the self.msg method.

    Returns
    -------
    msg_list : list
        The list of bytes objects to be sent with the format:
        [ident1,ident2,...,DELIM,HMAC,p_header,p_parent,p_content,
         buffer1,buffer2,...]. In this list, the p_* entities are
        the packed or serialized versions, so if JSON is used, these
        are utf8 encoded JSON strings.
    """
    content = msg.fetch('content', {})
    if content.nil?
      content = {}.to_json
    elsif content.is_a?(Hash)
      content = content.to_json
    #elsif isinstance(content, bytes):
        # content is already packed, as in a relayed message
        #pass
    #elsif isinstance(content, unicode):
        # should be bytes, but JSON often spits out unicode
        #content = content.encode('utf8')
    else
      raise "Content incorrect type: %s"%type(content)
    end

    real_message = [self.pack(msg['header']),
                    self.pack(msg['parent_header']),
                    self.pack(msg['metadata']),
                    self.pack(msg['content']),
                  ]

    to_send = []

    if ident.is_a?(Array)
      # accept list of idents
      to_send += ident
    elsif !ident.nil?
      to_send << ident
    end
    to_send << DELIM

    signature = self.sign(real_message)
    to_send << signature

    to_send += real_message
    # STDOUT.puts to_send
    # STDOUT.puts to_send.length

    return to_send
  end

  def unserialize(msg_list, content=true, copy=true)
=begin
        Unserialize a msg_list to a nested message dict.
        This is roughly the inverse of serialize. The serialize/unserialize
        methods work with full message lists, whereas pack/unpack work with
        the individual message parts in the message list.

        Parameters:
        -----------
        msg_list : list of bytes or Message objects
            The list of message parts of the form [HMAC,p_header,p_parent,
            p_content,buffer1,buffer2,...].
        content : bool (True)
            Whether to unpack the content dict (True), or leave it packed
            (False).
        copy : bool (True)
            Whether to return the bytes (True), or the non-copying Message
            object in each place (False).

        Returns
        -------
        msg : dict
            The nested message dict with top-level keys [header, parent_header,
            content, buffers].
=end
    minlen = 5
    message = {}
    unless copy
      minlen.times do |i|
        msg_list[i] = msg_list[i].bytes
      end
    end
    unless msg_list.length >= minlen
      raise Exception "malformed message, must have at least %i elements"%minlen
    end
    # STDERR.puts msg_list.inspect
    header = msg_list[1]
    message['header'] = JSON.parse(header)
    message['msg_id'] = header['msg_id']
    message['msg_type'] = header['msg_type']
    message['parent_header'] = JSON.parse(msg_list[2])
    message['metadata'] = JSON.parse(msg_list[3])
    if content
      message['content'] = JSON.parse(msg_list[4])
    else
      message['content'] = msg_list[4]
    end

    message['buffers'] = msg_list[4..-1]
    return message
  end
end

=begin
def test_msg2obj():
    am = dict(x=1)
    ao = Message(am)
    assert ao.x == am['x']

    am['y'] = dict(z=1)
    ao = Message(am)
    assert ao.y.z == am['y']['z']
    
    k1, k2 = 'y', 'z'
    assert ao[k1][k2] == am[k1][k2]
    
    am2 = dict(ao)
    assert am['x'] == am2['x']
    assert am['y']['z'] == am2['y']['z']
=end
