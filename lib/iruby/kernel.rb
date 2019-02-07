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
    rescue Exception => e
      IRuby.logger.warn "Could not load PryBackend: #{e.message}\n#{e.backtrace.join("\n")}" unless LoadError === e
      PlainBackend.new
    end

    def run
      send_status :starting
      while @running
        dispatch
      end
    end

    def dispatch
      msg = @session.recv(:reply)
      IRuby.logger.debug "Kernel#dispatch: msg = #{msg}"
      type = msg[:header]['msg_type']
      raise "Unknown message type: #{msg.inspect}" unless type =~ /comm_|_request\Z/ && respond_to?(type)
      begin
        send_status :busy
        send(type, msg)
      ensure
        send_status :idle
      end
    rescue Exception => e
      IRuby.logger.debug "Kernel error: #{e.message}\n#{e.backtrace.join("\n")}"
      @session.send(:publish, :error, error_message(e))
    end

    def kernel_info_request(msg)
      @session.send(:reply, :kernel_info_reply,
                    protocol_version: '5.0',
                    implementation: 'iruby',
                    banner: "IRuby #{IRuby::VERSION} (with #{@session.description})",
                    implementation_version: IRuby::VERSION,
                    language_info: {
                      name: 'ruby',
                      version: RUBY_VERSION,
                      mimetype: 'application/x-ruby',
                      file_extension: '.rb'
                    })
    end

    def send_status(status)
      IRuby.logger.debug "Send status: #{status}"
      @session.send(:publish, :status, execution_state: status)
    end

    def execute_request(msg)
      code = msg[:content]['code']
      @execution_count += 1 if msg[:content]['store_history']
      @session.send(:publish, :execute_input, code: code, execution_count: @execution_count)

      content = {
        status: :ok,
        payload: [],
        user_expressions: {},
        execution_count: @execution_count
      }
      result = nil
      begin
        result = @backend.eval(code, msg[:content]['store_history'])
      rescue SystemExit
        content[:payload] << { source: :ask_exit }
      rescue Exception => e
        content = error_message(e)
        @session.send(:publish, :error, content)
      end
      @session.send(:reply, :execute_reply, content)
      @session.send(:publish, :execute_result,
                    data: Display.display(result),
                    metadata: {},
                    execution_count: @execution_count) unless result.nil? || msg[:content]['silent']
    end

    def error_message(e)
      { status: :error,
        ename: e.class.to_s,
        evalue: e.message,
        traceback: ["#{RED}#{e.class}#{RESET}: #{e.message}", *e.backtrace.map { |l| "#{WHITE}#{l}#{RESET}" }] }
    end

    def is_complete_request(msg)
      # FIXME: the code completeness should be judged by using ripper or other Ruby parser
      @session.send(:reply, :is_complete_reply,
                    status: :unknown)
    end

    def complete_request(msg)
      # HACK for #26, only complete last line
      code = msg[:content]['code']
      if start = code.rindex(/\s|\R/)
        code = code[start+1..-1]
        start += 1
      end
      @session.send(:reply, :complete_reply,
                    matches: @backend.complete(code),
                    status: :ok,
                    cursor_start: start.to_i,
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
    rescue Exception => e
      IRuby.logger.warn "Inspection error: #{e.message}\n#{e.backtrace.join("\n")}"
      @session.send(:reply, :inspect_reply, status: :error)
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
