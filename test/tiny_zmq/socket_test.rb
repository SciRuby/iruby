class TinyZmqSocketTest < Test::Unit::TestCase
  def setup
    require "tiny_zmq"
  end

  test("#close") do
    socket = TinyZmq::Socket.new(:PUB)
    socket.close
    assert do
      socket.closed?
    end
  end

  test("#type") do
    pub = TinyZmq::Socket.new(:PUB)
    rep = TinyZmq::Socket.new(:REP)
    req = TinyZmq::Socket.new(:REQ)
    assert_equal([:PUB     , :REP     , :REQ     ],
                 [pub.type , rep.type , req.type ])
  end

  test("#bind and #connect") do
    s1 = TinyZmq::Socket.new(:REP)
    s2 = TinyZmq::Socket.new(:REQ)
    assert_nothing_raised do
      s2.bind("tcp://*:5555")
      s1.connect("tcp://localhost:5555")
    end
  end

  sub_test_case("send and recv") do
    def setup
      super

      @s1 = TinyZmq::Socket.new(:REP)
      @s2 = TinyZmq::Socket.new(:REQ)
      @s2.bind("tcp://*:5555")
      @s1.connect("tcp://localhost:5555")
    end

    test("a String") do
      assert_nothing_raised do
        @s2.send("test message")
        res = @s1.recv
        assert_equal("test message", res)
      end
    end
  end
end
