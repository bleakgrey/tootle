using Gtk;
using Gdk;

public class Tootle.Views.Notifications : Views.Base, IAccountListener {

    private int64 last_id = 0;
    private bool force_dot = false;

    public Notifications () {
        base ();
        content.remove.connect (on_remove);
        connect_account_service ();
        app.refresh.connect (on_refresh);
        network.notification.connect (prepend);

        request ();
    }

    private bool has_unread () {
        if (accounts.active == null)
            return false;
        return last_id > accounts.active.last_seen_notification || force_dot;
    }

    public override string get_icon () {
        if (has_unread ())
            return Desktop.fallback_icon ("notification-new-symbolic", "user-available-symbolic");
        else
            return Desktop.fallback_icon ("notification-symbolic", "user-invisible-symbolic");
    }

    public override string get_name () {
        return _("Notifications");
    }

    public void prepend (API.Notification notification) {
        append (notification, true);
    }

    public void append (API.Notification notification, bool reverse = false) {
        var widget = new Widgets.Notification (notification);
        content.pack_start (widget, false, false, 0);

        if (reverse) {
            content.reorder_child (widget, 0);

            if (!current) {
                force_dot = true;
                accounts.active.has_unread_notifications = force_dot;
            }
        }

        if (notification.id > last_id)
            last_id = notification.id;

        if (has_unread ()) {
            accounts.save ();
            image.icon_name = get_icon ();
        }
        
        state = "content";
        check_resize ();
    }

    public override void on_set_current () {
        var account = accounts.active;
        if (has_unread ()) {
            force_dot = false;
            account.has_unread_notifications = force_dot;
            account.last_seen_notification = last_id;
            accounts.save ();
            image.icon_name = get_icon ();
        }
    }

    public virtual void on_remove (Widget widget) {
        if (!(widget is Widgets.Notification))
            return;

        empty_state ();
    }

    public override bool empty_state () {
        var is_empty = base.empty_state ();
        if (image != null && is_empty)
            image.icon_name = get_icon ();

        return is_empty;
    }

    public virtual void on_refresh () {
        clear ();
        request ();
    }

    public virtual void on_account_changed (InstanceAccount? account) {
        if (account == null)
            return;

        last_id = account.last_seen_notification;
        force_dot = account.has_unread_notifications;
        on_refresh ();
    }

    public void request () {
        if (accounts.active == null) {
            empty_state ();
            return;
        }

        accounts.active.cached_notifications.@foreach (notification => {
            append (notification);
            return true;
        });

        // new Request.GET ("/api/v1/follow_requests")  //TODO: this
        // 	.with_account ()
        // 	.then_parse_array (node => {
		      //   var notification = API.Notification.parse_follow_request (node.get_object ());
		      //   append (notification);
        // 	})
        // 	.exec ();

        new Request.GET ("/api/v1/notifications")
        	.with_account ()
        	.with_param ("limit", "30")
        	.then_parse_array (node => {
				var notification = API.Notification.parse (node.get_object ());
				append (notification);
        	})
        	.exec ();

        empty_state ();
    }

}
