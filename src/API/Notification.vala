public class Tootle.API.Notification : Entity, Widgetizable {

    public string id { get; set; }
    public API.Account account { get; set; }
    public API.NotificationType kind { get; set; }
    public string created_at { get; set; }
    public API.Status? status { get; set; default = null; }

    public override Gtk.Widget to_widget () {
        return new Widgets.Notification (this);
    }

    public Json.Node? serialize () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("id");
        builder.add_string_value (id.to_string ());
        builder.set_member_name ("type");
        builder.add_string_value (kind.to_string ());
        builder.set_member_name ("created_at");
        builder.add_string_value (created_at);

        if (status != null) {
            builder.set_member_name ("status");
            builder.add_value (status.serialize ());
        }
        if (account != null) {
            builder.set_member_name ("account");
            builder.add_value (account.serialize ());
        }

        builder.end_object ();
        return builder.get_root ();
    }

    public Soup.Message? dismiss () {
        if (kind == NotificationType.WATCHLIST) {
            if (accounts.active.cached_notifications.remove (this))
                accounts.save ();
            return null;
        }

        if (kind == NotificationType.FOLLOW_REQUEST)
            return reject_follow_request ();

		var req = new Request.POST ("/api/v1/notifications/dismiss")
		    .with_account (accounts.active)
			.with_param ("id", id)
			.exec ();
        return req;
    }

    public Soup.Message accept_follow_request () {
        var req = new Request.POST (@"/api/v1/follow_requests/$(account.id)/authorize")
            .with_account (accounts.active)
            .exec ();
        return req;
    }

    public Soup.Message reject_follow_request () {
        var req = new Request.POST (@"/api/v1/follow_requests/$(account.id)/reject")
            .with_account (accounts.active)
            .exec ();
        return req;
    }

}
