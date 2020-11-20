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
			visible = get_children ().length () > 0;
		}
	}

	construct {
		orientation = Orientation.VERTICAL;
	}

	void update_content (string content) {
		var doc = Html.Doc.read_doc (content, "", "utf8");
		if (doc == null) {
			//warning ("No document found!");
			delete doc;
			return;
		}

		var root = doc->get_root_element ();
		if (root == null) {
			//warning ("No root node found!");
			delete doc;
			return;
		}

		message (content);
		default_handler (this, root);

		delete doc;
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
				visible = true
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
			case "br":
				v.write_chunk ("\n");
				break;
			case "text":
				v.write_chunk (GLib.Markup.escape_text (root->content));
				break;
			case "p":
				if (v.current_chunk != "" && v.current_chunk != null)
					v.write_chunk ("\n\n");

				traverse (root, (node) => {
					default_handler (v, node);
				});
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
			case "span":
				traverse (root, (node) => {
					default_handler (v, node);
				});
				break;
			default:
				warning ("Unknown HTML tag: "+root->name);
				break;
		}
	}

}
