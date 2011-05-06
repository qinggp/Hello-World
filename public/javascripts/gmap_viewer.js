/*
 * GoogleMapのマーカ表示
 */
GMapViewer = {
  map : null,
  geocoder : null,
  coordinates : null,
  markers : [],

  /* マップの初期化 */
  maps_load : function(id, options) {
    var target_id = id || "map";
    GMapViewer.coordinates = options || {latitude : 1, longitude : 1, zoom : 2};
    var map = new GMap2($(target_id));
    map.addControl(new GLargeMapControl());
    map.addControl(new GScaleControl());
    map.addControl(new GOverviewMapControl(new GSize(100, 100)));
    map.addControl(new GMapTypeControl());

    map.setCenter(GMapViewer.get_default_center(),
                  GMapViewer.get_default_zoom());
    GMapViewer.map = map;
    GMapViewer.load_markers();
    GMapViewer.geocoder = new GClientGeocoder();
  },

  /* マップ初期化（表示用）*/
  maps_load_for_view : function(id, options) {
    var target_id = id || "map";
    GMapViewer.coordinates = options || {latitude : 1, longitude : 1, zoom : 2};
    var map = new GMap2($(target_id));
    map.addControl(new GLargeMapControl());
    map.addControl(new GScaleControl());

    map.setCenter(GMapViewer.get_default_center(),
                  GMapViewer.get_default_zoom());
    GMapViewer.map = map;
    GMapViewer.load_markers();
  },

  get_default_center : function(latitude, longitude) {
    return new GLatLng(GMapViewer.coordinates.latitude,
                       GMapViewer.coordinates.longitude);
  },

  get_default_zoom : function() {
    return GMapViewer.coordinates.zoom;
  },

  load_markers : function(){
    for (var i = 0; i < GMapViewer.markers.length; i++) {
        GMapViewer.markers[i].mark();
    }
  },

  /* Markerクラスのidを指定すると対応するマーカの吹き出しが表示される */
  open_info_window : function(id){
    for (var i = 0; i < GMapViewer.markers.length; i++) {
      if (GMapViewer.markers[i].info.id == id) {
        GEvent.trigger(GMapViewer.markers[i].marker, 'click');
      }
    }
  }
};

/*
 * マーカ親クラス
 * 継承して使用すること
 * 例 : var MovieMarker = Class.create();
 *      MovieMarker.prototype = Object.extend(new GMapMarker(),
 *        {
 *          marker_setup : function(){ ... };
 *        }
 *      );
 */
var GMapMarker = Class.create();

GMapMarker.prototype = {
  marker : null,
  info : null,
  point : null,

  /*
   * セットアップに必要な情報を渡す。
   */
  initialize : function(point, info){
    this.point = point;
    this.info = info;
  },

  mark : function(){
    if (this.marker != null) {
      GMapViewer.map.removeOverlay(this.marker);
      this.marker = null;
    }
    this.marker = new GMarker(this.point);
    this.marker.info = this.info;
    GMapViewer.map.addOverlay(this.marker);
    this.marker_setup();
  },

  remove : function(){
    GMapViewer.map.removeOverlay(this.marker);
    GMapViewer.map.closeInfoWindow();
  }
};