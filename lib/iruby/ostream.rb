module IRuby
  # IO-like object that publishes to 0MQ socket.
  class OStream
    attr_accessor :sync

    def initialize(session, name)
      @session, @name = session, name
    end

    def close
      @session = nil
    end

    def flush
    end

    def isatty
      false
    end
    alias_method :tty?, :isatty

    def read(*args)
      raise IOError, 'not opened for reading'
    end
    alias_method :next, :read
    alias_method :readline, :read

    def write(*obj)
      str = build_string { |sio| sio.write(*obj) }
      session_send(str)
    end
    alias_method :<<, :write
    alias_method :print, :write

    def printf(format, *obj)
      str = build_string { |sio| sio.printf(format, *obj) }
      session_send(str)
    end

    def puts(*obj)
      str = build_string { |sio| sio.puts(*obj) }
      session_send(str)
    end

    def writelines(lines)
      lines.each { |s| write(s) }
    end

    # Called by irb
    def set_encoding(extern, intern)
      a = extern
    end

    private

    def build_string
      StringIO.open { |sio| yield(sio); sio.string }
    end

    def session_send(str)
      raise 'I/O operation on closed file' unless @session

      @session.send(:publish, :stream, name: @name, text: str)
      nil
    end
  end
end
