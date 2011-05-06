/*
 * GoogleMapから位置を選択
 *
 * NOTE: 座標等の入力フォームのIDをそれぞれ以下の通りにすること。
 *  - latitude
 *  - longitude
 *  - zoom
 */
GMapSelector = {
  map : null,
  geocoder : null,

  /**
   * グーグルマップの初期化
   */
  maps_load : function(){
    var map = new GMap2($("map"));
    map.addControl(new GLargeMapControl());
    map.addControl(new GScaleControl());

    var lat  = $('lat').value;
    var lng  = $('lng').value;
    var zoom = parseInt($('zoom').value);

    map.setCenter(new GLatLng(lat, lng), zoom);

    GEvent.addListener(map, 'move', function(){
                         var center = map.getCenter();
                         $('lat').value = center.lat().toFixed(6);
                         $('lng').value = center.lng().toFixed(6);
                         $('zoom').value = map.getZoom();
                       });

    GEvent.addListener(map, 'moveend', function(){
                         marker = new GMarker(map.getCenter());
                         map.clearOverlays();
                         map.addOverlay(marker);
                       });

    GEvent.addListener(map, "zoomend", function(){
                         $('zoom').value = map.getZoom();
                       });

    if (lng > 0 && lat > 0) {
      marker = new GMarker(map.getCenter());
      map.addOverlay(marker);
    }
    GMapSelector.map = map;
    GMapSelector.geocoder = new GClientGeocoder();
  },

  /**
   * 座標値をクリアする
   */
  clear_coordinate_values : function(){
    $('latitude').value = '';
    $('longitude').value = '';
    $('zoom').value = '';
  },

  /**
   * 座標選択用のウィンドウを開く
   */
  open_map_window : function(url, name){
    // フォーム値を元に座標を指定
    var latitude = $('latitude').value;
    var longitude = $('longitude').value;
    var zoom = $('zoom').value;
    // ウィンドウを開く
    var opts = {"width" : 500, "height" : 400, "top" : 100, "left" : 450, "scrollbars" : "no"};
    url = url + "?latitude=" + latitude + "&longitude=" + longitude + "&zoom=" + zoom;
    Mars.open_window(url, name, opts);
  },

  /**
   * 座標選択ウィンドウの "座標値送信" ボタンをクリックされたときの動作
   */
  send_coordinate_values : function(){
    window.opener.$('latitude').value = $('lat').value;
    window.opener.$('longitude').value = $('lng').value;
    window.opener.$('zoom').value = $('zoom').value;
    Mars.window_close();
  },

  geocoding : function(address){
    $('choice_list').style.display = 'none';
    GMapSelector.geocoder.getLocations(address, GMapSelector.goto_address);
  },

  goto_address : function(AddressData){
    if (AddressData.Status.code != 200) { return; }

    var choice_str = "";
    if (AddressData.Placemark.length == 1) {
      if ($('zoom').value) {
        var zoom = $('zoom').value;
      } else {
        var zoom = 12;
      }

      var lat = parseFloat(AddressData.Placemark[0].Point.coordinates[1]);
      var lng = parseFloat(AddressData.Placemark[0].Point.coordinates[0]);
      var marker = new GLatLng(lat, lng);
      GMapSelector.map.setCenter(marker, zoom);
    } else if (AddressData.Placemark.length > 1) {
      for (var i = 0; i < AddressData.Placemark.length; i++) {
        address = AddressData.Placemark[i].address.replace('（日本）', '');
        choice_str += ('<a href="javascript:GMapSelector.choice_add(\'' +address + '\');">'+address+'</a> ');
      }
      $('choice_list').style.display = '';
      $('choice_list').innerHTML = '選択→ ' + choice_str;
    }
  },

  choice_add : function(choice_tmp){
    $('address').value = choice_tmp;
    $('choice_list').innerHTML = '';
    $('choice_list').style.display = 'none';
    GMapSelector.geocoding(choice_tmp);
  }

};
