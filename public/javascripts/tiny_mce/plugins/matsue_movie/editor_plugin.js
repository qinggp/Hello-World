/* Import plugin specific language pack */
//tinyMCE.importPluginLanguagePack('matsue_movie', 'en,tr,de,sv,zh_cn,cs,fa,fr_ca,fr,pl,pt_br,nl,da,he,nb,hu,ru,ru_KOI8-R,ru_UTF-8,nn,es,cy,is,zh_tw,zh_tw_utf8,sk,pt_br');
tinyMCE.importPluginLanguagePack('matsue_movie', 'ja,en,nl');

var TinyMCE_MatsueMoviePlugin = {
	getInfo : function() {
		return {
			longname : 'MatsueMovie',
			author : '',
			authorurl : '',
			infourl : '',
			version : "1.0"
		};
	},

	initInstance : function(inst) {
		if (!tinyMCE.settings['matsue_movie_skip_plugin_css'])
			tinyMCE.importCSS(inst.getDoc(), tinyMCE.baseURL + "/plugins/matsue_movie/css/content.css");
	},

	getControlHTML : function(cn) {
		switch (cn) {
			case "matsue_movie":
				return tinyMCE.getButtonHTML(cn, 'lang_matsue_movie_desc', '{$pluginurl}/images/matsue_movie.gif', 'mceMatsueMovie');
		}

		return "";
	},

	execCommand : function(editor_id, element, command, user_interface, value) {
		// Handle commands
		switch (command) {
			case "mceMatsueMovie":
				var name = "", swffile = "", swfwidth = "425", swfheight = "350", action = "insert";
				var template = new Array();
				var inst = tinyMCE.getInstanceById(editor_id);
				var focusElm = inst.getFocusElement();

				template['file']   = '../../plugins/matsue_movie/matsue_movie.htm'; // Relative to theme
				template['width']  = 430;
				template['height'] = 175;

				template['width'] += tinyMCE.getLang('lang_matsue_movie_delta_width', 0);
				template['height'] += tinyMCE.getLang('lang_matsue_movie_delta_height', 0);

				// Is selection a image
				if (focusElm != null && focusElm.nodeName.toLowerCase() == "img") {
					name = tinyMCE.getAttrib(focusElm, 'class');

					if (name.indexOf('mceItemMatsueMovie') == -1) // Not a Flash
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
						if (tinyMCE.getAttrib(imgs[i], "class") == "mceItemMatsueMovie") {
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
					if (tinyMCE.getAttrib(imgs[i], "class") == "mceItemMatsueMovie") {
						var src = tinyMCE.getAttrib(imgs[i], "alt");

						if (tinyMCE.getParam('convert_urls'))
							src = eval(tinyMCE.settings['urlconverter_callback'] + "(src, null, true);");

						imgs[i].setAttribute('alt', src);
						imgs[i].setAttribute('title', src);
					}
				}
				break;

			case "insert_to_editor":
				var startPos = -1;
                while ((startPos = content.indexOf("<EXT", startPos+1)) != -1 ||
                      (startPos = content.indexOf("<ext", startPos+1)) != -1) {
					var endPos = content.indexOf('/>', startPos);
					var attribs = TinyMCE_MatsueMoviePlugin._parseAttributes(content.substring(startPos + 4, endPos));

					// Is not matsue movie, skip it
					if (attribs['type'] != "matsue_movie")
						continue;

					endPos += 2;

                    // Insert image
					var contentAfter = content.substring(endPos);
                    content = content.substring(0, startPos);
                    content += '<img width="' + attribs["width"] + '" height="' + attribs["height"] + '"';
                    content += ' src="' + (tinyMCE.getParam("theme_href") + '/images/spacer.gif') + '" title="' + attribs["data"] + '"';
                    content += ' alt="' + attribs["data"] + '" class="mceItemMatsueMovie" />';
                    content += contentAfter;

                    startPos++;
                }

				break;

			case "get_from_editor":
				// Parse all img tags and replace them with object+embed
				var startPos = -1;

				while ((startPos = content.indexOf('<img', startPos+1)) != -1) {
					var endPos = content.indexOf('/>', startPos);
					var attribs = TinyMCE_MatsueMoviePlugin._parseAttributes(content.substring(startPos + 4, endPos));

					// Is not matsue movie, skip it
					if (attribs['class'] != "mceItemMatsueMovie")
						continue;

					endPos += 2;

					// Insert object + embed
					var embedHTML = '';
					var src = attribs["title"];

					if( src.indexOf("movies/") > -1 )
                      src = src.replace(/.+\//, "");

                    embedHTML += '<EXT type="matsue_movie"';
                    embedHTML += ' data="' + src + '"';
                    embedHTML += ' width="' + attribs["width"] + '"';
                    embedHTML += ' height="' + attribs["height"] + '"';
                    embedHTML += '/>';

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
			if (node.nodeName == "IMG" && tinyMCE.getAttrib(node, 'class').indexOf('mceItemMatsueMovie') == 0) {
				tinyMCE.switchClass(editor_id + '_matsue_movie', 'mceButtonSelected');
				return true;
			}
		} while ((node = node.parentNode));

		tinyMCE.switchClass(editor_id + '_matsue_movie', 'mceButtonNormal');

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

tinyMCE.addPlugin("matsue_movie", TinyMCE_MatsueMoviePlugin);
