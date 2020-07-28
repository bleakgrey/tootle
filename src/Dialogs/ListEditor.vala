using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/list_editor.ui")]
public class Tootle.Dialogs.ListEditor: Gtk.Window {

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/list_editor_item.ui")]
	class Item : ListBoxRow {

		public ListEditor editor { get; construct set; }
		public API.Account acc { get; construct set; }
		public bool committed { get; construct set; }

		[GtkChild]
		Widgets.RichLabel label;
		[GtkChild]
		Widgets.RichLabel handle;
		[GtkChild]
		ToggleButton status;

		public Item (ListEditor editor, API.Account acc, bool committed) {
			this.editor = editor;
			this.acc = acc;
			this.committed = committed;
			acc.bind_property ("display-name", label, "text", BindingFlags.SYNC_CREATE);
			acc.bind_property ("handle", handle, "text", BindingFlags.SYNC_CREATE);
			status.active = committed;
		}

		[GtkCallback]
		void on_toggled () {
			if (status.active) {
				editor.to_add.add (acc.id);
				editor.to_remove.remove (acc.id);
			}
			else {
				editor.to_add.remove (acc.id);
				editor.to_remove.add (acc.id);
			}
			committed = status.active;
			if (!editor.working)
				editor.dirty = true;
		}

	}

	public API.List list { get; set; }
	public bool working { get; set; }
	public bool dirty { get; set; default = false; }

	Soup.Message? search_req = null;

	public Gee.ArrayList<string> to_add = new Gee.ArrayList<string> ();
	public Gee.ArrayList<string> to_remove = new Gee.ArrayList<string> ();

	[GtkChild]
	Button save_btn;
	[GtkChild]
	Entry name_entry;
	[GtkChild]
	SearchEntry search_entry;
	[GtkChild]
	ListBox listbox;

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

		new Request.GET (@"/api/v1/lists/$(list.id)/accounts")
			.with_account (accounts.active)
			// .with_context (this)
			.on_error (on_error)
			.then ((sess, msg) => {
				Network.parse_array (msg, node => {
					var acc = API.Account.from (node);
					add_account (acc, true);
				});
				working = false;
			})
			.exec ();
	}

	void init () {
		list.bind_property ("title", name_entry, "text", BindingFlags.SYNC_CREATE);

		ulong dirty_sigid = 0;
		dirty_sigid = name_entry.changed.connect (() => {
			dirty = true;
			name_entry.disconnect (dirty_sigid);
		});
	}

	void on_error (int32 code, string msg) {
		warning (@"Error code $code: \"$msg\"");
	}

	void request_search (string q) {
		debug (@"Searching for: \"$q\"...");
		if (search_req != null) {
			network.cancel (search_req);
			search_req = null;
		}

		search_req = new Request.GET ("/api/v1/accounts/search")
			.with_account (accounts.active)
			// .with_context (this)
			.with_param ("resolve", "false")
			.with_param ("limit", "8")
			.with_param ("following", "true")
			.with_param ("q", q)
			.then ((sess, msg) => {
				Network.parse_array (msg, node => {
					var acc = API.Account.from (node);
					add_account (acc, false, 0);
				});
			})
			.on_error (on_error)
			.exec ();
	}

	void add_account (API.Account acc, bool committed, int order = -1) {
		var exists = false;
		listbox.@foreach (w => {
			var i = w as Item;
			if (i != null) {
				if (i.acc.id == acc.id)
					exists = true;
			}
		});

		if (!exists) {
			var item = new Item (this, acc, committed);
			listbox.insert (item, order);
		}
	}

	void invalidate () {
		listbox.@foreach (w => {
			var i = w as Item;
			if (i != null) {
				if (!i.committed)
					i.destroy ();
			}
		});
	}


	[GtkCallback]
	void validate () {
		var has_title = name_entry.text.replace (" ", "") != "";
		save_btn.sensitive = has_title;
	}

	[GtkCallback]
	void on_cancel_clicked () {
		if (dirty) {
			var yes = app.question (
				_("Discard changes?"),
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
		var q = search_entry.text
			.chug ()
			.chomp ();

		if (q.char_count () < 3)
			invalidate ();
		else if (q != "") {
			invalidate ();
			request_search (q);
		}
	}

}
