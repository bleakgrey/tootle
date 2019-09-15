using Gtk;
using Gdk;

public class Tootle.Widgets.Attachment.Item : EventBox {

	public API.Attachment attachment { get; construct set; }
	
	private Cache.Reference? cached;

	public Item (API.Attachment obj) {
		Object (attachment: obj);
	}
	~Item () {
		cache.unload (cached);
	}
	
	construct {
		get_style_context ().add_class ("attachment");
		width_request = height_request = 128;
		hexpand = true;
		show ();
		on_request ();
	}

	protected void on_request () {
		cached = null;
		on_redraw ();
		cache.load (attachment.preview_url, on_cache_result);
	}

	protected void on_redraw () {
		var w = get_allocated_width ();
		var h = get_allocated_height ();
		queue_draw_area (0, 0, w, h);
	}

	protected void on_cache_result (Cache.Reference? result) {
		cached = result;
		on_redraw ();
	}

	public override bool draw (Cairo.Context ctx) {
		base.draw (ctx);
		var w = get_allocated_width ();
		var h = get_allocated_height ();
		var style = get_style_context ();
		var border_radius = style.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, style.get_state ()).get_int ();
		
		if (cached != null) {
			if (cached.item != null) {
				Drawing.draw_rounded_rect (ctx, 0, 0, w, h, border_radius);
				var pixbuf = cached.item.scale_simple (w, h, InterpType.BILINEAR);
				Gdk.cairo_set_source_pixbuf (ctx, pixbuf, 0, 0);
				ctx.fill ();
			}
		}
		
		return Gdk.EVENT_STOP;
	}

}
