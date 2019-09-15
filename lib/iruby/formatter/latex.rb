module IRuby
  module Formatter
    module LaTeX
      extend self

      def vector(v)
        x = 'c' * v.size
        y = v.map(&:to_s).join(' & ')
        "$$\\left(\\begin{array}{#{x}} #{y} \\end{array}\\right)$$"
      end

      def matrix(m, row_count, column_count)
        s = "$$\\left(\\begin{array}{#{'c' * column_count}}\n"
        (0...row_count).each do |i|
          s << '  ' << m[i,0].to_s
          (1...column_count).each do |j|
            s << '&' << m[i,j].to_s
          end
          s << "\\\\\n"
        end
        s << "\\end{array}\\right)$$"
      end
    end
  end
end
