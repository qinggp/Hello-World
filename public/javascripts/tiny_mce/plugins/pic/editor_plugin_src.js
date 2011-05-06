/**
 * $RCSfile: editor_plugin.js,v $
 * $Revision: 1.00 $
 * $Date: 2007/06/29 $
 */

/* Import plugin specific language pack */
//tinyMCE.importPluginLanguagePack('pic', 'en,tr,de,sv,zh_cn,cs,fa,fr_ca,fr,pl,pt_br,nl,da,he,nb,hu,ru,ru_KOI8-R,ru_UTF-8,nn,es,cy,is,zh_tw,zh_tw_utf8,sk,pt_br');
tinyMCE.importPluginLanguagePack('pic', 'ja');

var TinyMCE_PicPlugin = {
	getInfo : function() {
		return {
			longname : 'Pic',
			author : 'InfoMeMe',
			authorurl : '',
			infourl : '',
			version : "1.0"
		};
	},

	initInstance : function(inst) {
		if (!tinyMCE.settings['pic_skip_plugin_css'])
			tinyMCE.importCSS(inst.getDoc(), tinyMCE.baseURL + "/plugins/pic/css/content.css");
	},

	getControlHTML : function(cn) {
		switch (cn) {
			case "pic":
				return tinyMCE.getButtonHTML(cn, 'lang_pic_desc', tinyMCE.baseURL + '/themes/advanced/images/image.gif', 'mcePic');
		}

		return "";
	},

	execCommand : function(editor_id, element, command, user_interface, value) {
		// Handle commands
		switch (command) {
			case "mcePic":
				var name = "", swffile = "", swfwidth = "100", swfheight = "100", action = "insert";
				var template = new Array();
				var inst = tinyMCE.getInstanceById(editor_id);
				var focusElm = inst.getFocusElement();

				template['file']   = '../../plugins/pic/pic.htm'; // Relative to theme
				template['width']  = 430;
				template['height'] = 120;

				template['width'] += tinyMCE.getLang('lang_Pic_delta_width', 0);
				template['height'] += tinyMCE.getLang('lang_Pic_delta_height', 0);

				// Is selection a image
				if (focusElm != null && focusElm.nodeName.toLowerCase() == "img") {
					name = tinyMCE.getAttrib(focusElm, 'class');

					if (name.indexOf('mceItemPic') == -1) // Not a Flash
						return true;

					// Get rest of Flash items
					swffile = tinyMCE.getAttrib(focusElm, 'alt');

					if (tinyMCE.getParam('convert_urls'))
						swffile = eval(tinyMCE.settings['urlconverter_callback'] + "(swffile, null, true);");

					swfwidth = tinyMCE.getAttrib(focusElm, 'width');
					swfheight = tinyMCE.getAttrib(focusElm, 'height');
					action = "update";
				}

				tinyMCE.openWindow(template, {editor_id : editor_id, inline : "yes", swffile : swffile, swfwidth : swfwidth, swfheight : swfheight, action : action});
			return true;
	   }

	   // Pass to next handler in chain
	   return false;
	},

	cleanup : function(type, content) {
		switch (type) {
			case "insert_to_editor_dom":
				// Force relative/absolute
				if (tinyMCE.getParam('convert_urls')) {
					var imgs = content.getElementsByTagName("img");
					for (var i=0; i<imgs.length; i++) {
//						if (tinyMCE.getAttrib(imgs[i], "class") == "mceItemPic") {
						if (tinyMCE.getAttrib(imgs[i], "class") == "mceItemPic1" || tinyMCE.getAttrib(imgs[i], "class") == "mceItemPic2" || tinyMCE.getAttrib(imgs[i], "class") == "mceItemPic3") {
							var src = tinyMCE.getAttrib(imgs[i], "alt");

							if (tinyMCE.getParam('convert_urls'))
								src = eval(tinyMCE.settings['urlconverter_callback'] + "(src, null, true);");

							imgs[i].setAttribute('alt', src);
							imgs[i].setAttribute('title', src);
						}
					}
				}
				break;

			case "get_from_editor_dom":
				var imgs = content.getElementsByTagName("img");
				for (var i=0; i<imgs.length; i++) {
//					if (tinyMCE.getAttrib(imgs[i], "class") == "mceItemPic") {
					if (tinyMCE.getAttrib(imgs[i], "class") == "mceItemPic1" || tinyMCE.getAttrib(imgs[i], "class") == "mceItemPic2" || tinyMCE.getAttrib(imgs[i], "class") == "mceItemPic3") {
						var src = tinyMCE.getAttrib(imgs[i], "alt");

						if (tinyMCE.getParam('convert_urls'))
							src = eval(tinyMCE.settings['urlconverter_callback'] + "(src, null, true);");

						imgs[i].setAttribute('alt', src);
						imgs[i].setAttribute('title', src);
					}
				}
				break;

			case "insert_to_editor":
				var startPos = 0;
				var embedList = new Array();

				// Parse all embed tags
				while ((startPos = content.indexOf('<PIC', startPos+1)) != -1) {
					var endPos = content.indexOf('>', startPos);
					var attribs = TinyMCE_PicPlugin._parseAttributes(content.substring(startPos + 5, endPos));
					embedList[embedList.length] = attribs;
				}

				// Parse all object tags and replace them with images from the embed data
				var index = 0;
				while ((startPos = content.indexOf('<PIC', startPos)) != -1) {
					if (index >= embedList.length)
						break;

					var attribs = embedList[index];
					// Find end of object
					endPos = content.indexOf('>', startPos);
					endPos += 1;

					// Insert image
					var contentAfter = content.substring(endPos);
					content = content.substring(0, startPos);
					content += '<img width="100" height="100"';
					content += ' src="' + (tinyMCE.getParam("theme_href") + '/images/spacer.gif') + '" title="' + attribs["no"] + '"';
					content += ' alt="' + attribs["no"] + '" class="mceItemPic'+attribs["no"]+'" />';
					content += contentAfter;
					index++;

					startPos++;
				}
				break;

			case "get_from_editor":
				// Parse all img tags and replace them with object+embed
				var startPos = -1;

				while ((startPos = content.indexOf('<img', startPos+1)) != -1) {
					var endPos = content.indexOf('/>', startPos);
					var attribs = TinyMCE_PicPlugin._parseAttributes(content.substring(startPos + 4, endPos));

					// Is not pic, skip it
//					if (attribs['class'] != "mceItemPic")
					if (!(attribs['class'] == "mceItemPic1" || attribs['class'] == "mceItemPic2" || attribs['class'] == "mceItemPic3"))
						continue;

					endPos += 2;

					var embedHTML = '';
					var wmode = tinyMCE.getParam("pic_wmode", "");
					var quality = tinyMCE.getParam("pic_quality", "high");
					var menu = tinyMCE.getParam("pic_menu", "false");

					// Insert object + embed
					var src = attribs["title"];
					var flash_mov = "";

					embedHTML += '<PIC no="' + src + '">';

					// Insert embed/object chunk
					chunkBefore = content.substring(0, startPos);
					chunkAfter = content.substring(endPos);
					content = chunkBefore + embedHTML + chunkAfter;
				}
				break;
		}

		// Pass through to next handler in chain
		return content;
	},

	handleNodeChange : function(editor_id, node, undo_index, undo_levels, visual_aid, any_selection) {
		if (node == null)
			return;

		do {
//			if (node.nodeName == "IMG" && tinyMCE.getAttrib(node, 'class').indexOf('mceItemPic') == 0) {
			if (node.nodeName == "IMG" && (tinyMCE.getAttrib(node, 'class').indexOf('mceItemPic1') == 0 || tinyMCE.getAttrib(node, 'class').indexOf('mceItemPic2') == 0 || tinyMCE.getAttrib(node, 'class').indexOf('mceItemPic3') == 0)) {
				tinyMCE.switchClass(editor_id + '_pic', 'mceButtonSelected');
				return true;
			}
		} while ((node = node.parentNode));

		tinyMCE.switchClass(editor_id + '_pic', 'mceButtonNormal');

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

tinyMCE.addPlugin("pic", TinyMCE_PicPlugin);
