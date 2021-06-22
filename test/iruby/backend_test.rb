module IRubyTest
  class PlainBackendTest < IRubyTest::TestBase
    def setup
      @plainbackend = IRuby::PlainBackend.new
    end

    def test_eval_one_plus_two
      assert_equal 3, @plainbackend.eval('1+2', false)
    end

    def test_include_module
      assert_nothing_raised do
        @plainbackend.eval("include Math, Comparable", false)
      end
    end

    def test_complete_req
      assert_includes @plainbackend.complete('req'), 'require'
    end

    def test_complete_2_dot
      assert_includes @plainbackend.complete('2.'), '2.even?'
    end
  end

  class PryBackendTest < IRubyTest::TestBase
    def setup
      @prybackend = IRuby::PryBackend.new
    end

    def test_eval_one_plus_two
      assert_equal 3, @prybackend.eval('1+2', false)
    end

    def test_include_module
      assert_nothing_raised do
        @prybackend.eval("include Math, Comparable", false)
      end
    end

    def test_complete_req
      assert_includes @prybackend.complete('req'), 'require'
    end

    def test_complete_2_dot
      assert_includes @prybackend.complete('2.'), '2.even?'
    end
  end
end
