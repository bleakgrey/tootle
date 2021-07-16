using Gtk;

public class Tootle.EditorPage : ComposerPage {

	public uint char_limit { get; set; default = 500; } //TODO: Ask the instance to get this value

	protected TextView editor;
	protected Label char_counter;

	protected int remaining_chars { get; set; default = 0; }

	public EditorPage () {
		Object (
			title: _("Text"),
			icon_name: "document-edit-symbolic"
		);
	}

	construct {
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
		content.append (editor);

		bottom_bar = new ActionBar ();
		append (bottom_bar);

		char_counter = new Label (char_limit.to_string ());
		char_counter.add_css_class ("heading");
		bottom_bar.pack_end (char_counter);
		editor.buffer.changed.connect (count_characters);
		notify["remaining-chars"].connect (on_remaining_chars_changed);
		count_characters ();
	}

	protected void count_characters () {
		var remaining = (int) char_limit;

		remaining -= editor.buffer.get_char_count ();
		// if cw
		// - cw.buffer.get_char_count ()

		remaining_chars = remaining;
	}

	void on_remaining_chars_changed () {
		char_counter.label = remaining_chars.to_string ();
		if (remaining_chars < 0)
			char_counter.add_css_class ("error");
		else
			char_counter.remove_css_class ("error");
	}

}
