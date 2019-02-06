module IRuby
  class SessionAdapterNotFound < RuntimeError; end

  module SessionAdapter
    class BaseAdapter
      def self.available?
        load_requirements
        true
      rescue LoadError
        false
      end

      def initialize(config)
        @config = config
      end
    end

    require_relative 'session_adapter/rbczmq_adapter'
    require_relative 'session_adapter/cztop_adapter'
    require_relative 'session_adapter/ffirzmq_adapter'
    require_relative 'session_adapter/pyzmq_adapter'

    def self.select_adapter_class
      classes = [
        SessionAdapter::RbczmqAdapter,
        SessionAdapter::CztopAdapter,
        SessionAdapter::FfirzmqAdapter,
        SessionAdapter::PyzmqAdapter
      ]
      classes.each do |cls|
        return cls if cls.available?
      end
      raise SessionAdapterNotFound
    end
  end
end
