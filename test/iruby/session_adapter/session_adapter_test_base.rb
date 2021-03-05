module IRubyTest
  class SessionAdapterTestBase < TestBase
    # https://jupyter-client.readthedocs.io/en/stable/kernels.html#connection-files
    def make_connection_config
      {
        "control_port" => 50160,
        "shell_port" => 57503,
        "transport" => "tcp",
        "signature_scheme" => "hmac-sha256",
        "stdin_port" => 52597,
        "hb_port" => 42540,
        "ip" => "127.0.0.1",
        "iopub_port" => 40885,
        "key" => "a0436f6c-1916-498b-8eb9-e81ab9368e84"
      }
    end

    def setup
      @config = make_connection_config
      @session_adapter = adapter_class.new(@config)

      unless adapter_class.available?
        omit("#{@session_adapter.name} is unavailable")
      end
    end
  end
end
