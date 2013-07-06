module IRuby
  module Output
    module HTML
      require "gruff"
      require "base64"
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

      def self.image(image)
        data = image.respond_to?(:to_blob) ? image.to_blob : image
        "<img src='data:image/png;base64,#{Base64.encode64(data)}'>"
      end

      def self.chart_pie(o)
        data=o.delete(:data)
        title=o.delete(:title)
        size=o.delete(:size) || 300
        g = Gruff::Pie.new(size)
        g.title = title if title
        data.each do |data|
          g.data(data[0], data[1])
        end
        image(g.to_blob)
      end

      def self.chart_bar(o)
        data=o.delete(:data)
        title=o.delete(:title)
        size=o.delete(:size) || 300
        g = Gruff::Bar.new(size)
        g.title = title if title
        data.each do |data|
          g.data(data[0], data[1])
        end
        image(g.to_blob)

      end
    end
  end
end
