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
      options[:maxcols] = 15 unless options.include?(:maxcols)
      raise ArgumentError, 'Invalid :maxrows' if options[:maxrows] && options[:maxrows] < 3
      raise ArgumentError, 'Invalid :maxcols' if options[:maxcols] && options[:maxcols] < 3

      return obj unless Enumerable === obj
      keys = nil
      size = 0
      rows = []

      obj.each do |row|
        row = row.flatten(1) if obj.respond_to?(:keys)
        if row.respond_to?(:keys)
          # Array of Hashes
          keys ||= Set.new
          keys.merge(row.keys)
        elsif row.respond_to?(:map)
          # Array of Arrays
          size = row.size if size < row.size
        end
        rows << row
      end

      if header = keys
        keys.merge(0...size)
      else
        keys = 0...size
      end
      keys = keys.to_a

      rows1, rows2 = rows, nil
      keys1, keys2 = keys, nil

      if options[:maxcols] && keys.size > options[:maxcols]
        keys1 = keys[0...options[:maxcols] / 2]
        keys2 = keys[-options[:maxcols] / 2...-1]
      end

      if options[:maxrows] && rows.size > options[:maxrows]
        rows1 = rows[0...options[:maxrows] / 2]
        rows2 = rows[-options[:maxrows] / 2...-1]
      end

      table = '<table>'

      if (header || options[:header]) && options[:header] != false
        table << '<tr>' << keys1.map {|k| "<th>#{k}</th>" }.join
        table << "<th>&#8230;</th>" << keys2.map {|k| "<th>#{k}</th>" }.join if keys2
        table << '</tr>'
      end

      row_block(table, rows1, keys1, keys2)

      if rows2
        table << "<tr><td#{keys1.size > 1 ? " colspan='#{keys1.size}'" : ''}>&#8942;</td>"
        table << "<td>&#8945;</td><td#{keys2.size > 1 ? " colspan='#{keys2.size}'" : ''}>&#8942;</td>" if keys2
        table << '</tr>'

        row_block(table, rows2, keys1, keys2)
      end

      table << '</table>'
    end

    private

    def row_block(table, rows, keys1, keys2)
      cols = keys1.size
      cols += keys2.size + 1 if keys2
      rows.each_with_index do |row, i|
        table << '<tr>'
        if row.respond_to?(:map)
          row_html = keys1.map {|k| "<td>#{row[k] rescue nil}</td>" }.join
          if keys2
            row_html << "<td#{rows.size > 1 ? " rowspan='#{rows.size}'" : ''}>&#8230;</td>" if i == 0
            row_html << keys2.map {|k| "<td>#{row[k] rescue nil}</td>" }.join
          end
          if row_html.empty?
            table << "<td#{cols > 1 ? " colspan='#{cols}'" : ''}></td>"
          else
            table << row_html
          end
        else
          table << "<td#{cols > 1 ? " colspan='#{cols}'" : ''}>#{row}</td>"
        end
        table << '</tr>'
      end
    end
  end
end
