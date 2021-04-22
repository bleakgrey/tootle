using Gtk;
using Gdk;

public class Tootle.Widgets.Avatar : Button {

	Adw.Avatar avatar;

	public int size {
		get {
			return avatar.size;
		}
		set {
			avatar.size = value;
		}
	}

	public API.Account? account { get; set; }

	construct {
		avatar = new Adw.Avatar (48, null, true);
		child = avatar;
		halign = valign = Align.CENTER;
		add_css_class ("flat");
		add_css_class ("circular");
		add_css_class ("image-button");
		add_css_class ("ttl-flat-button");

		notify["account"].connect (on_invalidated);
		on_invalidated ();
	}

	void on_invalidated () {
		if (account == null) {
			avatar.text = "d";
			avatar.show_initials = false;
		}
		else {
			avatar.text = account.display_name;
			avatar.show_initials = true;
		}
	}

}
