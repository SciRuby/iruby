require 'test_helper'

module IRubyTest
  class SessionAdapterSelectionTest < TestBase
    def setup
      @session_config = {}
    end

    def test_without_any_session_adapter
      IRuby::SessionAdapter::CztopAdapter.stub :available?, false do
        IRuby::SessionAdapter::RbczmqAdapter.stub :available?, false do
          IRuby::SessionAdapter::FfirzmqAdapter.stub :available?, false do
            IRuby::SessionAdapter::PyzmqAdapter.stub :available?, false do
              assert_raises IRuby::SessionAdapterNotFound do
                IRuby::Session.new(@session_config)
              end
            end
          end
        end
      end
    end

    def test_with_rbczmq
      IRuby::SessionAdapter::RbczmqAdapter.stub :available?, true do
        IRuby::SessionAdapter::CztopAdapter.stub :available?, false do
          IRuby::SessionAdapter::FfirzmqAdapter.stub :available?, false do
            IRuby::SessionAdapter::PyzmqAdapter.stub :available?, false do
              session = IRuby::Session.new(@session_config)
              assert_kind_of IRuby::SessionAdapter::RbczmqAdapter, session.adapter
            end
          end
        end
      end
    end

    def test_with_cztop
      IRuby::SessionAdapter::CztopAdapter.stub :available?, true do
        IRuby::SessionAdapter::RbczmqAdapter.stub :available?, false do
          IRuby::SessionAdapter::FfirzmqAdapter.stub :available?, false do
            IRuby::SessionAdapter::PyzmqAdapter.stub :available?, false do
              session = IRuby::Session.new(@session_config)
              assert_kind_of IRuby::SessionAdapter::CztopAdapter, session.adapter
            end
          end
        end
      end
    end

    def test_with_ffirzmq
      IRuby::SessionAdapter::FfirzmqAdapter.stub :available?, true do
        IRuby::SessionAdapter::RbczmqAdapter.stub :available?, false do
          IRuby::SessionAdapter::CztopAdapter.stub :available?, false do
            IRuby::SessionAdapter::PyzmqAdapter.stub :available?, false do
              session = IRuby::Session.new(@session_config)
              assert_kind_of IRuby::SessionAdapter::FfirzmqAdapter, session.adapter
            end
          end
        end
      end
    end

    def test_with_pyzmq
      IRuby::SessionAdapter::PyzmqAdapter.stub :available?, true do
        IRuby::SessionAdapter::RbczmqAdapter.stub :available?, false do
          IRuby::SessionAdapter::CztopAdapter.stub :available?, false do
            IRuby::SessionAdapter::FfirzmqAdapter.stub :available?, false do
              session = IRuby::Session.new(@session_config)
              assert_kind_of IRuby::SessionAdapter::PyzmqAdapter, session.adapter
            end
          end
        end
      end
    end
  end
end
