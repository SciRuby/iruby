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
  end
end
