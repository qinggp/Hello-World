Message = {
  allCheck: function() {
    var checked = $("check_all").checked;
    $$('input[name="receiver_ids[]"]').each(function(elm){
      elm.checked = checked;
    });
  },

  clearSubmit: function() {
    $("input_info_clear").click();
  }
};
