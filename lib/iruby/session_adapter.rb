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
      classes = {
        'rbczmq' => SessionAdapter::RbczmqAdapter,
        'cztop' => SessionAdapter::CztopAdapter,
        'ffi-rzmq' => SessionAdapter::FfirzmqAdapter,
        'pyzmq' => SessionAdapter::PyzmqAdapter
      }
      if (name = ENV.fetch('IRUBY_SESSION_ADAPTER', nil))
        cls = classes[name]
        unless cls.available?
          raise SessionAdapterNotFound,
                "Session adapter `#{name}` from IRUBY_SESSION_ADAPTER is unavailable"
        end
        return cls
      end
      classes.each_value do |cls|
        return cls if cls.available?
      end
      raise SessionAdapterNotFound, "No session adapter is available"
    end
  end
end
