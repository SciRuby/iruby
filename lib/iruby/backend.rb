module IRuby
  In, Out = [nil], [nil]
  ::In, ::Out = In, Out

  module HistoryVariables
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
    prepend HistoryVariables

    def initialize
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
    prepend HistoryVariables

    def initialize
      require 'pry'
      Pry.pager = false # Don't use the pager
      Pry.print = proc {|output, value|} # No result printing
      Pry.exception_handler = proc {|output, exception, _| }
      @pry = Pry.new(output: $stdout, target: TOPLEVEL_BINDING)
      raise 'Falling back to plain backend since your version of Pry is too old (the Pry instance doesn\'t support #eval). You may need to install the pry gem with --pre enabled.' unless @pry.respond_to?(:eval)
    end

    def eval(code, store_history)
      raise SystemExit unless @pry.eval(code)
      raise @pry.last_exception if @pry.last_result_is_exception?
      @pry.push_initial_binding unless @pry.current_binding # ensure that we have a binding
      @pry.last_result
    end

    def complete(code)
      @pry.complete(code)
    end
  end
end
