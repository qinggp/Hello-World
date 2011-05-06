function init() {
	tinyMCEPopup.resizeToInnerSize();
	var formObj = document.forms[0];
	var swffile   = tinyMCE.getWindowArg('swffile');

	if(swffile){
		formObj.file.options[swffile-1].selected = true;
	}else{
		formObj.file.options[0].selected = true;
	}
	formObj.insert.value = tinyMCE.getLang('lang_' + tinyMCE.getWindowArg('action'), 'Insert', true);
}
function insertTest() {
	var formObj = document.forms[0];
	var html      = '';
	var file      = formObj.file.value;
	var width     = 100;
	var height    = 100;

	html += ''
		+ '<img src="' + (tinyMCE.getParam("theme_href") + "/images/spacer.gif") + '" mce_src="' + (tinyMCE.getParam("theme_href") + "/images/spacer.gif") + '" '
		+ 'width="' + width + '" height="' + height + '" '
		+ 'border="0" alt="' + file + '" title="' + file + '" class="mceItemTest" />';

	tinyMCEPopup.execCommand("mceInsertContent", true, html);
	tinyMCE.selectedInstance.repaint();

	tinyMCEPopup.close();
}
