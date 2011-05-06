var CommunityMapMarker = Class.create();

CommunityMapMarker.prototype = Object.extend(new GMapMarker(),
  {
    icon : null,
    category : null,

   /*
   * セットアップに必要な情報を渡す。
   */
    initialize : function(point, info, category){
      this.category = category
      this.point = point;
      this.info = info;
      this.icon = new GIcon()
      this.icon.image = "/themes/mars/images/marker_" + (this.category % 10) + ".png";
      this.icon.shadow = "/themes/mars/images/marker_shadow.png";
      this.icon.iconSize = new GSize(18, 30);
      this.icon.shadowSize = new GSize(30, 30);
      this.icon.iconAnchor = new GPoint(8,30);
      this.icon.infoWindowAnchor = new GPoint(8, 0);
    },

    mark : function(){
      if (this.marker != null) {
        GMapViewer.map.removeOverlay(this.marker);
        this.marker = null;
      }
      this.marker = new GMarker(this.point, this.icon);
      this.marker.info = this.info;
      GMapViewer.map.addOverlay(this.marker);
      this.marker_setup();
    },

    marker_setup : function(){
      // クリックされた詳細情報を表示する吹き出しを開く
      GEvent.addListener(this.marker, "click", function(){
        marker = this.info;
        message = '<div style="text-align: left; font-weight: bold;">' + marker.title_link + '</div>';
        message += '<div style="text-align: left; margin: 3px 0px 3px 12px; font-size: 10px;">' + 'カテゴリ：' + marker.category_name + '</div>';
        message += '<div style="text-align: left; height: auto;">' + marker.body + '</div>';
        message += '<div style="text-align:right; margin-top: 5px;">' + '[  ' + marker.reply + '  ]' + '</div>';
        GMapViewer.map.setCenter(marker.point, marker.zoom);
        this.openInfoWindow(message);
      });
    },
  }
);

CommunityMarker = {
  category_switch : function(id, action){
    var displayed_types = new Array(2);
    displayed_types[0] = 'right';
    displayed_types[1] = 'bottom';

    if(action == 'ON') {
      for(i = 0; i < displayed_types.length; i++){
        document.getElementById('category_off_' + id + '_' + displayed_types[i]).style.display = 'none';
        document.getElementById('category_on_' + id + '_' + displayed_types[i]).style.display = '';
      }
      document.getElementById('category_' + id).style.display = '';
      for(i = 0; i < GMapViewer.markers.length; i++){
        if(GMapViewer.markers[i].category == id){
          GMapViewer.markers[i].mark();
        }
      }
    }
    else if(action == 'OFF') {
      for(i = 0; i < displayed_types.length; i++){
        document.getElementById('category_off_' + id + '_' + displayed_types[i]).style.display = '';
        document.getElementById('category_on_' + id + '_' + displayed_types[i]).style.display = 'none';
      }
      document.getElementById('category_' + id).style.display = 'none';
      for(i = 0; i < GMapViewer.markers.length; i++){
        if(GMapViewer.markers[i].category == id){
          GMapViewer.markers[i].remove();
        }
      }
    }
  }
}
