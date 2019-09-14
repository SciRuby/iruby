require 'test_helper'

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

    def test_select_adapter_class_with_rbczmq
      IRuby::SessionAdapter::RbczmqAdapter.stub :available?, true do
        IRuby::SessionAdapter::CztopAdapter.stub :available?, false do
          IRuby::SessionAdapter::FfirzmqAdapter.stub :available?, false do
            IRuby::SessionAdapter::PyzmqAdapter.stub :available?, false do
              cls = IRuby::SessionAdapter.select_adapter_class
              assert_equal IRuby::SessionAdapter::RbczmqAdapter, cls
            end
          end
        end
      end
    end

    def test_select_adapter_class_with_cztop
      IRuby::SessionAdapter::CztopAdapter.stub :available?, true do
        IRuby::SessionAdapter::RbczmqAdapter.stub :available?, false do
          IRuby::SessionAdapter::FfirzmqAdapter.stub :available?, false do
            IRuby::SessionAdapter::PyzmqAdapter.stub :available?, false do
              cls = IRuby::SessionAdapter.select_adapter_class
              assert_equal IRuby::SessionAdapter::CztopAdapter, cls
            end
          end
        end
      end
    end

    def test_select_adapter_class_with_ffirzmq
      IRuby::SessionAdapter::FfirzmqAdapter.stub :available?, true do
        IRuby::SessionAdapter::RbczmqAdapter.stub :available?, false do
          IRuby::SessionAdapter::CztopAdapter.stub :available?, false do
            IRuby::SessionAdapter::PyzmqAdapter.stub :available?, false do
              cls = IRuby::SessionAdapter.select_adapter_class
              assert_equal IRuby::SessionAdapter::FfirzmqAdapter, cls
            end
          end
        end
      end
    end

    def test_select_adapter_class_with_pyzmq
      skip "pyzmq adapter is disabled"
      IRuby::SessionAdapter::PyzmqAdapter.stub :available?, true do
        IRuby::SessionAdapter::RbczmqAdapter.stub :available?, false do
          IRuby::SessionAdapter::CztopAdapter.stub :available?, false do
            IRuby::SessionAdapter::FfirzmqAdapter.stub :available?, false do
              cls = IRuby::SessionAdapter.select_adapter_class
              assert_equal IRuby::SessionAdapter::PyzmqAdapter, cls
            end
          end
        end
      end
    end

    def test_select_adapter_class_with_env
      with_env('IRUBY_SESSION_ADAPTER' => 'rbczmq') do
        IRuby::SessionAdapter::RbczmqAdapter.stub :available?, true do
          assert_equal IRuby::SessionAdapter::RbczmqAdapter, IRuby::SessionAdapter.select_adapter_class
        end

        IRuby::SessionAdapter::RbczmqAdapter.stub :available?, false do
          assert_raises IRuby::SessionAdapterNotFound do
            IRuby::SessionAdapter.select_adapter_class
          end
        end
      end

      with_env('IRUBY_SESSION_ADAPTER' => 'cztop') do
        IRuby::SessionAdapter::CztopAdapter.stub :available?, true do
          assert_equal IRuby::SessionAdapter::CztopAdapter, IRuby::SessionAdapter.select_adapter_class
        end

        IRuby::SessionAdapter::CztopAdapter.stub :available?, false do
          assert_raises IRuby::SessionAdapterNotFound do
            IRuby::SessionAdapter.select_adapter_class
          end
        end
      end

      with_env('IRUBY_SESSION_ADAPTER' => 'ffi-rzmq') do
        IRuby::SessionAdapter::FfirzmqAdapter.stub :available?, true do
          assert_equal IRuby::SessionAdapter::FfirzmqAdapter, IRuby::SessionAdapter.select_adapter_class
        end

        IRuby::SessionAdapter::FfirzmqAdapter.stub :available?, false do
          assert_raises IRuby::SessionAdapterNotFound do
            IRuby::SessionAdapter.select_adapter_class
          end
        end
      end

      with_env('IRUBY_SESSION_ADAPTER' => 'pyzmq') do
        # pyzmq adapter is disabled
        #
        # IRuby::SessionAdapter::PyzmqAdapter.stub :available?, true do
        #   assert_equal IRuby::SessionAdapter::PyzmqAdapter, IRuby::SessionAdapter.select_adapter_class
        # end
        #
        # IRuby::SessionAdapter::PyzmqAdapter.stub :available?, false do
        #   assert_raises IRuby::SessionAdapterNotFound do
        #     IRuby::SessionAdapter.select_adapter_class
        #   end
        # end
      end
    end
  end
end
