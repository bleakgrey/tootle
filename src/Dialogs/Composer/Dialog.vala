using Gtk;
using Gee;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/compose.ui")]
public class Tootle.Dialogs.Compose : Adw.Window {

	public API.Status status { get; construct set; }

	public string button_label {
		set {
			commit_button.label = value;
		}
	}
	public string button_class {
		set {
			commit_button.add_css_class (value);
		}
	}

	construct {
		transient_for = app.main_window;
		title_switcher.stack = stack;

		on_constructed ();
		present ();
	}

	public virtual signal void on_constructed () {
		add_page (new EditorPage ());
		add_page (new AttachmentsPage ());
		add_page (new PollPage ());
	}



	[GtkChild] unowned Adw.ViewSwitcherTitle title_switcher;
	[GtkChild] unowned Button commit_button;

	[GtkChild] unowned Adw.ViewStack stack;



	public Compose (API.Status template = new API.Status.empty ()) {
		Object (
			status: template,
			button_label: _("Compose"),
			button_class: "suggested-action"
		);
		// set_visibility (status.visibility);
	}

	public Compose.redraft (API.Status status) {
		Object (
			status: status,
			button_label: _("Redraft"),
			button_class: "destructive-action"
		);
	}

	public Compose.reply (API.Status to) {
		var template = new API.Status.empty () {
			in_reply_to_id = to.id.to_string (),
			in_reply_to_account_id = to.account.id.to_string (),
			spoiler_text = to.spoiler_text,
			content = to.formal.get_reply_mentions ()
		};

		Object (
			status: template,
			button_label: _("Reply"),
			button_class: "suggested-action"
		);
		// set_visibility (to.visibility);
	}

	protected T? get_page<T> () {
		// return widget as typeof(T);
		return null;
	}

	protected void add_page (ComposerPage page) {
		var wrapper = stack.add (page);
		page.bind_property ("visible", wrapper, "visible", GLib.BindingFlags.SYNC_CREATE);
		page.bind_property ("title", wrapper, "title", GLib.BindingFlags.SYNC_CREATE);
		page.bind_property ("icon_name", wrapper, "icon_name", GLib.BindingFlags.SYNC_CREATE);
		page.bind_property ("badge_number", wrapper, "badge_number", GLib.BindingFlags.SYNC_CREATE);
		// wrapper.badge_number;
	}

	[GtkCallback] void on_close () {
		destroy ();
	}

	[GtkCallback] void on_commit () {
		destroy ();
	}

}
