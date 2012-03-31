# A simple interactive frontend that talks to a kernel over 0MQ.

#-----------------------------------------------------------------------------
# Imports
#-----------------------------------------------------------------------------
# stdlib
#import cPickle as pickle
#import code
#import readline
#import sys
#import time
#import uuid

# our own
require 'zmq'
require 'irb'
require File.expand_path('../session', __FILE__)
require File.expand_path('../console', __FILE__)
require File.expand_path('../interactive_client', __FILE__)
#import completer

#-----------------------------------------------------------------------------
# Classes and functions
#-----------------------------------------------------------------------------
def main
  # Defaults
  #ip = '192.168.2.109'
  ip = '127.0.0.1'
  #ip = '99.146.222.252'
  port_base = 5555
  connection = ('tcp://%s' % ip) + ':%i'
  req_conn = connection % port_base
  sub_conn = connection % (port_base+1)

  # Create initial sockets
  c = ZMQ::Context.new
  request_socket = c.socket(ZMQ::XREQ)
  request_socket.connect(req_conn)

  sub_socket = c.socket(ZMQ::SUB)
  sub_socket.connect(sub_conn)
  sub_socket.setsockopt(ZMQ::SUBSCRIBE, '')

  # Make session and user-facing client
  sess = Session.new
  client = InteractiveClient.new(sess, request_socket, sub_socket)
  client.interact()
end

if __FILE__ == $0
  main
end

