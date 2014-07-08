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
      require 'pry'
      Pry.pager = false # Don't use the pager
      Pry.print = proc {|output, value|} # No result printing
      Pry.exception_handler = proc {|output, exception, _| }
      @pry = Pry.new(output: $stdout, target: TOPLEVEL_BINDING)
      raise 'Falling back to plain backend since your version of Pry is too old (the Pry instance doesn\'t support #eval). You may need to install the pry gem with --pre enabled.' unless @pry.respond_to?(:eval)
    end

    def eval(code)
      @pry.last_result = nil
      @pry.eval(code)
      raise @pry.last_exception if @pry.last_result_is_exception?
      @pry.last_result
    end

    def complete(line, text)
      @pry.complete(line)
    end
  end
end
