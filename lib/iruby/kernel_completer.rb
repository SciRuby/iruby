require 'bond'

module IRuby
  class KernelCompleter
    class FakeReadline
      def self.setup(arg)
      end

      def self.line_buffer
        @line_buffer
      end
    end

    def initialize(ns)
      @ns = ns
      Bond.start(readline: FakeReadline, debug: true)
    end

    def complete(line, text)
      tab(line)
    end

  private
    def tab(full_line, last_word=full_line)
      # TODO use @ns as binding
      Bond.agent.weapon.instance_variable_set('@line_buffer', full_line)
      Bond.agent.call(last_word)
    end
  end
end
