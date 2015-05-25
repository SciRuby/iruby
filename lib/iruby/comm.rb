module IRuby

  # Comm is a new messaging system for bidirectional communication.
  # Both kernel and front-end listens for messages.
  class Comm
    def initialize(target_name, comm_id = SecureRandom.hex(16))
      @comm_id = comm_id
      @target_name = target_name
      @session = Kernel.instance.session
      @pub_socket = Kernel.instance.pub_socket
    end

    # Ask front-end to open comm channel.
    # Primary side should specify comm_id and target_name.
    def open(data = {})
      content = {
        comm_id: @comm_id,
        data: data,
        target_name: @target_name
      }
      @session.send(@pub_socket, 'comm_open', content)
    end

    def send(data = {})
      content = {
        comm_id: @comm_id,
        data: data
      }
      @session.send(@pub_socket, 'comm_msg', content)
    end

    def close(data = {})
      content = {
        comm_id: @comm_id,
        data: data
      }
      @session.send(@pub_socket, 'comm_close', content)
    end

    def on_open(callback)
      @open_callback = callback
    end

    def on_msg(callback)
      @msg_callback = callback
    end

    def on_close(callback)
      @close_callback = callback
    end

    def handle_msg(msg)
      @msg_callback.call(msg) unless @msg_callback
    end

    def handle_close(msg)
      @close_callback.call(msg) unless @close_callback
    end
  end
end
