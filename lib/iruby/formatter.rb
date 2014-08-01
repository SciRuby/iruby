module IRuby
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

  module HTML
    extend self

    def table(obj, options = {})
      options[:maxrows] = 15 unless options.include?(:maxrows)
      return obj unless Enumerable === obj
      keys = nil
      size = 0
      rows = []
      obj.each_with_index do |row, i|
        row = row.flatten(1) if obj.respond_to?(:keys)
        if row.respond_to?(:keys)
          # Array of Hashes
          keys ||= Set.new
          keys.merge(row.keys)
        elsif row.respond_to?(:map)
          # Array of Arrays
          size = row.size if size < row.size
        end
        if options[:maxrows] && i > options[:maxrows]
          rows << '...'
          break
        end
        rows << row
      end
      table = '<table>'
      if keys
        keys.merge(0...size)
        table << '<tr>' << keys.map {|k| "<th>#{k}</th>"}.join << '</tr>'
      else
        keys = 0...size
      end
      rows.each do |row|
        table << '<tr>'
        if row.respond_to?(:map)
          row = keys.map {|k| "<td>#{row[k] rescue nil}</td>" }
          if row.empty?
            table << "<td#{keys.size > 1 ? " colspan='#{keys.size}'" : ''}></td>"
          else
            table << row.join
          end
        else
          table << "<td#{keys.size > 1 ? " colspan='#{keys.size}'" : ''}>#{row}</td>"
        end
        table << '</tr>'
      end
      table << '</table>'
    end
  end
end
