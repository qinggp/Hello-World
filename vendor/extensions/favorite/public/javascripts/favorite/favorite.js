Favorite = {
  allCheck: function() {
    var checked = $("check_all").checked;
    $$('input[name="checked_ids[]"]').each(function(elm){
      elm.checked = checked;
    });
  }
};