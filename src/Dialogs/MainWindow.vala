using Gtk;
using Gdk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/main.ui")]
public class Tootle.Dialogs.MainWindow: Adw.Window, ISavedWindow {

	public const string ZOOM_CLASS = "ttl-scalable";

	[GtkChild] unowned Adw.Leaflet deck;

	Views.Base? last_view = null;

	construct {
		var gtk_settings = Gtk.Settings.get_default ();
		settings.bind_property ("dark-theme", gtk_settings, "gtk-application-prefer-dark-theme", BindingFlags.SYNC_CREATE);
		settings.notify["post-text-size"].connect (() => on_zoom_level_changed ());

		on_zoom_level_changed ();
		deck.notify["visible-child"].connect (on_view_changed);
		// button_press_event.connect (on_button_press);
		restore_state ();
	}

	public MainWindow (Gtk.Application app) {
		Object (
			application: app,
			icon_name: Build.DOMAIN,
			title: Build.NAME,
			resizable: true
		);
		open_view (new Views.Main ());
	}

	public Views.Base open_view (Views.Base view) {
		deck.append (view);
		deck.visible_child = view;
		return view;
	}

	public bool back () {
		deck.navigate (Adw.NavigationDirection.BACK);
		return true;
	}

	[GtkCallback]
	void on_child_transition () {
		if (deck.child_transition_running)
			return;

		Widget unused_child;
		while ((unused_child = deck.get_adjacent_child (Adw.NavigationDirection.FORWARD)) != null)
			unused_child.destroy ();
	}

	// public override bool delete_event (Gdk.EventAny event) {
	// 	window = null;
	// 	return app.on_window_closed ();
	// }

	//TODO: switch timelines with 1-4. Should be moved to Views.TabbedBase
	[Deprecated]
	public void switch_timeline (int32 num) {
	}

	// bool on_button_press (EventButton ev) {
	// 	if (ev.button == 8)
	// 		return back ();
	// 	return false;
	// }

	void on_zoom_level_changed () {
		try {
			var scale = settings.post_text_size;
			var css = "";

			if (scale > 100) {
				css ="""
					.%s label {
						font-size: %i%;
					}
				""".printf (ZOOM_CLASS, scale);
			}

			app.zoom_css_provider.load_from_data (css.data);
		}
		catch (Error e) {
			warning (@"Can't set zoom level: $(e.message)");
		}
	}

	void on_view_changed () {
		var view = deck.visible_child as Views.Base;

		if (last_view != null) {
			last_view.current = false;
			last_view.on_hidden ();
		}

		if (view != null) {
			view.current = true;
			view.on_shown ();
		}

		last_view = view;
	}

}
