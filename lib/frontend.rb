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
#import session
#import completer

#-----------------------------------------------------------------------------
# Classes and functions
#-----------------------------------------------------------------------------

class Console#(code.InteractiveConsole)

  def initialize(locals=None, filename="<console>",
    session = session,
    request_socket=None,
    sub_socket=None)

    code.InteractiveConsole.new(locals, filename)
    @session = session
    @request_socket = request_socket
    @sub_socket = sub_socket
    @backgrounded = 0
    @messages = {}

    # Set tab completion
    @completer = completer.ClientCompleter(@session, request_socket)
    readline.parse_and_bind('tab: complete')
    readline.parse_and_bind('set show-all-if-ambiguous on')
    readline.set_completer(@completer.complete)

    # Set system prompts
    sys.ps1 = 'Py>>> '
    sys.ps2 = '  ... '
    sys.ps3 = 'Out : '
    # Build dict of handlers for message types
    @handlers = {}
    ['pyin', 'pyout', 'pyerr', 'stream'].each do |msg_type|
      @handlers[msg_type] = getattr('handle_%s' % msg_type)
    end
  end

    def handle_pyin(omsg)
      if omsg.parent_header.session == @session.session
        return
      end
      c = omsg.content.code.rstrip()
      if c
        print '[IN from %s]' % omsg.parent_header.username
        print c
      end
   end

  def handle_pyout(omsg)
    #print omsg # dbg
    if omsg.parent_header.session == @session.session
      print sys.ps3, omsg.content.data
    else
      print omsg.parent_header.username
      print omsg.content.data
    end
  end

  def print_pyerr(err)
    print >> sys.stderr#, err.etype,':', err.evalue
    print >> sys.stderr# + ''.join(err.traceback)       
  end

  def handle_pyerr(omsg)
    if omsg.parent_header.session == @session.session
      return
    end
    print >> sys.stderr + omsg.parent_header.username
    print_pyerr(omsg.content)
  end
      
  def handle_stream(omsg)
    if omsg.content.name == 'stdout'
      outstream = sys.stdout
    else
      outstream = sys.stderr
      print >> outstream
    end
    print >> outstream + omsg.content.data
  end

  def handle_output(omsg)
    handler = @handlers.get(omsg.msg_type, None)
    if handler != None
      handler(omsg)
    end
  end

  def recv_output
    while true
      omsg = @session.recv(@sub_socket)
      if omsg is None
        break
      end
      handle_output(omsg)
    end
  end

  def handle_reply(rep)
    # Handle any side effects on output channels
    recv_output
    # Now, dispatch on the possible reply types we must handle
    if rep is None
      return
    end
    if rep.content.status == 'error'
      print_pyerr(rep.content)            
    elsif rep.content.status == 'aborted'
      print >> sys.stderr << "ERROR: ABORTED"
      ab = @messages[rep.parent_header.msg_id].content
      #if 'code' in ab
      #  print >> sys.stderr, ab.code
      #else
      #  print >> sys.stderr, ab
      #end
    end
  end

  def recv_reply
    rep = @session.recv(@request_socket)
    handle_reply(rep)
    return rep
  end

  def runcode(code)
    # We can't pickle code objects, so fetch the actual source
    src = '\n'.join(self.buffer)

    # for non-background inputs, if we do have previoiusly backgrounded
    # jobs, check to see if they've produced results
    if not src.endswith(';')
      while @backgrounded > 0
        #print 'checking background'
        rep = recv_reply
        if rep
          @backgrounded -= 1
        end
        time.sleep(0.05)
      end
    end

    # Send code execution message to kernel
    omsg = @session.send(@request_socket, 'execute_request', dict(code=src))
    @messages[omsg.header.msg_id] = omsg
    
    # Fake asynchronicity by letting the user put ';' at the end of the line
    if src.endswith(';')
      @backgrounded += 1
      return
    end

    # For foreground jobs, wait for reply
    while true
      rep = recv_reply
      if rep != None
        break
      end
      recv_output
      time.sleep(0.05)
    #else
    #  # We exited without hearing back from the kernel!
    #  print >> sys.stderr, 'ERROR!!! kernel never got back to us!!!'
    end
  end
end

class InteractiveClient#(object)

  def initialize(session, request_socket, sub_socket)
    @session = session
    @request_socket = request_socket
    @sub_socket = sub_socket
    @console = Console.new(None, '<zmq-console>', @session, @request_socket, @sub_socket)
  end 

  def interact
    @console.interact
  end
end

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
  c = zmq.Context()
  request_socket = c.socket(zmq.XREQ)
  request_socket.connect(req_conn)
  
  sub_socket = c.socket(zmq.SUB)
  sub_socket.connect(sub_conn)
  sub_socket.setsockopt(zmq.SUBSCRIBE, '')

  # Make session and user-facing client
  sess = session.Session()
  client = InteractiveClient(sess, request_socket, sub_socket)
  client.interact()
end

if __FILE__ == $0
  main
end

