/* NOTE: このファイルを変更したらcache_default.jsも更新すること！！ */
var FontSize = {
  default_size : 12,
  cookie_key : "font_size_change",
  change_value : null,
  current_size : null
};

FontSize.change_value = Mars.get_cookie(FontSize.cookie_key);
if (FontSize.change_value == null){
  FontSize.current_size = FontSize.default_size;
}
else{
  FontSize.current_size = FontSize.change_value;
}

document.writeln('<style type="text/css">');
document.write('body{font-size:' + FontSize.current_size + 'px;}');
document.write('td{font-size:' + FontSize.current_size + 'px;}');
document.writeln('</style>');

function font_size_change(cmd){
  switch(cmd){
  case "larger":
    Mars.set_cookie(FontSize.cookie_key, Number(FontSize.current_size) + 2);
    break;
  case "smaller":
    if(Number(FontSize.current_size) != 2)
      Mars.set_cookie(FontSize.cookie_key, Number(FontSize.current_size) - 2);
    break;
  case "default":
    Mars.delete_cookie(FontSize.cookie_key);
    break;
  }
  location.reload();
}
