var MovieMarker = Class.create();

MovieMarker.prototype = Object.extend(new GMapMarker(),
  {
    marker_setup : function(){
      // クリックされた詳細情報を表示する吹き出しを開く
      GEvent.addListener(this.marker, "click", function(){
                           movie = this.info;
                           message = '<h2>' + movie.title + '</h2>';
                           message += '<div style="width: 200px;">';
                           message += movie.body;
                           message += '</div>';
                           message += '<div style="text-align:right;">';
                           message += '<a href="' + movie.link_to + '">ムービーを見る</a>';
                           message += '</div>';
                           GMapViewer.map.setCenter(movie.point, movie.zoom);
                           this.openInfoWindow(message);
                         });
    }
  }
);