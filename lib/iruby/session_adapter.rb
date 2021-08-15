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

      def self.load_requirements
        # Do nothing
      end

      def initialize(config)
        @config = config
      end

      def name
        self.class.name[/::(\w+)Adapter\Z/, 1].downcase
      end

      def make_router_socket(protocol, host, port)
        socket, port = make_socket(:ROUTER, protocol, host, port)
        [socket, port]
      end

      def make_pub_socket(protocol, host, port)
        socket, port = make_socket(:PUB, protocol, host, port)
        [socket, port]
      end

      def make_rep_socket(protocol, host, port)
        socket, port = make_socket(:REP, protocol, host, port)
        [socket, port]
      end
    end

    require_relative 'session_adapter/ffirzmq_adapter'
    require_relative 'session_adapter/cztop_adapter'
    require_relative 'session_adapter/test_adapter'

    def self.select_adapter_class(name=nil)
      classes = {
        'ffi-rzmq' => SessionAdapter::FfirzmqAdapter,
        'cztop' => SessionAdapter::CztopAdapter,
        'test' => SessionAdapter::TestAdapter,
      }
      if (name ||= ENV.fetch('IRUBY_SESSION_ADAPTER', nil))
        cls = classes[name]
        unless cls.available?
          if ENV['IRUBY_SESSION_ADAPTER']
            raise SessionAdapterNotFound,
                  "Session adapter `#{name}` from IRUBY_SESSION_ADAPTER is unavailable"
          else
            raise SessionAdapterNotFound,
                  "Session adapter `#{name}` is unavailable"
          end
        end
        if name == 'cztop'
          warn "WARNING: cztop was deprecated and will be removed; Use ffi-rzmq, instead."
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
