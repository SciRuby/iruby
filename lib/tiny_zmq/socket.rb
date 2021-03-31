module TinyZmq
  class Socket
    SOCKET_TYPES = {
      PUB: 1,
      REQ: 3,
      REP: 4,
      ROUTER: 6,
    }.freeze

    @__finalizer__ = lambda do |id|
      socket = ObjectSpace._id2ref(id)
      socket.close! rescue nil
    end

    def self.__finalizer__
      @__finalizer__
    end

    def initialize(type)
      @type = type
      @socket_ptr = __open__(context, socket_type_id(type))
      @poll_io = IO.for_fd(self.fd)
      ObjectSpace.define_finalizer(self, self.class.__finalizer__)
      context.register_socket(self)
    end

    def to_ptr
      @socket_ptr || Fiddle::NULL
    end

    attr_reader :type

    private def __open__(context, type_id)
      socket_ptr = LibZMQ.zmq_socket(context, type_id)
      raise ZMQError.strerror if socket_ptr.null?
      socket_ptr
    end

    def open?
      ! closed?
    end

    def closed?
      @socket_ptr.nil?
    end

    def close!
      return if closed?
      @poll_io.close
      rc = LibZMQ.zmq_close(self)
      @socket_ptr = nil
      raise ZMQError.strerror if rc != 0
    end

    def fd
      getsockopt(LibZMQ::ZMQ_FD)
    end

    private def socket_type_id(type)
      SOCKET_TYPES.fetch(type)
    rescue
      raise ArgumentError, "Unknown or unsupported socket type: #{type}"
    end

    def linger
      getsockopt(LibZMQ::ZMQ_LINGER)
    end

    def linger=(val)
      setsockopt(LibZMQ::ZMQ_LINGER, val)
    end

    private def getsockopt(opt)
      if opt == LibZMQ::ZMQ_FD && Fiddle::WINDOWS
        # Windows uses a pointer-sized unsigned integer to store the socket fd.
        size = Fiddle::SIZEOF_VOIDP
        fmt = size == 4 ? "L" : "Q"
      else
        size = Fiddle::SIZEOF_INT
        fmt = "i"
      end
      buf = Fiddle::Pointer.malloc(size)
      rc = LibZMQ.zmq_getsockopt(self, opt, buf, size)
      raise ZMQError.strerror if rc != 0
      buf.to_s(size).unpack(fmt)[0]
    end

    private def setsockopt(opt, val)
      size = Fiddle::SIZEOF_INT
      fmt = "i"
      packed = [val].pack(fmt)
      buf = Fiddle::Pointer[packed]
      rc = LibZMQ.zmq_setsockopt(self, opt, buf, size)
      raise ZMQError.strerror if rc != 0
      val
    end
  end
end
