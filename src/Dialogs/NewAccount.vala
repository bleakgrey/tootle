using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/new_account.ui")]
public class Tootle.Dialogs.NewAccount: Gtk.Window {

	public NewAccount () {
		Object (transient_for: window);
	}

}
