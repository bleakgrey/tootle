using Gtk;
using Gee;

public class Tootle.Widgets.MarkupView : Box {

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

		default_handler (this, root);

		delete doc;
	}

	public delegate void NodeFn (Xml.Node* node);

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

	void write_chunk (string chunk) {
		if (current_chunk == null)
			current_chunk = chunk;
		else
			current_chunk += chunk;
	}



	public static void default_handler (MarkupView v, Xml.Node* root) {
		var name = root->name;
		switch (name) {
			case "html":
				message ("===START DOC===");
				traverse (root, (node) => {
					default_handler (v, node);
				});
				message ("=== END DOC ===");
				break;
			case "body":
				message (root->content);
				traverse (root, (node) => {
					default_handler (v, node);
				});
				v.commit_chunk ();
				break;
			case "br":
				v.write_chunk ("\n");
				break;
			case "text":
				message (root->content);
				v.write_chunk (root->content);
				break;
			case "p":
				v.commit_chunk ();
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
