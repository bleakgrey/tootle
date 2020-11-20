using Gtk;

public class Tootle.Widgets.MarkupView : Box {

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

		handle_node (root);

		delete doc;
	}

	public delegate void NodeCB (Xml.Node* node);
	void traverse (Xml.Node* root, owned NodeCB cb) {
		Xml.Node* iter;
		for (iter = root->children; iter != null; iter = iter->next) {
			//warning (iter->name);

			// if (iter->content != null)
			// 	warning (iter->content);

			//handle_node (iter);
			//traverse_node (iter);

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

	void handle_node (Xml.Node* root) {
		switch (root->name) {
			case "html":
				message ("===START DOC===");
				traverse (root, (node) => {
					handle_node (node);
				});
				message ("=== END DOC ===");
				break;
			case "body":
				message (content);
				traverse (root, (node) => {
					handle_node (node);
				});
				commit_chunk ();
				break;
			case "br":
				write_chunk ("\n");
				break;
			case "text":
				message (root->content);
				write_chunk (root->content);
				break;
			case "p":
				commit_chunk ();
				traverse (root, (node) => {
					handle_node (node);
				});
				break;
			default:
				warning ("Unknown HTML tag: "+root->name);
				break;
		}
	}

}
