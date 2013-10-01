require "test_config"
require "iruby/output/html"
class TestOutputMaps < Minitest::Unit::TestCase
  def test_heatmap
    points=[
      OpenStruct.new({lat: 33.1, lon: 34.1}), 
      OpenStruct.new({lat: 33.2, lon: 34.2}), 
      OpenStruct.new({lat: 33.3, lon: 34.3}), 
    ]
   expected = <<Z
<div id='map-canvas' style='width: 500px; height: 500px;'></div>
<script src=\"https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false&libraries=visualization&callback=initialize\"></script>

<script>
  function initialize() {
    var latlngbounds = new google.maps.LatLngBounds();
    var zoom = null;
    var center = null;
    var map_type = null || google.maps.MapTypeId.SATELLITE;

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

    var points = [{location: new google.maps.LatLng(33.1, 34.1)},{location: new google.maps.LatLng(33.2, 34.2)},{location: new google.maps.LatLng(33.3, 34.3)}];
    if (! zoom){
      for (var i = 0; i < points.length; i++) {
        latlngbounds.extend(points[i].location);
     }
     map.fitBounds(latlngbounds);
    }


    var pointArray = new google.maps.MVCArray(points);

    heatmap = new google.maps.visualization.HeatmapLayer({
      radius: null || 10,
      data: pointArray
    });

    heatmap.setMap(map);

  }
</script>
Z
    assert_equal expected.strip, IRuby::Output::HTML::Gmaps.heatmap(points: points).strip
  end
  def test_markers
    points=[
      OpenStruct.new({lat: 33.1, lon: 34.1, label: "f1"}), 
      OpenStruct.new({lat: 33.2, lon: 34.2, label: "f2"}), 
      OpenStruct.new({lat: 33.3, lon: 34.3, label: "f3"}), 
    ]
   expected = <<Z
<div id='map-canvas' style='width: 500px; height: 500px;'></div>
<script src=\"https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false&libraries=visualization&callback=initialize\"></script>

<script>
  function initialize() {
    var latlngbounds = new google.maps.LatLngBounds();
    var zoom = null;
    var center = null;
    var map_type = null || google.maps.MapTypeId.SATELLITE;

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

    var points = [{location: new google.maps.LatLng(33.1, 34.1),label: "f1"},{location: new google.maps.LatLng(33.2, 34.2),label: "f2"},{location: new google.maps.LatLng(33.3, 34.3),label: "f3"} ];
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
          title: points[i].label
      });
    }


  }
</script>
Z
    assert_equal expected.strip, IRuby::Output::HTML::Gmaps.markers(points: points).strip
  end

end
