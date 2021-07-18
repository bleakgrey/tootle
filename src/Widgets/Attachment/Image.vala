using Gtk;
using Gdk;

public class Tootle.Widgets.Attachment.Image : Widgets.Attachment.Item {

	protected Gtk.Picture pic;

	construct {
		pic = new Picture () {
			hexpand = true,
			vexpand = true,
			can_shrink = true,
			keep_aspect_ratio = true
		};
		button.child = pic;
		warning ("constru pic");
	}

	protected override void on_rebind () {
		image_cache.request_pixbuf (entity.preview_url, on_cache_response);
	}

	protected virtual void on_cache_response (bool is_loaded, owned Pixbuf? data) {
		pic.paintable = null;
		if (data != null)
			pic.paintable = Gdk.Texture.for_pixbuf (data);
	}

}
