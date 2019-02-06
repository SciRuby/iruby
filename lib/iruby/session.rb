require 'iruby/session_adapter'

module IRuby
  class Session
    def initialize(config)
      @config = config
      @adapter = create_session_adapter(config)
    end

    attr_reader :adapter

    private

    def create_session_adapter(config)
      adapter_class = SessionAdapter.select_adapter_class
      adapter_class.new(config)
    end
  end
end
