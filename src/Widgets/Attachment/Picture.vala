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
		on_request ();
	}
	~Picture () {
		cache.unload (cached);
	}

	void on_request () {
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
				//var thumb = Drawing.make_thumbnail (cached.data, w, h);
				// Drawing.draw_rounded_rect (ctx, 0, 0, w, h, border_radius);
				//Drawing.center (ctx, w, h, thumb.width, thumb.height);
				//Gdk.cairo_set_source_pixbuf (ctx, thumb, 0, 0);
				// Gdk.cairo_set_source_pixbuf (ctx, cached.data, 0, 0);
				// ctx.fill ();

				Cairo.Surface surface = Gdk.cairo_surface_create_from_pixbuf (cached.data, 1, null);

				ctx.save ();
				var xscale = (float) w / cached.data.get_width ();
				var yscale = (float) h / cached.data.get_height ();
				Drawing.draw_rounded_rect (ctx, 0, 0, w, h, border_radius);
				ctx.scale (xscale, yscale);
				ctx.set_source_surface (surface, 0, 0);
				ctx.fill ();
				ctx.restore ();
			}
		}

		return Gdk.EVENT_STOP;
	}

}
