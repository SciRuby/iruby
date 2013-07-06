module IRuby
  module Output
    module HTML
      def self.table(data)
        #
        # data = {a: 1, b:2}

        if data.respond_to?(:keys)
          d = data
        else
          d = data
        end

        r = "<table>"
        if d.respond_to?(:keys) # hash
          columns = [0,1]
        else
          columns = d.first.keys
          r << "<tr>#{columns.map{|c| "<th>#{c}</th>"}.join("\n")}</tr>"
        end
        d.each{|row|
          r << "<tr>"
          columns.each{|column|
            r << "<td>#{row[column]}</td>"
          }
          r << "</tr>"
        }
        r << "</table>"
        r
      end
    end
  end
end
