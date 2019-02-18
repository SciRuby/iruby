require_relative 'session_adapter_test_base'
require 'iruby'

module IRubyTest
  class RbczmqAdapterTest < SessionAdapterTestBase
    def adapter_class
      IRuby::SessionAdapter::RbczmqAdapter
    end

    def test_send
      dummy_message = MiniTest::Mock.new.expect(:called!, true)

      dummy_socket = MiniTest::Mock.new.expect(:send_message, nil, [dummy_message])

      ZMQ.stub(:Message, ->(message) { message.called!; message }) do
        @session_adapter.send(dummy_socket, dummy_message)
      end

      assert(dummy_message.verify)
      assert(dummy_socket.verify)
    end

    def test_recv
      dummy_message = MiniTest::Mock.new
      dummy_message.expect(:equal?, true, [dummy_message])

      dummy_socket = MiniTest::Mock.new.expect(:recv_message, dummy_message)

      assert_same(dummy_message, @session_adapter.recv(dummy_socket))

      assert(dummy_message.verify)
      assert(dummy_socket.verify)
    end
  end
end
