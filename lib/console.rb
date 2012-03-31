class Console#(code.InteractiveConsole)
  def initialize(locals=nil, filename="<console>", session = session, request_socket=nil, sub_socket=nil)
    #code.InteractiveConsole.new(locals, filename)
    @session = session
    @request_socket = request_socket
    @sub_socket = sub_socket
    @backgrounded = 0
    @messages = {}

    # Set tab completion
    #@completer = completer.ClientCompleter(@session, request_socket)
    #readline.parse_and_bind('tab: complete')
    #readline.parse_and_bind('set show-all-if-ambiguous on')
    #readline.set_completer(@completer.complete)

    # Set system prompts
    #sys.ps1 = 'Ru>>> '
    #sys.ps2 = '  ... '
    #sys.ps3 = 'Out : '
    # Build dict of handlers for message types
    @handlers = {}
    ['pyin', 'pyout', 'pyerr', 'stream'].each do |msg_type|
      @handlers[msg_type] = "handle_#{msg_type}"
    end
  end

  def interact
    repl = -> prompt { print prompt; puts(" => %s" % runcode(gets.chomp!)) }
    loop { repl[">> "] }
  end

  def handle_pyin(omsg)
    if omsg.parent_header.session == @session
      return
    end
    c = omsg.content.code.rstrip()
    if c
      #print '[IN from %s]' % omsg.parent_header.username
      #print c
    end
 end

  def handle_pyout(omsg)
    #print omsg # dbg
    if omsg.parent_header.session == @session
      print sys.ps3, omsg.content.data
    else
      print omsg.parent_header.username
      print omsg.content.data
    end
  end

  def print_pyerr(err)
    STDERR.puts "#{err.etype}:#{err.evalue}"
    STDERR.puts err.traceback
  end

  def handle_pyerr(omsg)
    if omsg.parent_header.session == @session
      return
    end
    STDERR.puts omsg.parent_header.username
    print_pyerr(omsg.content)
  end

  def handle_stream(omsg)
    if omsg.content.name == 'stdout'
      outstream = STDOUT
    else
      outstream = STDERR
      #print >> outstream
    end
    outstream.puts omsg.content.data
  end

  def handle_output(omsg)
    handler = @handlers[omsg.msg_type]
    if handler != nil
      send(handler, omsg)
    end
  end

  def recv_output
    while true
      omsg = @session.recv(@sub_socket)
      if omsg.nil?
        break
      end
      handle_output(omsg)
    end
  end

  def handle_reply(rep)
    # Handle any side effects on output channels
    recv_output
    # Now, dispatch on the possible reply types we must handle
    if rep.nil?
      return
    end
    if rep.content.status == 'error'
      print_pyerr(rep.content)
    elsif rep.content.status == 'aborted'
      STDERR.puts "ERROR: ABORTED"
      ab = @messages[rep.parent_header.msg_id].content
      if ab.code
        STDERR.puts ab.code
      else
        STDERR.puts ab
      end
    end
  end

  def recv_reply
    rep = @session.recv(@request_socket)
    handle_reply(rep)
    return rep
  end

  def runcode(code)
    # We can't pickle code objects, so fetch the actual source
    #src = '\n'.join(self.buffer)
    src = code

    # for non-background inputs, if we do have previoiusly backgrounded
    # jobs, check to see if they've produced results
    if not src[-1..-1] == ';'
      while @backgrounded > 0
        #print 'checking background'
        rep = recv_reply
        if rep
          @backgrounded -= 1
        end
        sleep(0.05)
      end
    end

    # Send code execution message to kernel
    omsg = @session.send(@request_socket, 'execute_request', {code:src})
    #@messages[omsg.header.msg_id] = omsg

    # Fake asynchronicity by letting the user put ';' at the end of the line
    if src[-1..-1] == ';'
      @backgrounded += 1
      return
    end

    # For foreground jobs, wait for reply
    while true
      rep = recv_reply
      if rep != nil
        break
      end
      recv_output
      sleep(0.05)
    #else
    #  # We exited without hearing back from the kernel!
    #  print >> sys.stderr, 'ERROR!!! kernel never got back to us!!!'
    end
  end
end
