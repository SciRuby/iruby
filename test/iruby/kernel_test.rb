require "base64"

module IRubyTest
  class KernelTest < TestBase
    def setup
      super
      with_session_adapter("test")
      @kernel = IRuby::Kernel.instance
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
                     msg_types: [ "execute_input", "execute_reply", "execute_result" ],
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
  end
end
