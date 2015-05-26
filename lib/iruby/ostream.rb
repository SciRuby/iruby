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

    def write(s)
      raise 'I/O operation on closed file' unless @session
      @session.send(:publish, stream, name: @name, text: s.to_s)
      nil
    end
    alias_method :<<, :write
    alias_method :print, :write

    def puts(*lines)
      lines = [''] if lines.empty?
      lines.each { |s| write("#{s}\n")}
      nil
    end

    def writelines(lines)
      lines.each { |s| write(s) }
    end
  end
end
