require 'test_helper'

module IRubyTest
  class SessionAdapterSelectionTest < TestBase
    def setup
      # https://jupyter-client.readthedocs.io/en/stable/kernels.html#connection-files
      @session_config = {
        "control_port" => 0,
        "shell_port" => 0,
        "transport" => "tcp",
        "signature_scheme" => "hmac-sha256",
        "stdin_port" => 0,
        "hb_port" => 0,
        "ip" => "127.0.0.1",
        "iopub_port" => 0,
        "key" => "a0436f6c-1916-498b-8eb9-e81ab9368e84"
      }
    end

    def test_new_with_session_adapter
      adapter_name = ENV['IRUBY_TEST_SESSION_ADAPTER_NAME']
      adapter_class = case adapter_name
                      when 'cztop'
                        IRuby::SessionAdapter::CztopAdapter
                      when 'ffi-rzmq'
                        IRuby::SessionAdapter::FfirzmqAdapter
                      when 'pyzmq'
                        skip "pyzmq adapter is disabled"
                        # IRuby::SessionAdapter::PyzmqAdapter
                      else
                        flunk "Unknown session adapter: #{adapter_name}"
                      end

      session = IRuby::Session.new(@session_config, adapter_name)
      assert_kind_of(adapter_class, session.adapter)
    end

    def test_without_any_session_adapter
      IRuby::SessionAdapter::CztopAdapter.stub :available?, false do
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
