function init() {
	tinyMCEPopup.resizeToInnerSize();
	var formObj = document.forms[0];
	var swffile   = tinyMCE.getWindowArg('swffile');

	if(swffile){
		//formObj.file.options[swffile-1].selected = true;
		formObj.file[swffile-1].checked = true;
	}else{
		//formObj.file.options[0].selected = true;
		formObj.file[0].checked = true;
	}

	formObj.insert.value = tinyMCE.getLang('lang_' + tinyMCE.getWindowArg('action'), 'Insert', true);
}
function insertPic() {
	var formObj = document.forms[0];
	var html      = '';
//	var file      = formObj.file.value;
	var width     = 100;
	var height    = 100;

	for (i=0;i<formObj.file.length;i++) {
		if(formObj.file[i].checked){
			file = formObj.file[i].value;
		}
	}

	html += ''
		+ '<img src="' + (tinyMCE.getParam("theme_href") + "/images/spacer.gif") + '" mce_src="' + (tinyMCE.getParam("theme_href") + "/images/spacer.gif") + '" '
		+ 'width="' + width + '" height="' + height + '" '
		+ 'border="0" alt="' + file + '" title="' + file + '" class="mceItemPic' + file + '" />';

	tinyMCEPopup.execCommand("mceInsertContent", true, html);
	tinyMCE.selectedInstance.repaint();

	tinyMCEPopup.close();
}
