module IRuby
  # IO-like object that publishes to 0MQ socket.
  class OStream
    def initialize(session, socket, name)
      @session = session
      @socket = socket
      @name = name
    end

    def close
      @socket = nil
    end

    def flush
    end

    def isatty
      false
    end
    alias tty? isatty

    def read(*args)
      raise IOError, 'not opened for reading'
    end
    alias next read
    alias readline read

    def write(s)
      raise 'I/O operation on closed file' unless @socket
      @session.send(@socket, 'stream', { name: @name, data: s.to_s })
      nil
    end

    def puts(s)
      write "#{s}\n"
    end

    def writelines(lines)
      lines.each { |s| write(s) }
    end
  end
end
