using Gtk;
using Gdk;

public class Tootle.Widgets.Attachment.Picture : DrawingArea {

	public string url { get; set; }

	Cache.Reference? cached;

	construct {
		hexpand = vexpand = true;
		get_style_context ().add_class ("pic");
	}

	public class Picture (string url) {
		Object (url: url);
	}
	~Picture () {
		cache.unload (cached);
	}

	public void on_request () {
		cached = null;
		on_redraw ();
		cache.load (url, on_cache_result);
	}

	void on_redraw () {
		var w = get_allocated_width ();
		var h = get_allocated_height ();
		queue_draw_area (0, 0, w, h);
	}

	void on_cache_result (Cache.Reference? result) {
		cached = result;
		visible = !cached.loading;
		on_redraw ();
	}

	public override bool draw (Cairo.Context ctx) {
		var w = get_allocated_width ();
		var h = get_allocated_height ();
		var style = get_style_context ();
		var border_radius = style.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, style.get_state ()).get_int ();

		if (cached != null) {
			if (!cached.loading) {
				Cairo.Surface surface = Gdk.cairo_surface_create_from_pixbuf (cached.data, 1, null);

				ctx.save ();
				var ow = cached.data.get_width ();
				var oh = cached.data.get_height ();
				var xscale = (float) w / ow;
				var yscale = (float) h / oh;
				Drawing.draw_rounded_rect (ctx, 0, 0, w, h, border_radius);

				float ratio = yscale;
				if (xscale > yscale) {
					ratio = xscale;
				}

				ctx.scale (ratio, ratio);
				// height_request = (int) (oh*ratio);
				// get_parent ().height_request = height_request;

				ctx.set_source_surface (surface, 0, 0);
				ctx.fill ();
				ctx.restore ();
			}
		}

		return false;
	}

}
