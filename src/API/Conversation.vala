public class Tootle.API.Conversation : Entity, Widgetizable {

	public string id { get; set; }
	public Gee.ArrayList<API.Account> accounts { get; set; default = null; }
	public bool unread { get; set; default = false; }
	public API.Status? last_status { get; set; default = null; }

    public override Gtk.Widget to_widget () {
        return new Widgets.Status (last_status.formal);
    }

	public override void open () {
		var view = new Views.ExpandedStatus (last_status.formal);
		window.open_view (view);
	}

	public void mark_read () {
		new Request.POST (@"/api/v1/conversations/$id/read")
			.with_account (Tootle.accounts.active)
			.exec ();
	}

}
