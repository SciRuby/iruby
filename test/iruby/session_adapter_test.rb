module IRubyTest
  class SessionAdapterTest < TestBase
    def test_available_p_return_false_when_load_error
      subclass = Class.new(IRuby::SessionAdapter::BaseAdapter)
      class << subclass
        def load_requirements
          raise LoadError
        end
      end
      refute subclass.available?
    end

    def test_select_adapter_class_with_cztop
      assert_rr do
        stub(IRuby::SessionAdapter::CztopAdapter).available? { true }
        stub(IRuby::SessionAdapter::FfirzmqAdapter).available? { false }

        cls = IRuby::SessionAdapter.select_adapter_class
        assert_equal IRuby::SessionAdapter::CztopAdapter, cls
      end
    end

    def test_select_adapter_class_with_ffirzmq
      assert_rr do
        stub(IRuby::SessionAdapter::FfirzmqAdapter).available? { true }
        stub(IRuby::SessionAdapter::CztopAdapter).available? { false }

        cls = IRuby::SessionAdapter.select_adapter_class
        assert_equal IRuby::SessionAdapter::FfirzmqAdapter, cls
      end
    end

    def test_select_adapter_class_with_env
      with_env('IRUBY_SESSION_ADAPTER' => 'cztop') do
        assert_rr do
          stub(IRuby::SessionAdapter::CztopAdapter).available? { true }
          assert_equal IRuby::SessionAdapter::CztopAdapter, IRuby::SessionAdapter.select_adapter_class
        end

        assert_rr do
          stub(IRuby::SessionAdapter::CztopAdapter).available? { false }
          assert_raises IRuby::SessionAdapterNotFound do
            IRuby::SessionAdapter.select_adapter_class
          end
        end
      end

      with_env('IRUBY_SESSION_ADAPTER' => 'ffi-rzmq') do
        assert_rr do
          stub(IRuby::SessionAdapter::FfirzmqAdapter).available? { true }
          assert_equal IRuby::SessionAdapter::FfirzmqAdapter, IRuby::SessionAdapter.select_adapter_class
        end

        assert_rr do
          stub(IRuby::SessionAdapter::FfirzmqAdapter).available? { false }
          assert_raises IRuby::SessionAdapterNotFound do
            IRuby::SessionAdapter.select_adapter_class
          end
        end
      end
    end
  end
end
