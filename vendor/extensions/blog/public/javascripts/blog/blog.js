Blog = {
  allCheck: function() {
    var checked = $("check_all").checked;
    $$('input[name="checked_ids[]"]').each(function(elm){
      elm.checked = checked;
    });
  },

  clearSubmit: function() {
    $("input_info_clear").click();
  },

  nowTime: function() {
    var now = new Date();
    $("blog_entry_created_at_1i").value = now.getUTCFullYear();
    $("blog_entry_created_at_2i").value = now.getMonth()+1;
    $("blog_entry_created_at_3i").value = now.getDate();
    hours = now.getHours();
    $("blog_entry_created_at_4i").value = hours < 10 ? "0" + hours : hours;
    minutes = now.getMinutes();
    $("blog_entry_created_at_5i").value = minutes < 10 ? "0" + minutes : minutes;
  },

  addTag: function(id, tag) {
    var data = $(id).value;
    if(data.length > 0){ CrLf = "\n"; }else{ CrLf = ''; }
    $(id).value = data + CrLf + tag;
  }
};
