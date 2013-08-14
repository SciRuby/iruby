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

        klass = o.delete(:stacked) ? Gruff::StackedBar : Gruff::Bar
        g = klass.new(size)

        if labels=o.delete(:labels)
          if ! labels.respond_to?(:keys)
            labels = Hash[labels.map.with_index{|v,k| [k,v]}]
          end
          g.labels = labels
        end

        g.title = title if title
        data.each do |data|
          g.data(data[0], data[1])
        end
        image(g.to_blob)

      end

      module Gmaps
        def self.points2latlng(points)
          "[" + points.reject{|p| not p.lat or not p.lon}.map{|p| 
            "  {location: new google.maps.LatLng(#{p.lat.to_f}, #{p.lon.to_f}) #{", weight: #{p.weight.to_i}" if p.respond_to?(:weight) and p.weight} } "
          }.join(',') + "]"
        end
        def self.heatmap(o)
          data = o.delete(:points)
          raise "Missing :points parameter" if not data

          points = points2latlng(data)
          zoom = o.delete(:zoom)
          center = o.delete(:center)
          map_type = o.delete(:map_type)
          radius = o.delete(:radius)
r = <<E
<div id='map-canvas' style='width: 500px; height: 500px;'></div>
<script src="https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false&libraries=visualization&callback=initialize"></script>

<script>
  function initialize() {
    var points = #{points};
    var latlngbounds = new google.maps.LatLngBounds();
    var zoom = #{zoom.to_json};
    var center = #{center.to_json};
    var map_type = #{map_type.to_json} || google.maps.MapTypeId.SATELLITE;

    var mapOptions = { 
      mapTypeId: map_type
    };

    if (zoom){
      mapOptions.zoom = zoom
    }
    if (center){
      mapOptions.center = new google.maps.LatLng(center.lat, center.lon)
    }

    map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);

    if (! zoom){
      for (var i = 0; i < points.length; i++) {
        latlngbounds.extend(points[i].location);
     }
     map.fitBounds(latlngbounds);
    }


    var pointArray = new google.maps.MVCArray(points);

    heatmap = new google.maps.visualization.HeatmapLayer({
      radius: #{radius.to_json} || 10,
      data: pointArray
    });

    heatmap.setMap(map);
  }
</script>
E
        STDERR.write("#{r}\n\n")
        r
        end
      end
      #stolen from https://github.com/Bantik/heatmap/blob/master/lib/heatmap.rb
      module WordCloud

        def self.wordcloud(histogram={})
          html = %{<div class="wordcloud">}
          histogram.keys.sort{|a,b| histogram[a] <=> histogram[b]}.reverse.each do |k|
            next if histogram[k] < 1
            _max = histogram_max(histogram) * 2
            _size = element_size(histogram, k)
            _heat = element_heat(histogram[k], _max)
            html << %{
        <span class="wordcloud_element" style="color: ##{_heat}#{_heat}#{_heat}; font-size: #{_size}px;">#{k}</span>
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
