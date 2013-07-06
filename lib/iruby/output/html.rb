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

      #stolen from https://github.com/Bantik/heatmap/blob/master/lib/heatmap.rb
      module Heatmap

        def self.heatmap(histogram={})
          html = %{<div class="heatmap">}
          histogram.keys.sort{|a,b| histogram[a] <=> histogram[b]}.reverse.each do |k|
            next if histogram[k] < 1
            _max = histogram_max(histogram) * 2
            _size = element_size(histogram, k)
            _heat = element_heat(histogram[k], _max)
            html << %{
        <span class="heatmap_element" style="color: ##{_heat}#{_heat}#{_heat}; font-size: #{_size}px;">#{k}</span>
      }
          end
          html << %{<br style="clear: both;" /></div>}
        end

        def self.histogram_max(histogram)
          histogram.map{|k,v| histogram[k]}.max
        end

        def self.element_size(histogram, key)
          (((histogram[key] / histogram.map{|k,v| histogram[k]}.reduce(&:+).to_f) * 100) + 5).to_i
        end

        def self.element_heat(val, max)
          sprintf("%02x" % (200 - ((200.0 / max) * val)))
        end

      end
    end
  end
end
