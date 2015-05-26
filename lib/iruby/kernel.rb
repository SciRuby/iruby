module IRuby
  class Kernel
    RED = "\e[31m"
    WHITE = "\e[37m"
    RESET = "\e[0m"

    class<< self
      attr_accessor :instance
    end

    attr_reader :session

    def initialize(config_file)
      @config = MultiJson.load(File.read(config_file))
      IRuby.logger.debug("IRuby kernel start with config #{@config}")
      Kernel.instance = self

      @session = Session.new(@config)
      $stdout = OStream.new(@session, :stdout)
      $stderr = OStream.new(@session, :stderr)

      @execution_count = 0
      @backend = create_backend
      @running = true
    end

    def create_backend
      PryBackend.new
    rescue Exception => ex
      IRuby.logger.warn ex.message unless LoadError === ex
      PlainBackend.new
    end

    def run
      send_status :starting
      while @running
        msg = @session.recv(:reply)
        type = msg[:header]['msg_type']
        if type =~ /comm_|_request\Z/ && respond_to?(type)
          send_status :busy
          send(type, msg)
          send_status :idle
        else
          IRuby.logger.error "Unknown message type: #{msg[:header]['msg_type']} #{msg.inspect}"
        end
      end
    end

    def kernel_info_request(msg)
      @session.send(:reply, :kernel_info_reply,
                    protocol_version: '5.0',
                    implementation: 'iruby',
                    banner: "IRuby #{IRuby::VERSION}",
                    implementation_version: IRuby::VERSION,
                    language_info: {
                      name: 'ruby',
                      version: RUBY_VERSION,
                      mimetype: 'text/ruby',
                      file_extension: 'rb'
                    })
    end

    def send_status(status)
      @session.send(:publish, :status, execution_state: status)
    end

    def execute_request(msg)
      code = msg[:content]['code']
      @execution_count += 1 if msg[:content]['store_history']
      @session.send(:publish, :execute_input, code: code, execution_count: @execution_count)

      result = nil
      begin
        result = @backend.eval(code, msg[:content]['store_history'])
        content = {
          status: :ok,
          payload: [],
          user_expressions: {},
          execution_count: @execution_count
        }
      rescue SystemExit
        raise
      rescue Exception => e
        content = {
          status: :error,
          ename: e.class.to_s,
          evalue: e.message,
          traceback: ["#{RED}#{e.class}#{RESET}: #{e.message}", *e.backtrace.map { |l| "#{WHITE}#{l}#{RESET}" }],
          execution_count: @execution_count
        }
        @session.send(:publish, :error, content)
      end
      @session.send(:reply, :execute_reply, content)
      unless result.nil? || msg[:content]['silent']
        @session.send(:publish, :execute_result, data: Display.display(result), metadata: {}, execution_count: @execution_count)
      end
    end

    def complete_request(msg)
      @session.send(:reply, :complete_reply,
                    matches: @backend.complete(msg[:content]['code']),
                    status: :ok,
                    cursor_start: 0,
                    cursor_end: msg[:content]['cursor_pos'])
    end

    def connect_request(msg)
      @session.send(:reply, :connect_reply, Hash[%w(shell_port iopub_port stdin_port hb_port).map {|k| [k, @config[k]] }])
    end

    def shutdown_request(msg)
      @session.send(:reply, :shutdown_reply, msg[:content])
      @running = false
    end

    def history_request(msg)
      # we will just send back empty history for now, pending clarification
      # as requested in ipython/ipython#3806
      @session.send(:reply, :history_reply, history: [])
    end

    def inspect_request(msg)
      result = @backend.eval(msg[:content]['code'])
      @session.send(:reply, :inspect_reply,
                    status: :ok,
                    data: Display.display(result),
                    metadata: {})
    rescue Exception
      @session.send(:reply, :inspect_reply, status: 'error')
    end

    def comm_open(msg)
      comm_id = msg[:content]['comm_id']
      target_name = msg[:content]['target_name']
      Comm.comm[comm_id] = Comm.target[target_name].new(target_name, comm_id)
    end

    def comm_msg(msg)
      Comm.comm[msg[:content]['comm_id']].handle_msg(msg[:content]['data'])
    end

    def comm_close(msg)
      comm_id = msg[:content]['comm_id']
      Comm.comm[comm_id].handle_close(msg[:content]['data'])
      Comm.comm.delete(comm_id)
    end
  end
end
