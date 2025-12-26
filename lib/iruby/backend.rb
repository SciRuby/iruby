module IRuby
  In, Out = [nil], [nil]

  class << self
    attr_accessor :silent_assignment
  end
  self.silent_assignment = false

  module History
    def eval(code, store_history)
      b = eval_binding

      b.local_variable_set(:_ih, In)  unless b.local_variable_defined?(:_ih)
      b.local_variable_set(:_oh, Out) unless b.local_variable_defined?(:_oh)

      out = super

      # TODO Add IRuby.cache_size which controls the size of the Out array
      # and sets the oldest entries and _<n> variables to nil.
      if store_history
        b.local_variable_set("_o#{Out.size}", out)
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
    attr_reader :eval_path
    prepend History

    def initialize
      require 'irb'
      require 'irb/completion'
      IRB.setup(nil)
      @main = TOPLEVEL_BINDING.eval("self").dup
      init_main_object(@main)
      @workspace = IRB::WorkSpace.new(@main)
      @irb = IRB::Irb.new(@workspace)
      @eval_path = @irb.context.irb_path
      IRB.conf[:MAIN_CONTEXT] = @irb.context
      @completor = IRB::RegexpCompletor.new if defined? IRB::RegexpCompletor # IRB::VERSION >= 1.8.2
    end

    def eval_binding
      @workspace.binding
    end

    def eval(code, store_history)
      @irb.context.evaluate(parse_code(code), 0)
      @irb.context.last_value unless IRuby.silent_assignment && assignment_expression?(code)
    end

    def parse_code(code)
      return code if Gem::Version.new(IRB::VERSION) < Gem::Version.new('1.13.0')
      return @irb.parse_input(code) if @irb.respond_to?(:parse_input)
      return @irb.build_statement(code) if @irb.respond_to?(:build_statement)
    end

    def complete(code)
      if @completor
        # preposing and postposing never used, so they are empty, pass only target as code
        @completor.completion_candidates('', code, '', bind: @workspace.binding)
      else
        IRB::InputCompletor::CompletionProc.call(code)
      end
    end

    private

    def init_main_object(main)
      wrapper_module = Module.new
      main.extend(wrapper_module)
      main.define_singleton_method(:include) do |*args|
        wrapper_module.include(*args)
      end
    end

    def assignment_expression?(code)
      @irb.respond_to?(:assignment_expression?) && @irb.assignment_expression?(code)
    end
  end

  class PryBackend
    attr_reader :eval_path
    prepend History

    def initialize
      require 'pry'
      Pry.memory_size = 3
      Pry.pager = false # Don't use the pager
      Pry.print = proc {|output, value|} # No result printing
      Pry.exception_handler = proc {|output, exception, _| }
      @eval_path = Pry.eval_path
      reset
    end

    def eval_binding
      TOPLEVEL_BINDING
    end

    def eval(code, store_history)
      Pry.current_line = 1
      @pry.last_result = nil
      unless @pry.eval(code)
        reset
        raise SystemExit
      end

      # Pry::Code.complete_expression? return false
      if !@pry.eval_string.empty?
        syntax_error = @pry.eval_string
        @pry.reset_eval_string
        @pry.evaluate_ruby(syntax_error)

      # Pry::Code.complete_expression? raise SyntaxError
      # evaluate again for current line number
      elsif @pry.last_result_is_exception? &&
              @pry.last_exception.is_a?(SyntaxError) &&
              @pry.last_exception.is_a?(Pry::UserError)
         @pry.evaluate_ruby(code)
      end

      raise @pry.last_exception if @pry.last_result_is_exception?
      @pry.push_initial_binding unless @pry.current_binding # ensure that we have a binding
      @pry.last_result
    end

    def complete(code)
      @pry.complete(code)
    end

    def reset
      @pry = Pry.new(output: $stdout, target: eval_binding)
    end
  end
end
