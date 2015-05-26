module IRuby
  # Comm is a new messaging system for bidirectional communication.
  # Both kernel and front-end listens for messages.
  class Comm
    attr_writer :on_msg, :on_close

    class << self
      def targets
        @targets ||= {}
      end
    end

    def initialize(target_name, comm_id = SecureRandom.uuid)
      @target_name, @comm_id = target_name, comm_id
    end

    def open(**data)
      Kernel.instance.session.send(:publish, 'comm_open', comm_id: @comm_id, data: data, target_name: @target_name)
      Kernel.instance.comms[@comm_id] = self
    end

    def send(**data)
      Kernel.instance.session.send(:publish, 'comm_msg', comm_id: @comm_id, data: data)
    end

    def close(**data)
      Kernel.instance.session.send(:publish, 'comm_close', comm_id: @comm_id, data: data)
      Kernel.instance.comms.delete(@comm_id)
    end

    def on_msg(&b)
      @on_msg = b
    end

    def on_close(&b)
      @on_close = b
    end

    def comm_msg(msg)
      @on_msg.call(msg) if @on_msg
    end

    def comm_close
      @on_close.call if @on_close
    end
  end
end
