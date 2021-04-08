using Gtk;

public class Tootle.Views.ContentBase : Views.Base {

	public GLib.ListStore model;
	protected ListBox content;

	public bool empty {
		get {
			return model.get_n_items () <= 0;
		}
	}

	construct {
		content = new ListBox () {
			selection_mode = SelectionMode.NONE,
			can_focus = false
		};
		content.add_css_class ("content");
		content.row_activated.connect (on_content_item_activated);
		content_box.append (content);

		model = new GLib.ListStore (typeof (Widgetizable));
		model.items_changed.connect (() => on_content_changed ());

		scrolled.edge_reached.connect (pos => {
			if (pos == PositionType.BOTTOM)
				on_bottom_reached ();
		});
	}

	public override void clear () {
		base.clear ();
		model.remove_all ();
	}

	public override void on_content_changed () {
		if (empty) {
			status_message = STATUS_EMPTY;
			state = "status";
		}
		else {
			state = "content";
		}
		// check_resize ();
	}

	public virtual void on_bottom_reached () {}

	public virtual void on_content_item_activated (ListBoxRow row) {
		Signal.emit_by_name (row, "open");
	}

}
