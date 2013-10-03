module IRuby
  class PlainBackend
    def initialize
      Bond.start(debug: true)
    end

    def eval(code)
      TOPLEVEL_BINDING.eval(code)
    end

    def complete(line, text)
      Bond.agent.call(line, line)
    end
  end

  class PryBackend
    def initialize
      # Monkey patching the Pry bond completer
      ::Pry::BondCompleter.module_eval do
        def self.call(input, options)
          Pry.current[:pry] = options[:pry]
          Bond.agent.call(input, input)
        end
      end
      Pry.pager = false
      @pry = Pry.new(output: File.open(File::NULL, 'w'), target: TOPLEVEL_BINDING)
    end

    def eval(code)
      @pry.eval(code)
      raise @pry.last_exception if @pry.last_result_is_exception?
      @pry.last_result
    end

    def complete(line, text)
      @pry.complete(line)
    end
  end
end
