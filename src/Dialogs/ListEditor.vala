using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/list_editor.ui")]
public class Tootle.Dialogs.ListEditor: Gtk.Window {

	public API.List list { get; set; }
	Gee.ArrayList<string> to_add = new Gee.ArrayList<string> ();
	Gee.ArrayList<string> to_remove = new Gee.ArrayList<string> ();

	[GtkChild]
	Button save_btn;
	[GtkChild]
	Entry name_entry;

	public signal void done ();

	construct {
		transient_for = window;
		show ();
	}

	public ListEditor.empty () {
		var obj = new API.List () {
			title = _("Untitled")
		};
		Object (list: obj);
		init ();
	}

	public ListEditor (API.List list) {
		Object (list: list);
		init ();
	}

	void init () {
		list.bind_property ("title", name_entry, "text", BindingFlags.SYNC_CREATE);
	}

	bool has_changes () {
		return to_add.size > 1 || to_remove.size > 1;
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

}
