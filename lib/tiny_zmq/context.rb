module TinyZmq
  # Return the default ZMQ context
  def self.context
    @context ||= __init_context__
  end

  private_class_method def self.__init_context__
    ctx_ptr = LibZMQ.zmq_ctx_new
    raise ZMQError.strerror if ctx_ptr.null?

    ctx = Object.new
    ctx.instance_variable_set(:@ctx_ptr, ctx_ptr)
    ctx.instance_variable_set(:@sockets, [])

    class << ctx
      def to_ptr
        @ctx_ptr || Fiddle::NULL
      end

      def register_socket(socket)
        @sockets << WeakRef.new(socket)
      end

      def closed?
        @ctx_ptr.nil?
      end

      def close!
        return if closed?
        @sockets.each do |socket|
          if socket.alive? && socket.open?
            socket.linger = 0 # allow socket to shut down immediately
            socket.close!
          end
        end
        rc = LibZMQ.zmq_ctx_destroy(@ctx_ptr)
        @ctx_ptr = nil
        raise ZMQError.strerror if rc != 0
      end
    end

    ObjectSpace.define_finalizer(ctx, __context_finalizer__)
    ctx
  end

  private_class_method def self.__context_finalizer__
    lambda do |id|
      ctx = ObjectSpace._id2ref(id)
      ctx.close! rescue nil
    end
  end
end
