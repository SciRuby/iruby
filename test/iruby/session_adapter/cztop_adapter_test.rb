require_relative 'session_adapter_test_base'
require 'iruby'

module IRubyTest
  if ENV['IRUBY_TEST_SESSION_ADAPTER_NAME'] == 'cztop'
    class CztopAdapterTest < SessionAdapterTestBase
      def adapter_class
        IRuby::SessionAdapter::CztopAdapter
      end

      def test_send
        assert(adapter_class.available?)
      end

      def test_recv
        omit
      end
    end
  end
end
