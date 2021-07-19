using Gtk;

public class Tootle.Widgets.Attachment.Item : Adw.Bin {

	public API.Attachment entity { get; set; default = null; }

	protected Overlay overlay;
	protected Button button;
	protected Label badge;

	construct {
		notify["entity"].connect (on_rebind);
		add_css_class ("attachment");
		add_css_class ("flat");

		button = new Button ();
		button.clicked.connect (on_click);

		badge = new Label ("") {
			valign = Align.END,
			halign = Align.START
		};
		badge.add_css_class ("osd");
		badge.add_css_class ("heading");

		overlay = new Overlay ();
		overlay.child = button;
		overlay.add_overlay (badge);
		child = overlay;
	}

	protected virtual void on_rebind () {
		badge.label = entity == null ? "" : entity.kind.up();
	}

	protected virtual void on_click () {}

}
