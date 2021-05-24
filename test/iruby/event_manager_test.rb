module IRubyTest
  class EventManagerTest < TestBase
    def setup
      @man = IRuby::EventManager.new([:foo, :bar])
    end

    def test_available_events
      assert_equal([:foo, :bar],
                   @man.available_events)
    end

    sub_test_case("#register") do
      sub_test_case("known event name") do
        def test_register
          fn = ->() {}
          assert_equal(fn,
                       @man.register(:foo, &fn))
        end
      end

      sub_test_case("unknown event name") do
        def test_register
          assert_raise_message("Unknown event name: baz") do
            @man.register(:baz) {}
          end
        end
      end
    end

    sub_test_case("#unregister") do
      sub_test_case("no event is registered") do
        def test_unregister
          fn = ->() {}
          assert_raise_message("Given callable object #{fn} is not registered as a foo callback") do
            @man.unregister(:foo, fn)
          end
        end
      end

      sub_test_case("the registered callable is given") do
        def test_unregister
          results = { values: [] }
          fn = ->(a) { values << a }

          @man.register(:foo, &fn)

          results[:retval] = @man.unregister(:foo, fn)

          @man.trigger(:foo, 42)

          assert_equal({
                         values: [],
                         retval: fn
                       },
                       results)
        end
      end
    end

    sub_test_case("#trigger") do
      sub_test_case("no event is registered") do
        def test_trigger
          assert_nothing_raised do
            @man.trigger(:foo)
          end
        end
      end

      sub_test_case("some events are registered") do
        def test_trigger
          values = []
          @man.register(:foo) {|a| values << a }
          @man.register(:foo) {|a| values << 10*a }
          @man.register(:foo) {|a| values << 100+a }

          @man.trigger(:foo, 5)

          assert_equal([5, 50, 105],
                       values)
        end
      end

      sub_test_case("unknown event name") do
        def test_trigger
          assert_raise_message("Unknown event name: baz") do
            @man.trigger(:baz, 100)
          end
        end
      end
    end
  end
end
