module IRuby
  module Magic
    class Run < Base

      def execute(args, code)
        filename = args[0]
        puts `ruby #{filename}`
      end

    end
  end
end
