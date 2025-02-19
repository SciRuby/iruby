module IRuby
  # Comm is a new messaging system for bidirectional communication.
  # Both kernel and front-end listens for messages.
  class Comm
    attr_writer :on_msg, :on_close

    class << self
      def target; @target ||= {} end
      def comm;   @comm   ||= {} end
    end

    def initialize(target_name, comm_id = SecureRandom.uuid)
      @target_name, @comm_id = target_name, comm_id
    end

    def open(metadata = nil, **data)
      Kernel.instance.session.send(:publish, :comm_open, metadata, comm_id: @comm_id, data: data, target_name: @target_name)
      Comm.comm[@comm_id] = self
    end

    def send(metadata = nil, **data)
      Kernel.instance.session.send(:publish, :comm_msg, metadata, comm_id: @comm_id, data: data)
    end

    def close(metadata = nil, **data)
      Kernel.instance.session.send(:publish, :comm_close, metadata, comm_id: @comm_id, data: data)
      Comm.comm.delete(@comm_id)
    end

    def on_msg(&b)
      @on_msg = b
    end

    def on_close(&b)
      @on_close = b
    end

    def handle_msg(data)
      @on_msg.call(data) if @on_msg
    end

    def handle_close(data)
      @on_close.call(data) if @on_close
    end
  end
end
