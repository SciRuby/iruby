module IRuby
  In, Out = [nil], {}
  ::In, ::Out = In, Out

  module HistoryVariables
    def eval(code, store_history)
      if store_history
        ih = binding.local_variable_defined?(:_ih) ? binding.local_variable_get(:_ih) : binding.local_variable_set(:_ih, In)
        binding.local_variable_set("_i#{ih.size}", code)
        ih << code
      end

      out = super

      # TODO Add IRuby.cache_size which controls the size of the Out array
      # and sets the oldest entries and _<n> variables to nil.
      if store_history
        if binding.local_variable_defined?(:_i)
          if binding.local_variable_defined?(:_ii)
            binding.eval('___ = __')
            binding.eval('_iii = _ii')
          end
          binding.eval('__ = _')
          binding.eval('_ii = _i')
        end
        binding.local_variable_set(:_i, code)
        binding.local_variable_set(:_, out)

        oh = binding.local_variable_defined?(:_oh) ? binding.local_variable_get(:_oh) : binding.local_variable_set(:_oh, Out)
        binding.local_variable_set("_#{ih.size - 1}", out)
        oh[ih.size - 1] = out
      end

      out
    end
  end

  class PlainBackend
    prepend HistoryVariables

    def initialize
      Bond.start(debug: true)
    end

    def binding
      TOPLEVEL_BINDING
    end

    def eval(code, store_history)
      binding.eval(code)
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

    def binding
      @pry.push_initial_binding unless @pry.current_binding # ensure that we have a binding
      @pry.current_binding
    end

    def eval(code, store_history)
      @pry.last_result = nil
      raise SystemExit unless @pry.eval(code)
      raise @pry.last_exception if @pry.last_result_is_exception?
      binding # HACK ensure that we have a binding
      @pry.last_result
    end

    def complete(code)
      @pry.complete(code)
    end
  end
end
