#import os
#import uuid
#import pprint

require 'zmq'
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
    STDERR.puts "extracting header for:"
    STDERR.puts msg_or_header.inspect
    # Given a message or header, return the header.
    if msg_or_header.nil?
      return {}
    end
    # See if msg_or_header is the entire message.
    h = msg_or_header['header']
    # See if msg_or_header is just the header
    #h ||= msg_or_header['msg_id']
    h ||= msg_or_header

    STDERR.puts "extracted:"
    STDERR.puts h.inspect
    return h
  end
end

class Session
  def initialize username='jadams'
    @username = username
    @session = UUID.new.generate
    @msg_id = 0
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
    msg['header']['msg_type'] = msg_type
    msg['content'] = content || {}
    return msg
  end

  def send(socket, msg_type, content=nil, parent=nil, ident=nil)
    msg = self.msg(msg_type, content, parent)
    if ident
      socket.send(ident, ZMQ::SNDMORE)
    end
    socket.send(msg.to_json)
    omsg = msg
    return omsg
  end

  def recv(socket, mode=ZMQ::NOBLOCK)
    begin
      msg = socket.recv(mode)
      msg = JSON.parse(msg) unless msg.nil?
    rescue Exception => e
      if e.errno == ZMQ::EAGAIN
        # We can convert EAGAIN to None as we know in this case
        # recv_json won't return None.
        return nil
      else
        raise
      end
    end
    return nil if msg.nil?
    return msg
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
