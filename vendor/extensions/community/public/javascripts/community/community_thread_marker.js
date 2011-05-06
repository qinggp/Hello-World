var CommunityThreadMarker = Class.create();

CommunityThreadMarker.prototype = Object.extend(new GMapMarker(),
  {
    marker_setup : function(){
      // クリックされた詳細情報を表示する吹き出しを開く
      GEvent.addListener(this.marker, "click", function(){
                           entry = this.info;
                           message = '<div>' + entry.title_link + '</div>';
                           message += '<div style="text-align:right">' + entry.date + '</div>';
                           message += '<div sytle="height: auto;">' + entry.body + '</div>';
                           GMapViewer.map.setCenter(entry.point, entry.zoom);
                           this.openInfoWindow(message);
                         });
    }
  }
);