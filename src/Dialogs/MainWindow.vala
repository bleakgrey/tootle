using Gtk;
using Gdk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/main.ui")]
public class Tootle.Dialogs.MainWindow: Hdy.Window, ISavedWindow {

	public const string ZOOM_CLASS = "app-scalable";

	[GtkChild]
	Hdy.Deck deck;

	// [GtkChild]
	// protected Stack view_stack;
	// [GtkChild]
	// protected Stack timeline_stack;

	// [GtkChild]
	// public Hdy.HeaderBar header;
	// [GtkChild]
	// protected Revealer view_navigation;
	// [GtkChild]
	// protected Revealer view_controls;
	// [GtkChild]
	// protected Button back_button;
	// [GtkChild]
	// protected Button compose_button;
	// [GtkChild]
	// protected Hdy.ViewSwitcherTitle timeline_switcher;
	// [GtkChild]
	// protected Hdy.ViewSwitcherBar switcher_navbar;
	// [GtkChild]
	// protected Widgets.AccountsButton accounts_button;

	// Views.Base? last_view = null;

	construct {
		open_view (new Views.Main ());

		settings.bind_property ("dark-theme", Gtk.Settings.get_default (), "gtk-application-prefer-dark-theme", BindingFlags.SYNC_CREATE);
		settings.notify["post-text-size"].connect (() => on_zoom_level_changed ());

		on_zoom_level_changed ();

		button_press_event.connect (on_button_press);
		restore_state ();
	}

	public MainWindow (Gtk.Application app) {
		Object (
			application: app,
			icon_name: Build.DOMAIN,
			title: Build.NAME,
			resizable: true,
			window_position: WindowPosition.CENTER
		);
	}

	public bool open_view (Views.Base view) {
		deck.add (view);
		deck.visible_child = view;
		return true;
	}

	public bool back () {
		var children = deck.get_children ();
		unowned var current = children.find (deck.visible_child);
		if (current != null) {
			unowned var prev = current.prev;
			if (current.prev != null) {
				deck.visible_child = prev.data;
				(current.data as Views.Base).unused = true;
				Timeout.add (deck.transition_duration, clean_unused_views);
			}
		}
		return true;
	}

	bool clean_unused_views () {
		deck.get_children ().foreach (c => {
			var view = c as Views.Base;
			if (view != null && view.unused)
				view.destroy ();
		});
		return Source.REMOVE;
	}
	public override bool delete_event (Gdk.EventAny event) {
		window = null;
		return app.on_window_closed ();
	}

	[Deprecated]
	public void switch_timeline (int32 num) {
	}

	[Deprecated]
	public void set_header_controls (Widget w) {
	}
	[Deprecated]
	public void reset_header_controls () {
	}

	bool on_button_press (EventButton ev) {
		if (ev.button == 8)
			return back ();
		return false;
	}

	void on_zoom_level_changed () {
		var css ="""
			.%s label {
				font-size: %i%;
			}
		""".printf (ZOOM_CLASS, settings.post_text_size);

		try {
			app.zoom_css_provider.load_from_data (css);
		}
		catch (Error e) {
			warning (@"Can't set zoom level: $(e.message)");
		}
	}

}
