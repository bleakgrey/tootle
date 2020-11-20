using Gtk;
using Gee;

public class Tootle.Widgets.MarkupView : Box {

	public delegate void NodeFn (Xml.Node* node);
	public delegate void NodeHandlerFn (MarkupView view, Xml.Node* node);

	string? current_chunk = null;

	string _content = "";
	public string content {
		get {
			return _content;
		}
		set {
			_content = value;
			update_content (_content);
		}
	}

	construct {
		orientation = Orientation.VERTICAL;
		spacing = 12;
	}

	void update_content (string content) {
		get_children ().foreach (w => {
			w.destroy ();
		});

		var doc = Html.Doc.read_doc (content, "", "utf8");
		if (doc == null) {
			//warning ("No document found!");
			return;
		}

		var root = doc->get_root_element ();
		if (root == null) {
			//warning ("No root node found!");
			return;
		}

		//message (content);
		default_handler (this, root);

		//delete doc;

		visible = get_children ().length () > 0;
	}

	static void traverse (Xml.Node* root, owned NodeFn cb) {
		Xml.Node* iter;
		for (iter = root->children; iter != null; iter = iter->next) {
			cb (iter);
		}
	}

	void commit_chunk () {
		if (current_chunk != null && current_chunk != "") {
			var label = new RichLabel (current_chunk) {
				visible = true,
				markup = MarkupPolicy.TRUST
			};
			pack_start (label);
		}
		current_chunk = null;
	}

	void write_chunk (string? chunk) {
		if (chunk == null) return;

		if (current_chunk == null)
			current_chunk = chunk;
		else
			current_chunk += chunk;
	}



	public static void default_handler (MarkupView v, Xml.Node* root) {
		switch (root->name) {
			case "html":
			case "span":
			case "markup":
			case "pre":
			case "ul":
			case "ol":
				traverse (root, (node) => {
					default_handler (v, node);
				});
				break;
			case "body":
				traverse (root, (node) => {
					default_handler (v, node);
				});
				v.commit_chunk ();
				break;
			case "p":
				// Don't add spacing if this is the first paragraph
				if (v.current_chunk != "" && v.current_chunk != null)
					v.write_chunk ("\n\n");

				traverse (root, (node) => {
					default_handler (v, node);
				});
				break;
			case "code":
			case "blockquote":
				v.commit_chunk ();

				var text = "";
				traverse (root, (node) => {
					switch (node->name) {
						case "text":
							text += node->content;
							break;
						default:
							break;
					}
				});

				var label = new RichLabel (text) {
					visible = true,
					markup = MarkupPolicy.DISALLOW
				};
				label.get_style_context ().add_class ("ttl-code");
				v.pack_start (label);
				break;
			case "a":
				var href = root->get_prop ("href");
				if (href != null) {
					v.write_chunk ("<a href='"+href+"'>");
					traverse (root, (node) => {
						default_handler (v, node);
					});
					v.write_chunk ("</a>");
				}
				break;
			case "li":
				v.write_chunk ("\n• ");
				traverse (root, (node) => {
					default_handler (v, node);
				});
				break;
			case "br":
				v.write_chunk ("\n");
				break;
			case "text":
				v.write_chunk (GLib.Markup.escape_text (root->content));
				break;
			default:
				warning ("Unknown HTML tag: "+root->name);
				break;
		}
	}

}
