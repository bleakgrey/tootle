using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/new_account.ui")]
public class Tootle.Dialogs.NewAccount: Gtk.Window {

	const string scopes = "read%20write%20follow";

	string? instance { get; set; }
	string? code { get; set; }

	string? client_id { get; set; }
	string? client_secret { get; set; }
	string? access_token { get; set; }
	string redirect_uri { get; set; default = "urn:ietf:wg:oauth:2.0:oob"; }
	InstanceAccount account;

	public NewAccount () {
		Object (transient_for: window);
		StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), app.css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
	}

	public override bool delete_event (Gdk.EventAny event) {
		new_account_window = null;
		return app.on_window_closed ();
	}

}
