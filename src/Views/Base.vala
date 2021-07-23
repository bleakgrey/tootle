using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/base.ui")]
public class Tootle.Views.Base : Box {

	public static string STATUS_EMPTY = _("Nothing to see here");
	public static string STATUS_LOADING = " ";

	public string? icon { get; set; default = null; }
	public string label { get; set; default = ""; }
	public bool needs_attention { get; set; default = false; }
	public bool current { get; set; default = false; }
	protected SimpleActionGroup actions { get; set; default = new SimpleActionGroup (); }

	[GtkChild] protected unowned Adw.HeaderBar header;
	[GtkChild] protected unowned Button back_button;

	[GtkChild] protected unowned ScrolledWindow scrolled;
	[GtkChild] protected unowned Box view;
	[GtkChild] protected unowned Adw.Clamp clamp;
	[GtkChild] protected unowned Box column_view;
	[GtkChild] protected unowned Stack states;
	[GtkChild] protected unowned Box content_box;
	[GtkChild] protected unowned Button status_button;
	[GtkChild] unowned Stack status_stack;
	[GtkChild] unowned Label status_message_label;

	public string state { get; set; default = "status"; }
	public string status_message { get; set; default = STATUS_EMPTY; }

	construct {
	    build_actions ();
	    build_header ();

		status_button.label = _("Reload");
		bind_property ("state", states, "visible-child-name", BindingFlags.SYNC_CREATE);

		notify["status-message"].connect (() => {
			status_message_label.label = @"<span size='large'>$status_message</span>";
			status_stack.visible_child_name = status_message == STATUS_LOADING ? "spinner" : "message";
		});

		notify["current"].connect (() => {
			if (current)
				on_shown ();
			else
				on_hidden ();
		});

		scrolled.get_style_context ().add_class (Dialogs.MainWindow.ZOOM_CLASS);
	}
	~Base () {
		message ("Destroying base "+label);
	}

	public override void dispose () {
		actions.dispose ();
		base.dispose ();
	}

    protected virtual void build_actions () {}

	protected virtual void build_header () {
		var title = new Adw.WindowTitle (null, null);
		bind_property ("label", title, "title", BindingFlags.SYNC_CREATE);
		header.title_widget = title;
	}

	public virtual void clear () {
		state = "status";
	}

	public virtual void on_shown () {
		app.main_window.insert_action_group ("view", actions);
	}
	public virtual void on_hidden () {
		app.main_window.insert_action_group ("view", null);
	}

	public virtual void on_content_changed () {}

	public virtual void on_error (int32 code, string reason) {
		status_message = reason;
		status_button.visible = true;
		status_button.sensitive = true;
		state = "status";
	}

	[GtkCallback]
	void on_close () {
		app.main_window.back ();
	}

}
