CommunityLinkage = {
    allCheck: function() {
    var checked = $("check_all").checked;
    $$('input[name="community_linkage_ids[]"]').each(function(elm){
      elm.checked = checked;
    });
  }
};
