module IRubyTest
  class KernelTest < TestBase
    def setup
      super
      with_session_adapter("test")
      @kernel = IRuby::Kernel.instance
    end

    sub_test_case("iruby_initialized event") do
      def setup
        super
        @initialized_kernel = nil
        @callback = IRuby::Kernel.events.register(:initialized) do |kernel|
          @initialized_kernel = kernel
        end
      end

      def teardown
        IRuby::Kernel.events.unregister(:initialized, @callback)
      end

      def test_iruby_initialized_event
        with_session_adapter("test")
        assert_same(IRuby::Kernel.instance, @initialized_kernel)
      end
    end

    def test_execute_request
      obj = Object.new

      class << obj
        def to_html
          "<b>HTML</b>"
        end

        def inspect
          "!!! inspect !!!"
        end
      end

      ::IRubyTest.define_singleton_method(:test_object) { obj }

      msg_types = []
      execute_reply = nil
      execute_result = nil
      @kernel.session.adapter.send_callback = ->(sock, msg) do
        header = msg[:header]
        content = msg[:content]
        msg_types << header["msg_type"]
        case header["msg_type"]
        when "execute_reply"
          execute_reply = content
        when "execute_result"
          execute_result = content
        end
      end

      msg = {
        content: {
          "code" => "IRubyTest.test_object",
          "silent" => false,
          "store_history" => false,
          "user_expressions" => {},
          "allow_stdin" => false,
          "stop_on_error" => true,
        }
      }
      @kernel.execute_request(msg)

      assert_equal({
                     msg_types: [ "execute_input", "execute_result", "execute_reply" ],
                     execute_reply: {
                       status: "ok",
                       user_expressions: {},
                     },
                     execute_result: {
                       data: {
                         "text/html" => "<b>HTML</b>",
                         "text/plain" => "!!! inspect !!!"
                       },
                       metadata: {},
                     }
                   },
                   {
                     msg_types: msg_types,
                     execute_reply: {
                       status: execute_reply["status"],
                       user_expressions: execute_reply["user_expressions"]
                     },
                     execute_result: {
                       data: execute_result["data"],
                       metadata: execute_result["metadata"]
                     }
                   })
    end

    def test_events_around_of_execute_request
      event_history = []

      @kernel.events.register(:pre_execute) do
        event_history << :pre_execute
      end

      @kernel.events.register(:pre_run_cell) do |exec_info|
        event_history << [:pre_run_cell, exec_info]
      end

      @kernel.events.register(:post_execute) do
        event_history << :post_execute
      end

      @kernel.events.register(:post_run_cell) do |result|
        event_history << [:post_run_cell, result]
      end

      msg = {
        content: {
          "code" => "true",
          "silent" => false,
          "store_history" => false,
          "user_expressions" => {},
          "allow_stdin" => false,
          "stop_on_error" => true,
        }
      }
      @kernel.execute_request(msg)

      msg = {
        content: {
          "code" => "true",
          "silent" => true,
          "store_history" => false,
          "user_expressions" => {},
          "allow_stdin" => false,
          "stop_on_error" => true,
        }
      }
      @kernel.execute_request(msg)

      assert_equal([
                     :pre_execute,
                     [:pre_run_cell, IRuby::ExecutionInfo.new("true", false, false)],
                     :post_execute,
                     [:post_run_cell, true],
                     :pre_execute,
                     :post_execute
                   ],
                   event_history)
    end

    sub_test_case("#switch_backend!") do
      sub_test_case("") do
        def test_switch_backend
          classes = []

          # First pick the default backend class
          classes << @kernel.instance_variable_get(:@backend).class

          @kernel.switch_backend!(:pry)
          classes << @kernel.instance_variable_get(:@backend).class

          @kernel.switch_backend!(:irb)
          classes << @kernel.instance_variable_get(:@backend).class

          @kernel.switch_backend!(:pry)
          classes << @kernel.instance_variable_get(:@backend).class

          @kernel.switch_backend!(:plain)
          classes << @kernel.instance_variable_get(:@backend).class

          assert_equal([
                         IRuby::PlainBackend,
                         IRuby::PryBackend,
                         IRuby::PlainBackend,
                         IRuby::PryBackend,
                         IRuby::PlainBackend
                       ],
                       classes)
        end
      end
    end
  end
end
