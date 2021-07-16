using Gtk;

public class Tootle.ComposerPage : Gtk.Box {

	public string title { get; set; }
	public string icon_name { get; set; }
	public uint badge_number { get; set; default = 0; }

	ScrolledWindow scroller;
	protected Box content;
	protected ActionBar bottom_bar;

	construct {
		orientation = Orientation.VERTICAL;

		scroller = new ScrolledWindow () {
			hexpand = true,
			vexpand = true
		};
		append (scroller);

		content = new Box (Orientation.VERTICAL, 0);
		scroller.child = content;

		bottom_bar = new ActionBar () {
			visible = false
		};
		append (bottom_bar);
	}

	protected void add_button (Widget widget) {
		bottom_bar.pack_start (widget);
		widget.add_css_class ("flat");
		bottom_bar.show ();
	}

}
