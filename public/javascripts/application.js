/* NOTE: このファイルを変更したらcache_default.jsも更新すること！！ */
var Mars = {
  window_options: {
    width: 560,
    height: 520,
    resizable: 'yes',
    scrollbars: 'yes',
    status: 'yes',
    menubar: 'no',
    toolbar: 'no',
    location: 'yes',
    directories: 'no'
  },

  cookie: {
    path : "/",
    days : 2
  },

  ajax_request_safe_double_click : function(button, url, opts) {
    var extend_options = {
      onComplete : function(){
        $(button).disabled = false;
      }
    };
    var options = Object.extend(extend_options, opts || {});

    $(button).disabled = "disabled";
    Mars.ajax_request(url, options);
  },

  ajax_request : function(url, opts) {
    var extend_options = {
      method : 'get',
      anonymous : true,
      evalScripts : true
    };
    var options = Object.extend(extend_options, opts || {});
    new Ajax.Request(url, options);
  },

  home_search_submit : function(elm, path) {
    var form = $(elm).up("form");
    var keyword = form.down("input[name=keyword]").value;
    if (keyword) {
      form.action = path;
      form.submit();
      return true;
    }
    return false;
  },

  open_window: function(url, name, opts){
    var options =
      Object.extend(Object.clone(Mars.window_options), opts || {});
    options = $H(options).map(function(elm){ return elm.join('=');}).join(',');
    window.open(url, name, options).focus();
  },

  window_close: function() {
    if(Mars.window_exist()) {
      window.opener.focus();
    }
    window.close();
  },

  window_exist: function() {
    return (window.opener && !window.opener.closed);
  },

  /* inspired by http://insomnia.jp/workshop/fontsize_changer_C/fscC.js */
  set_cookie: function(name, value, days) {
    var dobj = new Date();
    days = days || Mars.cookie.days;
    dobj.setTime(dobj.getTime() + 24 * 60 * 60 * days * 1000);
    var expiryDate = dobj.toGMTString();
    document.cookie = name + '=' + escape(value) + ';expires=' + expiryDate + ';path=' + Mars.cookie.path;
  },

  get_cookie: function(name) {
    var arg  = name + "=";
    var alen = arg.length;
    var clen = document.cookie.length;
    var i = 0;
    while (i < clen){
      var j = i + alen;
      if (document.cookie.substring(i, j) == arg)
        return Mars.get_cookie_val(j);
      i = document.cookie.indexOf(" ", i) + 1;
      if (i == 0) break;
    }
    return null;
  },

  get_cookie_val: function(offset) {
    var endstr = document.cookie.indexOf (";", offset);
    if (endstr == -1)
      endstr = document.cookie.length;
    return unescape(document.cookie.substring(offset,endstr));
  },

  delete_cookie: function(name) {
    if (Mars.get_cookie(name)){
      document.cookie = name + '=' +
        '; expires=Thu, 01-Jan-70 00:00:01 GMT;path='+Mars.cookie.path;
    }
  }
};

/* shows and hides ajax indicator(by redmine) */
Ajax.Responders.register({
    onCreate: function(){
        if ($('ajax-indicator') && Ajax.activeRequestCount > 0) {
            Element.show('ajax-indicator');
        }
    },
    onComplete: function(){
        if ($('ajax-indicator') && Ajax.activeRequestCount == 0) {
            Element.hide('ajax-indicator');
        }
    }
});
