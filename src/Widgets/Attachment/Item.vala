using Gtk;

public class Tootle.Widgets.Attachment.Item : Adw.Bin {

	public API.Attachment entity { get; set; default = null; }

	protected Overlay overlay;
	protected Button button;

	construct {
		notify["entity"].connect (on_rebind);
		add_css_class ("attachment");
		add_css_class ("flat");

		button = new Button ();
		button.clicked.connect (on_click);

		overlay = new Overlay ();
		overlay.child = button;
		child = overlay;

		warning ("constr item");
	}

	protected virtual void on_rebind () {}

	protected virtual void on_click () {}

}
