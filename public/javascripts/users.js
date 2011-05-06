Users = {
  select_prepare_face: function(id) {
    if(Mars.window_exist()) {
      var selects = window.opener.$("select_prepared_photo");
      $A(selects.options).each(function(elm){ elm.selected = false; });
      $A(selects.options).each(function(elm){ if(elm.value == id) elm.selected = true; });
      Mars.window_close();
    }
  },

  select_jp_address: function(id, city, town) {
    if(Mars.window_exist()) {
      var selects = window.opener.$("select_now_prefecture");
      $A(selects.options).each(function(elm){ elm.selected = false; });
      $A(selects.options).each(function(elm){ if(elm.value == id) elm.selected = true; });
      window.opener.$("now_city").value = city;
      window.opener.$("now_street").value = town;
      Mars.window_close();
    }
  },

  nickname_unique_check: function(url, name) {
    Mars.ajax_request(url, {parameters : "name=" + name});
  },

  box_open: function(id) {
    $(id).style.display = '';
    $(id+'_open').style.display = 'none';
    $(id+'_close').style.display = '';
    Mars.delete_cookie(id);
  },

  box_close: function(id) {
    $(id).style.display = 'none';
    $(id+'_open').style.display = '';
    $(id+'_close').style.display = 'none';
    Mars.set_cookie(id, '1');
  },

  set_cookie_for_news_show_options: function(id) {
    Mars.set_cookie(id, $(id).value, 30);
    location.reload();
  }
};
