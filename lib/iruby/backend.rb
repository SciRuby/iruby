module IRuby
  In, Out = [nil], [nil]
  ::In, ::Out = In, Out

  module History
    def eval(code, store_history)
      b = TOPLEVEL_BINDING

      b.local_variable_set(:_ih, In)  unless b.local_variable_defined?(:_ih)
      b.local_variable_set(:_oh, Out) unless b.local_variable_defined?(:_oh)

      out = super

      # TODO Add IRuby.cache_size which controls the size of the Out array
      # and sets the oldest entries and _<n> variables to nil.
      if store_history
        b.local_variable_set("_#{Out.size}", out)
        b.local_variable_set("_i#{In.size}", code)

        Out << out
        In << code

        b.local_variable_set(:___,  Out[-3])
        b.local_variable_set(:__,   Out[-2])
        b.local_variable_set(:_,    Out[-1])
        b.local_variable_set(:_iii, In[-3])
        b.local_variable_set(:_ii,  In[-2])
        b.local_variable_set(:_i,   In[-1])
      end

      out
    end
  end

  class PlainBackend
    prepend History

    def initialize
      require 'bond'
      Bond.start(debug: true)
    end

    def eval(code, store_history)
      TOPLEVEL_BINDING.eval(code)
    end

    def complete(code)
      Bond.agent.call(code, code)
    end
  end

  class PryBackend
    prepend History

    def initialize
      require 'pry'
      Pry.memory_size = 3 
      Pry.pager = false # Don't use the pager
      Pry.print = proc {|output, value|} # No result printing
      Pry.exception_handler = proc {|output, exception, _| }
      reset
    end

    def eval(code, store_history)
      @pry.last_result = nil
      unless @pry.eval(code)
        reset
        raise SystemExit
      end
      unless @pry.eval_string.empty?
        syntax_error = @pry.eval_string
        @pry.reset_eval_string
        @pry.evaluate_ruby syntax_error
      end
      raise @pry.last_exception if @pry.last_result_is_exception?
      @pry.push_initial_binding unless @pry.current_binding # ensure that we have a binding
      @pry.last_result
    end

    def complete(code)
      @pry.complete(code)
    end

    def reset
      @pry = Pry.new(output: $stdout, target: TOPLEVEL_BINDING)
    end
  end
end
