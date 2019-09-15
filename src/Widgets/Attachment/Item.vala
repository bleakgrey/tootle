using Gtk;

public class Tootle.Widgets.Attachment.Item : EventBox {

	public API.Attachment attachment { get; construct set; }

	public Item (API.Attachment obj) {
		Object (attachment: obj);
	}
	
	construct {
		get_style_context ().add_class ("attachment");
	}

}
