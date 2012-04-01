class OutStream
  #A file like object that publishes the stream to a 0MQ PUB socket.

  def initialize session, pub_socket, name, max_buffer=200
    @session = session
    @pub_socket = pub_socket
    @name = name
    @_buffer = []
    @_buffer_len = 0
    @max_buffer = max_buffer
    @parent_header = {}
  end

  def set_parent parent
    header = Message.extract_header(parent)
    @parent_header = header
  end

  def close
    @pub_socket = nil
  end

  def flush
    STDERR.puts("flushing, parent to follow")
    STDERR.puts @parent_header.inspect
    if @pub_socket.nil?
      raise 'I/O operation on closed file'
    else
      if @_buffer
        data = @_buffer.join('')
        content = { name: @name, data: data }
        msg = @session.msg('stream', content, @parent_header) if @session
        # FIXME: Wha?
        STDERR.puts msg.to_json
        #@pub_socket.send(msg.to_json)
        @session.send(@pub_socket, msg)
        @_buffer_len = 0
        @_buffer = []
      end
    end
  end

  def isattr
    return false
  end

  def next
    raise 'Read not supported on a write only stream.'
  end

  def read size=0
    raise 'Read not supported on a write only stream.'
  end
  alias readline read

  def write s
    if @pub_socket.nil?
      raise 'I/O operation on closed file'
    else
      @_buffer << s
      @_buffer_len += s.length
      _maybe_send
    end
  end

  def puts str
    write str
  end

  def _maybe_send
    #if self._buffer[-1].include?('\n')
      flush
    #end
    #if @_buffer_len > @max_buffer
      #flush
    #end
  end

  def writelines sequence
    if @pub_socket.nil?
      raise 'I/O operation on closed file'
    else
      sequence.each do |s|
        write(s)
      end
    end
  end
end

