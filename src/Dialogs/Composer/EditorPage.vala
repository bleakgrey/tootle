using Gtk;

public class Tootle.EditorPage : ComposerPage {

	protected TextView editor;
	protected Label char_counter;
	protected ToggleButton cw_button;

	protected uint char_limit { get; set; default = 500; } //TODO: Ask the instance to get this value
	protected int remaining_chars { get; set; default = 0; }

	protected virtual signal void recount_chars () {}
	protected virtual signal void build_dialog () {
		install_text_editor ();
		install_cw_editor ();
	}

	public EditorPage () {
		Object (
			title: _("Text"),
			icon_name: "document-edit-symbolic"
		);
	}

	construct {
		build_dialog ();
		validate ();
	}

	protected void validate () {
		recount_chars ();
	}

	protected void install_text_editor () {
		recount_chars.connect (() => {
			remaining_chars = (int) char_limit;
		});
		recount_chars.connect_after (() => {
			char_counter.label = remaining_chars.to_string ();
			if (remaining_chars < 0)
				char_counter.add_css_class ("error");
			else
				char_counter.remove_css_class ("error");
		});

		editor = new TextView () {
			vexpand = true,
			hexpand = true,
			top_margin = 6,
			right_margin = 6,
			bottom_margin = 6,
			left_margin = 6,
			pixels_below_lines = 6,
			accepts_tab = false,
			wrap_mode = WrapMode.WORD_CHAR
		};
		recount_chars.connect (() => {
			remaining_chars -= editor.buffer.get_char_count ();
		});
		content.prepend (editor);

		char_counter = new Label (char_limit.to_string ()) {
			margin_end = 6
		};
		char_counter.add_css_class ("heading");
		bottom_bar.pack_end (char_counter);
		editor.buffer.changed.connect (validate);
	}

	protected void install_cw_editor () {
		var cw_entry = new Gtk.Entry () {
			placeholder_text = _("Write your warning here"),
			margin_top = 6,
			margin_end = 6,
			margin_start = 6
		};
		cw_entry.buffer.inserted_text.connect (validate);
		cw_entry.buffer.deleted_text.connect (validate);
		var revealer = new Gtk.Revealer () {
			child = cw_entry
		};
		revealer.add_css_class ("view");
		content.prepend (revealer);

		cw_button = new ToggleButton () {
			icon_name = "dialog-warning-symbolic",
			tooltip_text = _("Spoiler Warning")
		};
		cw_button.toggled.connect (validate);
		cw_button.bind_property ("active", revealer, "reveal_child", GLib.BindingFlags.SYNC_CREATE);
		add_button (cw_button);

		recount_chars.connect (() => {
			if (cw_button.active)
				remaining_chars -= (int) cw_entry.buffer.length;
		});
	}

}
