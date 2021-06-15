using Gtk;

public class Tootle.Views.Main : Views.TabbedBase {

	// public Widgets.AccountsButton account_button;
	// public Button compose_button;
	// public Button search_button;

	public Main () {
		add_tab (new Views.Home ());
		add_tab (new Views.Notifications ());
		add_tab (new Views.Local ());
		add_tab (new Views.Federated ());
	}

	public override void build_header () {
		base.build_header ();
		back_button.hide ();

		var sidebar_button = new ToggleButton ();
		header.pack_start (sidebar_button);

		app.notify["main-window"].connect (() => {
			if (app.main_window == null) {
				sidebar_button.hide ();
				return;
			}

			app.main_window.flap.bind_property ("folded", sidebar_button, "visible", BindingFlags.SYNC_CREATE);
			app.main_window.flap.bind_property ("reveal-flap", sidebar_button, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
			app.main_window.flap.bind_property ("reveal-flap", sidebar_button, "icon-name", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
				var state = src.get_boolean ();
				target.set_string (state ? "sidebar-hide-symbolic" : "sidebar-show-symbolic" );
				return true;
			});
		});
		// account_button = new Widgets.AccountsButton ();
		// header.pack_start (account_button);

		// compose_button = new Button.from_icon_name ("document-edit-symbolic");
		// compose_button.tooltip_text = _("Compose");
		// compose_button.action_name = "app.compose";
		// header.pack_start (compose_button);

		// search_button = new Button.from_icon_name ("edit-find-symbolic");
		// search_button.tooltip_text = _("Search");
		// search_button.action_name = "app.search";
		// header.pack_end (search_button);
	}

}
