using Gtk;
using Gdk;

public class Tootle.Views.Notifications : Views.Timeline, AccountHolder, Streamable {

    protected int64 last_id = 0;

    public Notifications () {
        Object (
            url: "/api/v1/notifications",
        	label: _("Notifications"),
        	icon: "preferences-system-notifications-symbolic"
        );
        accepts = typeof (API.Notification);
    }

    public override string? get_stream_url () {
        return account.get_stream_url ();
    }

    public override void on_shown () {
        if (has_unread ()) {
            needs_attention = false;
            account.has_unread_notifications = false;
            account.last_seen_notification = last_id;
            accounts.safe_save ();
        }
    }

	//FIXME: Display unread dot
  //   public override void append (Widget? w, bool reverse = false) {
  //       base.append (w, reverse);
  //       var nw = w as Widgets.Notification;
  //       var notification = nw.notification;

  //       if (int64.parse (notification.id) > last_id)
  //           last_id = int64.parse (notification.id);

		// needs_attention = has_unread () && !current;
  //       if (needs_attention)
  //           accounts.safe_save ();
  //   }

    public override void on_account_changed (InstanceAccount? acc) {
        base.on_account_changed (acc);
        if (account == null) {
		    last_id = 0;
		    needs_attention = false;
        }
        else {
		    last_id = account.last_seen_notification;
		    needs_attention = account.has_unread_notifications;
		}
    }

    public override bool request () {
        if (account != null) {
            account.cached_notifications.@foreach (n => {
                model.append (n);
                return true;
            });
        }
        return base.request ();
    }

    bool has_unread () {
        if (account == null)
            return false;
        return last_id > account.last_seen_notification || needs_attention;
    }

	public override void on_stream_event (Streamable.Event ev) {
		try {
			switch (ev.type) {
				case Mastodon.Account.EVENT_NOTIFICATION:
					var entity = Entity.from_json (accepts, ev.get_node ());
					model.insert (0, entity);
					return;
			}
		}
		catch (Error e) {
			warning ("Couldn't process stream event: " + e.message);
		}
	}

}
