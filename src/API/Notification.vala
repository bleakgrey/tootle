public class Tootle.API.Notification {

    public string id;
    public NotificationType type;
    public string created_at;

    public Status? status;
    public Account? account;

    public Notification (string _id) {
        id = _id;
    }

    public static Notification parse (Json.Object obj) {
        var id = obj.get_string_member ("id");
        var notification = new Notification (id);

        notification.type = NotificationType.from_string (obj.get_string_member ("type"));
        notification.created_at = obj.get_string_member ("created_at");

        if (obj.has_member ("status"))
            notification.status = Status.parse (obj.get_object_member ("status"));
        if (obj.has_member ("account"))
            notification.account = Account.parse (obj.get_object_member ("account"));

        return notification;
    }

    public Json.Node? serialize () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("id");
        builder.add_string_value (id.to_string ());
        builder.set_member_name ("type");
        builder.add_string_value (type.to_string ());
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

    public static Notification parse_follow_request (Json.Object obj) {
        var notification = new Notification ("");
        var account = Account.parse (obj);

        notification.type = NotificationType.FOLLOW_REQUEST;
        notification.account = account;

        return notification;
    }

    public Soup.Message? dismiss () {
        if (type == NotificationType.WATCHLIST) {
            if (accounts.formal.cached_notifications.remove (this))
                accounts.save ();
            return null;
        }

        if (type == NotificationType.FOLLOW_REQUEST)
            return reject_follow_request ();

        var url = "%s/api/v1/notifications/dismiss?id=%s".printf (accounts.formal.instance, id);
        var msg = new Soup.Message ("POST", url);
        network.inject (msg, Network.INJECT_TOKEN);
        network.queue (msg);
        return msg;
    }

    public Soup.Message accept_follow_request () {
        var url = "%s/api/v1/follow_requests/%s/authorize".printf (accounts.formal.instance, account.id);
        var msg = new Soup.Message ("POST", url);
        network.inject (msg, Network.INJECT_TOKEN);
        network.queue (msg);
        return msg;
    }

    public Soup.Message reject_follow_request () {
        var url = "%s/api/v1/follow_requests/%s/reject".printf (accounts.formal.instance, account.id);
        var msg = new Soup.Message ("POST", url);
        network.inject (msg, Network.INJECT_TOKEN);
        network.queue (msg);
        return msg;
    }

}
