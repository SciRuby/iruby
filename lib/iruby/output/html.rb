require "json"
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
        elsif d.first.respond_to?(:keys) # array of hashes
          columns = d.first.keys
          r << "<tr>#{columns.map{|c| "<th>#{c.to_s}</th>"}.join}</tr>"
        else # array
          columns = (0 .. d.first.length)
        end
        d.each{|row|
          r << "<tr>"
          columns.each{|column|
            r << "<td>#{row[column].to_s}</td>"
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
          label = data[0].strip
          label = "?" if label == ''
          g.data(label, data[1])
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
            icon_url = nil
            icon_url = p.icon_url if p.respond_to?(:icon_url)
            icon_url = "http://www.google.com/intl/en_us/mapfiles/ms/micons/#{p.icon}-dot.png"if p.respond_to?(:icon)
            "{" + [ 
              "location: new google.maps.LatLng(#{p.lat.to_f}, #{p.lon.to_f})",
               p.respond_to?(:weight) && p.weight && "weight: #{p.weight.to_i} ",
               p.respond_to?(:label)  && "label: #{p.label.to_s.to_json}",
               p.respond_to?(:z_index)  && "z_index: #{p.z_index.to_json}",
               icon_url  && "icon_url: #{icon_url.to_json}",
            ].reject{|x| ! x}
             .join(",") + "}"
          }.join(',') + "]"
        end
        def self.base_map(o)
          zoom = o.delete(:zoom)
          center = o.delete(:center)
          map_type = o.delete(:map_type)
          width = o.delete(:width) || "500px"
          height = o.delete(:height) || "500px"
r = <<E
<div id='map-canvas' style='width: #{width}; height: #{height};'></div>
<script src="https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false&libraries=visualization&callback=initialize"></script>

<script>
  function initialize() {
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

#{yield}
  }
</script>
E
        r

        end
        def self.heatmap(o)
          data = o.delete(:points)
          points = points2latlng(data)
          radius = o.delete(:radius)
          raise "Missing :points parameter" if not data
          base_map(o){<<E
    var points = #{points};
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
E
          }

        end
        def self.markers(o)
          data = o.delete(:points)
          points = points2latlng(data)
          radius = o.delete(:radius)
          raise "Missing :points parameter" if not data
          base_map(o){<<E
    var points = #{points};
    if (! zoom){
      for (var i = 0; i < points.length; i++) {
        latlngbounds.extend(points[i].location);
     }
     map.fitBounds(latlngbounds);
    }

    for (var i=0; i<points.length; i++){
       var marker = new google.maps.Marker({
          position: points[i].location,
          map: map,
          icon: points[i].icon_url,
          zIndex: points[i].z_index,
          title: points[i].label
      });
    }

E
          }

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
