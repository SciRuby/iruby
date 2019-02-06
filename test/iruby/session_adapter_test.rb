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
  end
end
