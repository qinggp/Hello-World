/**
 * $RCSfile: editor_plugin.js,v $
 * $Revision: 1.00 $
 * $Date: 2007/06/28 $
 */

/* Import plugin specific language pack */
//tinyMCE.importPluginLanguagePack('File', 'en,tr,de,sv,zh_cn,cs,fa,fr_ca,fr,pl,pt_br,nl,da,he,nb,hu,ru,ru_KOI8-R,ru_UTF-8,nn,es,cy,is,zh_tw,zh_tw_utf8,sk,pt_br');
tinyMCE.importPluginLanguagePack('file', 'ja,en');

var TinyMCE_FilePlugin = {
	getInfo : function() {
		return {
			longname : 'fileBrowser',
			author : 'InfoMeMe',
			authorurl : '',
			infourl : '',
			version : "1.0"
		};
	},

	initInstance : function(inst) {
		if (!tinyMCE.settings['Test_skip_plugin_css'])
			tinyMCE.importCSS(inst.getDoc(), tinyMCE.baseURL + "/plugins/Test/css/content.css");
	},

	getControlHTML : function(cn) {
		switch (cn) {
			case "file":
				return tinyMCE.getButtonHTML(cn, 'lang_file_desc', tinyMCE.baseURL + '/themes/advanced/images/image.gif', 'mceFile');
		}

		return "";
	},

	execCommand : function(editor_id, element, command, user_interface, value) {
		// Handle commands
		switch (command) {
			case "mceFile":
				var name = "", swffile = "", swfwidth = "100", swfheight = "100", action = "insert";
				var template = new Array();
				var inst = tinyMCE.getInstanceById(editor_id);
				var focusElm = inst.getFocusElement();

				template['file']   = '../../../fileBrowser/fileBrowser.php?type=image'; // Relative to theme
				template['width']  = 580;
				template['height'] = 400;

				template['width'] += tinyMCE.getLang('lang_file_delta_width', 0);
				template['height'] += tinyMCE.getLang('lang_file_delta_height', 0);

				// Is selection a image
				if (focusElm != null && focusElm.nodeName.toLowerCase() == "img") {
					name = tinyMCE.getAttrib(focusElm, 'class');

					if (name.indexOf('mceItemFile') == -1) // Not a Flash
						return true;

					// Get rest of Flash items
					swffile = tinyMCE.getAttrib(focusElm, 'alt');

					if (tinyMCE.getParam('convert_urls'))
						swffile = eval(tinyMCE.settings['urlconverter_callback'] + "(swffile, null, true);");

					swfwidth = tinyMCE.getAttrib(focusElm, 'width');
					swfheight = tinyMCE.getAttrib(focusElm, 'height');
					action = "update";
				}

				tinyMCE.openWindow(template, {editor_id : editor_id, resizable : 'yes', inline : "yes", swffile : swffile, swfwidth : swfwidth, swfheight : swfheight, action : action});
			return true;
	   }

	   // Pass to next handler in chain
	   return false;
	},

	handleNodeChange : function(editor_id, node, undo_index, undo_levels, visual_aid, any_selection) {
		if (node == null)
			return;

		do {
			if (node.nodeName == "IMG" && tinyMCE.getAttrib(node, 'class').indexOf('mceItemFile') == 0) {
				tinyMCE.switchClass(editor_id + '_file', 'mceButtonSelected');
				return true;
			}
		} while ((node = node.parentNode));

		tinyMCE.switchClass(editor_id + '_file', 'mceButtonNormal');

		return true;
	},

	// Private plugin internal functions

	_parseAttributes : function(attribute_string) {
		var attributeName = "";
		var attributeValue = "";
		var withInName;
		var withInValue;
		var attributes = new Array();
		var whiteSpaceRegExp = new RegExp('^[ \n\r\t]+', 'g');

		if (attribute_string == null || attribute_string.length < 2)
			return null;

		withInName = withInValue = false;

		for (var i=0; i<attribute_string.length; i++) {
			var chr = attribute_string.charAt(i);

			if ((chr == '"' || chr == "'") && !withInValue)
				withInValue = true;
			else if ((chr == '"' || chr == "'") && withInValue) {
				withInValue = false;

				var pos = attributeName.lastIndexOf(' ');
				if (pos != -1)
					attributeName = attributeName.substring(pos+1);

				attributes[attributeName.toLowerCase()] = attributeValue.substring(1);

				attributeName = "";
				attributeValue = "";
			} else if (!whiteSpaceRegExp.test(chr) && !withInName && !withInValue)
				withInName = true;

			if (chr == '=' && withInName)
				withInName = false;

			if (withInName)
				attributeName += chr;

			if (withInValue)
				attributeValue += chr;
		}

		return attributes;
	}
};

tinyMCE.addPlugin("file", TinyMCE_FilePlugin);
