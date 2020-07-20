using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/list_editor.ui")]
public class Tootle.Dialogs.ListEditor: Gtk.Window {

	public API.List list { get; set; }

	Gee.ArrayList<string> to_add = new Gee.ArrayList<string> ();
	Gee.ArrayList<string> to_remove = new Gee.ArrayList<string> ();
	public bool working { get; set; }

	[GtkChild]
	Button save_btn;
	[GtkChild]
	Entry name_entry;

	[GtkChild]
	EntryCompletion completion;
	[GtkChild]
	Gtk.ListStore completion_model;

	public signal void done ();

	construct {
		transient_for = window;
		show ();
	}

	public ListEditor.empty () {
		var obj = new API.List () {
			title = _("Untitled")
		};
		Object (list: obj, working: false);
		init ();
	}

	public ListEditor (API.List list) {
		Object (list: list, working: true);
		init ();
		request_accounts ();
	}

	void init () {
		list.bind_property ("title", name_entry, "text", BindingFlags.SYNC_CREATE);

		completion.set_match_func (() => {
			return true;
		});
	}

	bool has_changes () {
		return to_add.size > 1 || to_remove.size > 1;
	}

	void on_error (int32 code, string msg) {
		warning (@"code $code, $msg");
	}

	//https://mastodon.social/api/v1/accounts/search?q=QUERY&resolve=false&limit=8&following=true

	void request_accounts () {
		new Request.GET (@"/api/v1/lists/$(list.id)/accounts")
			.with_account (accounts.active)
			//.with_context (this)
			.on_error (on_error)
			.then ((sess, msg) => {
				Network.parse_array (msg, node => {
					var acc = API.Account.from (node);
					add_account (acc, false);
				});
				working = false;
			})
			.exec ();
	}

	void add_account (API.Account acc, bool commit) {
		if (commit) {
			to_add.add (acc.id);
		}
	}

	[GtkCallback]
	bool on_match_selected (TreeModel model, TreeIter iter) {
		warning ("aaaa");
		return false;
	}

	[GtkCallback]
	void validate () {
		var has_title = name_entry.text.replace (" ", "") != "";
		save_btn.sensitive = has_title;
	}

	[GtkCallback]
	void on_cancel_clicked () {
		if (has_changes ()) {
			var yes = app.question (
				_("Discard unsaved changes?"),
				_("You need to save the list if you want to keep them."),
				this
			);
			if (yes)
				destroy ();
		}
		else
			destroy ();
	}

	[GtkCallback]
	void on_save_clicked () {

	}

	[GtkCallback]
	void on_search_changed () {
		warning ("CHANGED");
	}

}
