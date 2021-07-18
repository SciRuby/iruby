require_relative "libzmq_finder"

module IRuby
  module ZMQ
    module LibZMQ
      # Socket types.
      ZMQ_PUB = 1
      ZMQ_DEALER = 5
      ZMQ_ROUTER = 6
      ZMQ_PULL = 7
      ZMQ_PUSH = 8
      ZMQ_STREAM = 11

      # Socket options.
      ZMQ_ROUTING_ID = 5
      ZMQ_FD = 14
      ZMQ_LINGER = 17
      ZMQ_LAST_ENDPOINT = 32

      # Send/recv options.
      ZMQ_DONTWAIT = 1
      ZMQ_SNDMORE = 2

      def self.load
        path = LibZMQFinder.find_libzmq
        if path
          @path = path
          import_library(@path)
          define_version_constant
          true
        else
          raise LoadError, "Unable to find libzmq"
        end
      end

      private_class_method def self.import_library(path)
        require "fiddle/import"
        extend Fiddle::Importer
        dlload @path

        extern "int zmq_errno(void)"
        extern "const char *zmq_strerror(int errnum_)"

        extern "void zmq_version(int *major_, int *minor_, int *patch_)"

        extern "void *zmq_ctx_new(void)"
        extern "int zmq_ctx_term(void *context_)"

        extern "void *zmq_socket(void *, int type_)"
        extern "int zmq_close(void *s_)"
        extern "int zmq_setsockopt(void *s_, int option_, const void *optval_, size_t *optvallen_)"
        extern "int zmq_getsockopt(void *s_, int option_, void *optval_, size_t *optvallen_)"
        extern "int zmq_bind(void *s_, const char *addr_)"
        extern "int zmq_connect(void *s_, const char *addr_)"
        extern "int zmq_send(void *s_, const void *buf_, size_t len_, int flags_)"
        extern "int zmq_recv(void *s_, const void *buf_, size_t len_, int flags_)"

        extern "int zmq_proxy(void *frontend_, void *backend_, void *capture_)"

        if windows?
          typealias "zmq_fd_t", "uintptr_t"  # zmq_fd_t = SOCKET = UINT_PTR
        else
          typealias "zmq_fd_t", "int"
        end

        begin
          extern "void *zmq_poller_new()"

          zmq_poller_event_t = struct([
            "void *socket",
            "zmq_fd_t fd",
            "void *user_data",
            "short events"
          ])
          const_set :ZMQ_PollerEvent, zmq_poller_event_t

          extern "int zmq_poller_destroy(void **poller_p)"
          extern "int zmq_poller_add(void *poller, void *socket, void *user_data, short events)"
          extern "int zmq_poller_remove(void *poller, void *socket)"
          extern "int zmq_poller_wait(void *poller, void *event, long timeout)"
          extern "int zmq_poller_wait_all(void *poller, void *events, int n_events, long timeout)"
        rescue Fiddle::DLError
          @poller_available = false
        else
          @poller_available = true
        end
      end

      private_class_method def self.define_version_constant
        major_p = value("int")
        minor_p = value("int")
        patch_p = value("int")
        zmq_version(major_p, minor_p, patch_p)
        const_set :Version, Module.new
        Version.const_set :MAJOR, major_p.value
        Version.const_set :MINOR, minor_p.value
        Version.const_set :PATCH, patch_p.value
        Version.const_set :STRING, [major_p, minor_p, patch_p].map(&:value).join(".")
        const_set :VERSION, Version::STRING
      end

      def self.poller_available?
        @poller_available
      end

      def self.windows?
        /mingw|mswin|msys/ =~ RUBY_PLATFORM
      end
    end
  end
end
