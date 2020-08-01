using Gtk;

public class Tootle.Widgets.Conversation : Widgets.Status {

	public Conversation (API.Conversation entity) {
		Object (status: entity.last_status);
	}

}
