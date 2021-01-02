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

    def table(obj, maxrows: 15, maxcols: 15, **options)
      raise ArgumentError, 'Invalid :maxrows' if maxrows && maxrows < 3
      raise ArgumentError, 'Invalid :maxcols' if maxcols && maxcols < 3

      return obj unless obj.respond_to?(:each)

      rows = []

      if obj.respond_to?(:keys)
        # Hash of Arrays
        header = obj.keys
        keys = (0...obj.keys.size).to_a
        cols = obj.values.map {|x| [x].flatten(1) }
        num_rows = cols.map(&:size).max
        rows = []
        (0...num_rows).each do |i|
          rows << []
          (0...cols.size).each do |j|
            rows[i][j] = cols[j][i]
          end
        end
      else
        keys = nil
        array_size = 0

        obj.each do |row|
          if row.respond_to?(:keys)
            # Array of Hashes
            keys ||= Set.new
            keys.merge(row.keys)
          elsif row.respond_to?(:map)
            # Array of Arrays
            array_size = row.size if array_size < row.size
          end
          rows << row
        end

        if keys
          header = keys.to_a
          keys.merge(0...array_size)
        else
          keys = 0...array_size
        end
        keys = keys.to_a
      end

      header ||= keys if options[:header]

      rows1, rows2 = rows, nil
      keys1, keys2 = keys, nil
      header1, header2 = header, nil

      if maxcols && keys.size > maxcols
        keys1 = keys[0...maxcols / 2]
        keys2 = keys[-maxcols / 2 + 1..-1]
        if header
          header1 = header[0...maxcols / 2]
          header2 = header[-maxcols / 2 + 1..-1]
        end
      end

      if maxrows && rows.size > maxrows
        rows1 = rows[0...maxrows / 2]
        rows2 = rows[-maxrows / 2 + 1..-1]
      end

      table = '<table>'

      if header1 && options[:header] != false
        table << '<tr>' << header1.map {|k| "<th>#{cell k}</th>" }.join
        table << "<th>&#8230;</th>" << header2.map {|k| "<th>#{cell k}</th>" }.join if keys2
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

    def cell(obj)
      obj.respond_to?(:to_html) ? obj.to_html : obj
    end

    def elem(row, k)
      cell((row[k] rescue nil))
    end

    def row_block(table, rows, keys1, keys2)
      cols = keys1.size
      cols += keys2.size + 1 if keys2
      rows.each_with_index do |row, i|
        table << '<tr>'
        if row.respond_to?(:map)
          row_html = keys1.map {|k| "<td>#{elem row, k}</td>" }.join
          if keys2
            row_html << "<td#{rows.size > 1 ? " rowspan='#{rows.size}'" : ''}>&#8230;</td>" if i == 0
            row_html << keys2.map {|k| "<td>#{elem row, k}</td>" }.join
          end
          if row_html.empty?
            table << "<td#{cols > 1 ? " colspan='#{cols}'" : ''}></td>"
          else
            table << row_html
          end
        else
          table << "<td#{cols > 1 ? " colspan='#{cols}'" : ''}>#{cell row}</td>"
        end
        table << '</tr>'
      end
    end
  end
end
