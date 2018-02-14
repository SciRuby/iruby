module IRuby
  module Magic
    class File < Base

      def execute(args, code)
        filename = args[0]
        ::File.write(filename, code.lines[1..-1].join)
        puts "Writing #{filename}"
      end

    end
  end
end
