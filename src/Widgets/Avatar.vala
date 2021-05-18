using Gtk;
using Gdk;

public class Tootle.Widgets.Avatar : Button, Disposable {

	public API.Account? account { get; set; }
	public int size {
		get {
			return avatar.size;
		}
		set {
			avatar.size = value;
		}
	}

	protected Pixbuf? cached_data { get; set; }
	protected Adw.Avatar? avatar {
		get {
			return child as Adw.Avatar;
		}
	}

	construct {
		construct_disposable ();

		child = new Adw.Avatar (48, null, true);
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
			image_cache.request_pixbuf (account.avatar, on_cache_response);
		}
	}

	void on_cache_response (bool is_loaded, owned Pixbuf? data) {
		cached_data = data;
		avatar.set_image_load_func (set_avatar_pixbuf_fn);
	}

	Pixbuf? set_avatar_pixbuf_fn (int size) {
		return cached_data;
	}

}
