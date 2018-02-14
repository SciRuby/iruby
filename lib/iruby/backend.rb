module IRuby
  In, Out = [nil], [nil]
  ::In, ::Out = In, Out
  MAGICS = {}

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

    def initialize_magics
      @magics = {}
      IRuby::Magic::Base.subclasses.each do|clazz|
        magic = clazz.new(self)
        @magics[magic.name] = clazz.new(self)
        IRuby::Magic::AVAILABLE_MAGIC_NAMES << magic.name
      end
    end

    def eval_with_magic(code)
      first_line = code.lines.first.strip
      if first_line[0] == '%'
        cmd, *args = first_line.sub(/^[\s%]+/, '').split(/[\s]/).reject(&:empty?)
        magic = @magics[cmd]
        if magic
          magic.execute(args, code)
        else
          "Unknown magic [#{cmd}]"
        end
      else
        yield code
      end
    end

  end

  class PlainBackend
    prepend History

    def initialize
      require 'bond'
      initialize_magics
      Bond.start(debug: true)
    end

    def eval(code, store_history)
      eval_with_magic(code) do
        TOPLEVEL_BINDING.eval(code)
      end
    end

    def complete(code)
      Bond.agent.call(code, code)
    end

  end

  class PryBackend
    prepend History

    def initialize
      require 'pry'
      initialize_magics
      Pry.memory_size = 3 
      Pry.pager = false # Don't use the pager
      Pry.print = proc {|output, value|} # No result printing
      Pry.exception_handler = proc {|output, exception, _| }
      reset
    end

    def eval(code, store_history)
      @pry.last_result = nil

      eval_with_magic(code) do
        unless @pry.eval(code)
          reset
          raise SystemExit
        end
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
