module IRuby
  # Base class for Widgets. Inheritance this class to define your own custom widgets.
  # @@view_name: The view name defined on the front-end.
  # @@target_name: THe target to which kernel send comm messages. Default target is "WidgetModel", but you can define your own target on the front-end.
  #
  class Widget
    @@view_name = ""
    @@description = ""
    @@target_name = "WidgetModel"

    def initialize
      @model_id = SecureRandom.hex(16).upcase
      @sync_data = {}
      @comm = Comm.new(@@target_name, @model_id)
      Kernel.instance.register_comm(@model_id, @comm)
      @comm.on_msg(method(:handle_msg))
      @comm.open

      content = {
        method: "update",
        state: {
          _view_name: @@view_name,
          description: @@description,
          visible: true,
          _css: {},
          msg_throttle: 3,
          disabled: false
        }
      }

      @comm.send(content)
    end

    # send *custom* message to front-end
    def send(content)
      @comm.send({method: "custom", content: content})
    end

    def on_msg(callback)
      @msg_callback = callback
    end

    def to_iruby
      @comm.send({method: "display"})
    end

    # Called when the front-end send comm message to the kernel.
    # An example of msg: {"method" => "", "content"=> ""}
    def handle_msg(msg)
      if msg["method"] == "custom"
        @msg_callback.call(msg["content"])
      elsif msg["method"] == "backbone"
        data = msg["content"]["data"]

        if data.has_key? "sync_data"
          sync_data = data["sync_data"].reduce({}) do |memo, (key, val)|
            memo[key.to_sym] = val
          end
          @sync_data.merge!(sync_data)
        end
      else
        STDERR.puts("Unknown method type #{msg["method"]}.")
      end
    end
  end
end
