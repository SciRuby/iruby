module IRuby
  class Completer
    module Readline
      class<< self
        attr_accessor :line_buffer
        def setup(arg); end
      end
    end

    def initialize
      Bond.start(readline: Readline, debug: true)
    end

    def complete(line, text)
      Readline.line_buffer = line
      Bond.agent.call(line)
    end
  end
end
