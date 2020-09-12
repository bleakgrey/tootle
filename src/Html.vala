public class Tootle.Html {

	public const string FALLBACK_TEXT = _("[ There was an error parsing this text :c ]");

	public static string remove_tags (string content) {
		try {
			var fixed_paragraphs = simplify (content);
			var all_tags = new Regex ("<(.|\n)*?>", RegexCompileFlags.CASELESS);
			return Widgets.RichLabel.restore_entities (all_tags.replace (fixed_paragraphs, -1, 0, ""));
		}
		catch (Error e) {
			warning (e.message);
			return FALLBACK_TEXT;
		}
	}

	public static string simplify (string str) {
		try {
			var divided = str
			.replace("<br>", "\n")
			.replace("</br>", "")
			.replace("<br/>", "\n")
			.replace("<br />", "\n")
			.replace("<p>", "")
			.replace("</p>", "\n\n")
			.replace("<pre>", "")
			.replace("</pre>", "");

			var html_params = new Regex ("(class|target|rel|data-user|data-tag)=\"(.|\n)*?\"", RegexCompileFlags.CASELESS);
			var simplified = html_params.replace (divided, -1, 0, "");

			while (simplified.has_suffix ("\n"))
				simplified = simplified.slice (0, simplified.last_index_of ("\n"));

			var html_img_src = new Regex ("<img[ ]+(src)=\"([^\"]*)\"(.|\n)*?\\/>", RegexCompileFlags.CASELESS);
			simplified = html_img_src.replace_eval(simplified, simplified.length, 0, 0, (match_info, result) => {
				var src = match_info.fetch(2);
				// TODO: Show image in-line instead of a link to the image
				result.append_printf("<a href=\"%s\">%s</a>", src, src);
				return false;
			});

			return simplified;
		}
		catch (Error e) {
			warning (e.message);
			return FALLBACK_TEXT;
		}
	}

	public static string replace_with_pango_markup (string str) {
		var result = str
			.replace("<strong>", "<b>")
			.replace("</strong>", "</b>")
			.replace("<em>", "<i>")
			.replace("</em>", "</i>")
			.replace("<code>", "<span font_family=\"monospace\">")
			.replace("</code>", "</span>\n")
			.replace("<del>", "<s>")
			.replace("</del>", "</s>");
		return list_tags_to_text(result);
	}

	private enum ListType {
		UL,
		OL
	}

	private struct ListTag {
		ListType type;
		int counter;
	}

	public static string list_tags_to_text (string str) {
		try {
			var list_tags = new Regex ("<(/?)(ul|ol|li)>", RegexCompileFlags.CASELESS);
			var list_tag_stack = new Array<ListTag> ();
			return list_tags.replace_eval(str, str.length, 0, 0, (match_info, result) => {
				var is_start_tag = match_info.fetch(1) == "";
				var match = match_info.fetch(2);
				if (match == "ul") {
					if (is_start_tag) {
						var list_tag = ListTag();
						list_tag.type = ListType.UL;
						list_tag.counter = 1;
						list_tag_stack.append_val(list_tag);
					} else {
						if (list_tag_stack.length > 0)
							list_tag_stack.remove_index_fast (list_tag_stack.length - 1);
					}
				} else if (match == "ol") {
					if (is_start_tag) {
						var list_tag = ListTag();
						list_tag.type = ListType.OL;
						list_tag.counter = 1;
						list_tag_stack.append_val(list_tag);
					} else {
						if (list_tag_stack.length > 0)
							list_tag_stack.remove_index_fast (list_tag_stack.length - 1);
					}
				} else if (match == "li") {
					if (is_start_tag) {
						if (list_tag_stack.length > 0) {
							var last_tag_item = list_tag_stack.index(list_tag_stack.length - 1);
							if (last_tag_item.type == ListType.UL)
								result.append("• ");
							else if (last_tag_item.type == ListType.OL)
								result.append_printf("%d. ", last_tag_item.counter);
							last_tag_item.counter++;
						}
					} else {
						if (list_tag_stack.length > 0) {
							if( list_tag_stack.index(list_tag_stack.length - 1).counter > 1)
								list_tag_stack.index(list_tag_stack.length - 1).counter--;
							result.append("\n");
						}
					}
				}
				return false;
			});
		} catch (Error e) {
			warning (e.message);
			return str;
		}
	}

	public static string uri_encode (string str) {
		var restored = Widgets.RichLabel.restore_entities (str);
		return Soup.URI.encode (restored, ";&+");
	}

}
