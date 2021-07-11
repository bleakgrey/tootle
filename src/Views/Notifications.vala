using Gtk;
using Gdk;

public class Tootle.Views.Notifications : Views.Timeline, AccountHolder, Streamable {

	protected InstanceAccount? last_account = null;

	//FIXME: Display unread dot
	public Notifications () {
		Object (
			url: "/api/v1/notifications",
			label: _("Notifications"),
			icon: "bell-symbolic"
		);
		accepts = typeof (API.Notification);
	}

	public override void on_account_changed (InstanceAccount? acc) {
		base.on_account_changed (acc);

		if (last_account != null) {
			last_account.toast_inhibitors.remove (this);
			acc.stream_event[Mastodon.Account.EVENT_NOTIFICATION].disconnect (on_new_post);
		}

		last_account = acc;
		acc.stream_event[Mastodon.Account.EVENT_NOTIFICATION].connect (on_new_post);
	}

	public override void on_shown () {
		base.on_shown ();
		if (account != null) {
			if (!account.toast_inhibitors.contains (this))
				account.toast_inhibitors.add (this);

			account.read_notifications ();
		}
	}
	public override void on_hidden () {
		base.on_hidden ();
		if (account != null) {
			if (account.toast_inhibitors.contains (this))
				account.toast_inhibitors.remove (this);
		}
	}

}
