module TinyZmq
  class ZMQError < StandardError
    def self.strerror(errno = LibZMQ.errno)
      message = LibZMQ.zmq_strerror(errno)
      if message.null?
        new("Unknown Error")
      else
        new(message.to_s)
      end
    end
  end
end
