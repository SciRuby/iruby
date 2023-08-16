module IRuby
  ExecutionInfo = Struct.new(:raw_cell, :store_history, :silent)

  class Kernel
    RED = "\e[31m"
    RESET = "\e[0m"

    @events = EventManager.new([:initialized])

    class << self
      # Return the event manager defined in the `IRuby::Kernel` class.
      # This event manager can handle the following event:
      #
      # - `initialized`: The event occurred after the initialization of
      #   a `IRuby::Kernel` instance is finished
      #
      # @example Registering initialized event
      #   IRuby::Kernel.events.register(:initialized) do |result|
      #     STDERR.puts "IRuby kernel has been initialized"
      #   end
      #
      # @see IRuby::EventManager
      # @see IRuby::Kernel#events
      attr_reader :events

      # Returns the singleton kernel instance
      attr_accessor :instance
    end

    # Returns a session object
    attr_reader :session

    EVENTS = [
      :pre_execute,
      :pre_run_cell,
      :post_run_cell,
      :post_execute
    ].freeze

    def initialize(config_file, session_adapter_name=nil)
      @config = MultiJson.load(File.read(config_file))
      IRuby.logger.debug("IRuby kernel start with config #{@config}")
      Kernel.instance = self

      @session = Session.new(@config, session_adapter_name)
      $stdout = OStream.new(@session, :stdout)
      $stderr = OStream.new(@session, :stderr)

      init_parent_process_poller

      @events = EventManager.new(EVENTS)
      @execution_count = 0
      @backend = PlainBackend.new
      @running = true

      self.class.events.trigger(:initialized, self)
    end

    # Returns the event manager defined in a `IRuby::Kernel` instance.
    # This event manager can handle the following events:
    #
    # - `pre_execute`: The event occurred before running the code
    #
    # - `pre_run_cell`: The event occurred before running the code and
    #   if the code execution is not silent
    #
    # - `post_execute`: The event occurred after running the code
    #
    # - `post_run_cell`: The event occurred after running the code and
    #   if the code execution is not silent
    #
    # The callback functions of `pre_run_cell` event must take one argument
    # to get an `ExecutionInfo` object.
    # The callback functions of `post_run_cell` event must take one argument
    # to get the result of the code execution.
    #
    # @example Registering post_run_cell event
    #   IRuby::Kernel.instance.events.register(:post_run_cell) do |result|
    #     STDERR.puts "The result of the last execution: %p" % result
    #   end
    #
    # @see IRuby::EventManager
    # @see IRuby::ExecutionInfo
    # @see IRuby::Kernel.events
    attr_reader :events

    # Switch the backend (interactive shell) system
    #
    # @param backend [:irb,:plain,:pry] Specify the backend name switched to
    #
    # @return [true,false] true if the switching succeeds, otherwise false
    def switch_backend!(backend)
      name = case backend
             when String, Symbol
               name = backend.downcase
             else
               name = backend
             end

      backend_class = case name
                      when :irb, :plain
                        PlainBackend
                      when :pry
                        PryBackend
                      else
                        raise ArgumentError,
                          "Unknown backend name: %p" % backend
                      end

      begin
        new_backend = backend_class.new
        @backend = new_backend
        true
      rescue Exception => e
        unless LoadError === e
          IRuby.logger.warn "Could not load #{backend_class}: " +
                            "#{e.message}\n#{e.backtrace.join("\n")}"
        end
        return false
      end
    end

    # @private
    def run
      send_status :starting
      while @running
        dispatch
      end
    end

    # @private
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
      @session.send(:publish, :error, error_content(e))
    end

    # @private
    def kernel_info_request(msg)
      @session.send(:reply, :kernel_info_reply,
                    protocol_version: '5.0',
                    implementation: 'iruby',
                    implementation_version: IRuby::VERSION,
                    language_info: {
                      name: 'ruby',
                      version: RUBY_VERSION,
                      mimetype: 'application/x-ruby',
                      file_extension: '.rb'
                    },
                    banner: "IRuby #{IRuby::VERSION} (with #{@session.description})",
                    help_links: [
                      {
                        text: "Ruby Documentation",
                        url:  "https://ruby-doc.org/"
                      }
                    ],
                    status: :ok)
    end

    # @private
    def send_status(status)
      IRuby.logger.debug "Send status: #{status}"
      @session.send(:publish, :status, execution_state: status)
    end

    # @private
    def execute_request(msg)
      code = msg[:content]['code']
      silent = msg[:content]['silent']
      # https://jupyter-client.readthedocs.io/en/stable/messaging.html#execute
      store_history = silent ? false : msg[:content].fetch('store_history', true)

      @execution_count += 1 if store_history

      unless silent
        @session.send(:publish, :execute_input, code: code, execution_count: @execution_count)
      end

      events.trigger(:pre_execute)
      unless silent
        exec_info = ExecutionInfo.new(code, store_history, silent)
        events.trigger(:pre_run_cell, exec_info)
      end

      content = {
        status: :ok,
        payload: [],
        user_expressions: {},
        execution_count: @execution_count
      }

      result = nil
      begin
        result = @backend.eval(code, store_history)
      rescue SystemExit
        content[:payload] << { source: :ask_exit }
      rescue Exception => e
        content = error_content(e)
        @session.send(:publish, :error, content)
        content[:status] = :error
        content[:execution_count] = @execution_count
      end

      unless result.nil? || silent
        @session.send(:publish, :execute_result,
                      data: Display.display(result),
                      metadata: {},
                      execution_count: @execution_count)
      end

      events.trigger(:post_execute)
      # **{} is for Ruby2.7. Gnuplot#to_hash returns an Array.
      events.trigger(:post_run_cell, result, **{}) unless silent

      @session.send(:reply, :execute_reply, content)
    end

    # @private
    def error_content(e)
      rindex = e.backtrace.rindex{|line| line.start_with?(@backend.eval_path)} || -1
      backtrace = SyntaxError === e  && rindex == -1 ? [] : e.backtrace[0..rindex]
      { ename: e.class.to_s,
        evalue: e.message,
        traceback: ["#{RED}#{e.class}#{RESET}: #{e.message}", *backtrace] }
    end

    # @private
    def is_complete_request(msg)
      # FIXME: the code completeness should be judged by using ripper or other Ruby parser
      @session.send(:reply, :is_complete_reply,
                    status: :unknown)
    end

    # @private
    def complete_request(msg)
      # HACK for #26, only complete last line
      code = msg[:content]['code']
      if start = code.rindex(/\s|\R/)
        code = code[start+1..-1]
        start += 1
      end
      @session.send(:reply, :complete_reply,
                    matches: @backend.complete(code),
                    cursor_start: start.to_i,
                    cursor_end: msg[:content]['cursor_pos'],
                    metadata: {},
                    status: :ok)
    end

    # @private
    def connect_request(msg)
      @session.send(:reply, :connect_reply, Hash[%w(shell_port iopub_port stdin_port hb_port).map {|k| [k, @config[k]] }])
    end

    # @private
    def shutdown_request(msg)
      @session.send(:reply, :shutdown_reply, msg[:content])
      @running = false
    end

    # @private
    def history_request(msg)
      # we will just send back empty history for now, pending clarification
      # as requested in ipython/ipython#3806
      @session.send(:reply, :history_reply, history: [])
    end

    # @private
    def inspect_request(msg)
      # not yet implemented. See (#119).
      @session.send(:reply, :inspect_reply, status: :ok, found: false, data: {}, metadata: {})
    end

    # @private
    def comm_open(msg)
      comm_id = msg[:content]['comm_id']
      target_name = msg[:content]['target_name']
      Comm.comm[comm_id] = Comm.target[target_name].new(target_name, comm_id)
    end

    # @private
    def comm_msg(msg)
      Comm.comm[msg[:content]['comm_id']].handle_msg(msg[:content]['data'])
    end

    # @private
    def comm_close(msg)
      comm_id = msg[:content]['comm_id']
      Comm.comm[comm_id].handle_close(msg[:content]['data'])
      Comm.comm.delete(comm_id)
    end

    private

    def init_parent_process_poller
      pid = ENV.fetch('JPY_PARENT_PID', 0).to_i
      return unless pid > 1

      case RUBY_PLATFORM
      when /mswin/, /mingw/
        # TODO
      else
        @parent_poller = start_parent_process_pollar_unix
      end
    end

    def start_parent_process_pollar_unix
      Thread.start do
        IRuby.logger.warn("parent process poller thread started.")
        loop do
          begin
            current_ppid = Process.ppid
            if current_ppid == 1
              IRuby.logger.warn("parent process appears to exited, shutting down.")
              exit!(1)
            end
            sleep 1
          rescue Errno::EINTR
            # ignored
          end
        end
      end
    end
  end
end
