module IRuby
  class EventManager
    def initialize(available_events)
      @available_events = available_events.dup.freeze
      @callbacks = available_events.map {|n| [n, []] }.to_h
    end

    attr_reader :available_events

    def register(event, &block)
      check_available_event(event)
      @callbacks[event] << block unless block.nil?
      block
    end

    def unregister(event, callback)
      check_available_event(event)
      val = @callbacks[event].delete(callback)
      unless val
        raise ArgumentError,
              "Given callable object #{callback} is not registered as a #{event} callback"
      end
      val
    end

    def trigger(event, *args, **kwargs)
      check_available_event(event)
      @callbacks[event].each do |fn|
        fn.call(*args, **kwargs)
      end
    end

    private

    def check_available_event(event)
      return if @callbacks.key?(event)
      raise ArgumentError, "Unknown event name: #{event}", caller
    end
  end
end
