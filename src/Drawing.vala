using Gdk;
using GLib;

public class Tootle.Drawing {

	public static void draw_rounded_rect (Cairo.Context ctx, double x, double y, double w, double h, double r) {
		double degr = Math.PI / 180.0;
		ctx.new_sub_path ();
		ctx.arc (x + w - r, y + r, r, -90 * degr, 0 * degr);
		ctx.arc (x + w - r, y + h - r, r, 0 * degr, 90 * degr);
		ctx.arc (x + r, y + h - r, r, 90 * degr, 180 * degr);
		ctx.arc (x + r, y + r, r, 180 * degr, 270 * degr);
		ctx.close_path ();
	}

	public static void center (Cairo.Context ctx, int w, int h, int tw, int th) {
		var cx = w/2 - tw/2;
		var cy = h/2 - th/2;
		ctx.translate (cx, cy);
	}

	public static Pixbuf make_thumbnail (Pixbuf pixbuf, int view_w, int view_h) {
		// Don't resize if parent view is bigger than actual image
		if (view_w >= pixbuf.width && view_h >= pixbuf.height)
			return pixbuf;

		//Otherwise fit the image into the parent view
		var resized_w = view_w;
		var resized_h = view_h;
		resized_w = (pixbuf.width * view_h) / pixbuf.height;
		resized_h = (pixbuf.height * view_w) / pixbuf.width;

		var fill_parent = false;
		if (fill_parent)
			resized_h = (pixbuf.height * view_w) / pixbuf.width;
		else
			resized_w = (pixbuf.width * view_h) / pixbuf.height;

		return pixbuf.scale_simple (resized_w, resized_h, InterpType.BILINEAR);
	}

}
