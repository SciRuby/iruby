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

    def test_selects_correct_adapter_class
      adapter_name = ENV['IRUBY_TEST_SESSION_ADAPTER_NAME']
      adapter_class = case adapter_name
                      when 'cztop'
                        IRuby::SessionAdapter::CztopAdapter
                      when 'ffi-rzmq'
                        IRuby::SessionAdapter::FfirzmqAdapter
                      else
                        flunk "Unknown session adapter: #{adapter_name.inspect}"
                      end

      selected_class = IRuby::SessionAdapter.select_adapter_class(adapter_name)
      assert_equal(adapter_class, selected_class)
    end

    def test_without_any_session_adapter
      assert_rr do
        stub(IRuby::SessionAdapter::CztopAdapter).available? { false }
        stub(IRuby::SessionAdapter::FfirzmqAdapter).available? { false }
        stub(IRuby::SessionAdapter::TestAdapter).available? { false }
        assert_raises IRuby::SessionAdapterNotFound do
          IRuby::Session.new(@session_config)
        end
      end
    end
  end
end
