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

    def test_new_with_session_adapter_closes_heartbeat
      adapter_name = ENV['IRUBY_TEST_SESSION_ADAPTER_NAME']
      omit("ffi-rzmq only") unless adapter_name == 'ffi-rzmq'

      session = IRuby::Session.new(@session_config, adapter_name)

      session.close
      refute(session.instance_variable_get(:@heartbeat_thread).alive?)
    ensure
      session&.close
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

    def test_close_releases_adapter_resources
      session = IRuby::Session.new(@session_config, "test")
      adapter = session.adapter

      session.close

      assert(adapter.closed)
      assert(adapter.heartbeat_started)
      assert(adapter.heartbeat_finished)
      assert_equal([
                     :PUB,
                     :REP,
                     :ROUTER,
                     :ROUTER,
                   ],
                   adapter.closed_sockets.map(&:type).sort_by(&:to_s))
      refute(session.instance_variable_get(:@heartbeat_thread).alive?)
    ensure
      session&.close
    end
  end
end
