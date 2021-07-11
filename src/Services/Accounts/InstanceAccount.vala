using GLib;
using Gee;

public class Tootle.InstanceAccount : API.Account, Streamable {

	public string? backend { set; get; }
	public string? instance { get; set; }
	public string? client_id { get; set; }
	public string? client_secret { get; set; }
	public string? access_token { get; set; }
	public Error? error { get; set; } //TODO: use this field when server invalidates the auth token

	public new string handle {
		owned get { return @"@$username@$domain"; }
	}

	public virtual signal void added () {
		subscribed = true;
		check_notifications ();
	}
	public virtual signal void removed () {
		subscribed = false;
	}

	public virtual signal void activated () {}
	public virtual signal void deactivated () {}


	construct {
		construct_streamable ();
		stream_event[Mastodon.Account.EVENT_NOTIFICATION].connect (on_notification);
	}
	~InstanceAccount () {
		destruct_streamable ();
	}

	public InstanceAccount.empty (string instance){
		Object (
			id: "",
			instance: instance
		);
	}



	// Core functions

	public bool is_current () {
		return accounts.active.access_token == access_token;
	}

	public async void verify_credentials () throws Error {
		var req = new Request.GET ("/api/v1/accounts/verify_credentials").with_account (this);
		yield req.await ();

		var node = network.parse_node (req);
		var updated = API.Account.from (node);
		patch (updated);

		message (@"$handle: profile updated");
	}

	public async Entity resolve (string url) throws Error {
		message (@"Resolving URL: \"$url\"...");
		var results = yield API.SearchResults.request (url, this);
		var entity = results.first ();
		message (@"Found $(entity.get_class ().get_name ())");
		return entity;
	}

	public virtual void populate_user_menu (GLib.ListStore model) {}

	public virtual void describe_kind (string kind, out string? icon, out string? descr, API.Account account) {
		icon = null;
		descr = null;
	}



	// Notifications

	public int unread_count { get; set; default = 0; }
	public int last_read_id { get; set; default = 0; }
	public ArrayList<GLib.Notification> unread_toasts { get; set; default = new ArrayList<GLib.Notification> (); }
	public ArrayList<Object> toast_inhibitors { get; set; default = new ArrayList<Object> (); }

	public virtual void check_notifications () {
		new Request.GET ("/api/v1/markers?timeline[]=notifications")
			.with_account (this)
			.then ((sess, msg) => {
				var root = network.parse (msg);
				var notifications = root.get_object_member ("notifications");
				last_read_id = int.parse (notifications.get_string_member ("last_read_id") );

				if (notifications.has_member ("pleroma")) {
					var pleroma = notifications.get_object_member ("pleroma");
					unread_count = (int)pleroma.get_int_member ("unread_count");
				}
			})
			.exec ();
	}

	public virtual void read_notifications () {
		message ("Read notifications");
		unread_count = 0;
		unread_toasts.@foreach (toast => {
			var id = toast.get_data<string> ("id");
			app.withdraw_notification (id);
			return true;
		});
	}



	// Streamable

	public string? _connection_url { get; set; }
	public bool subscribed { get; set; }

	public virtual string? get_stream_url () {
		return @"$instance/api/v1/streaming/?stream=user&access_token=$access_token";
	}

	public virtual void on_notification (Streamable.Event ev) {
		var obj = Entity.from_json (typeof (API.Notification), ev.get_node ()) as API.Notification;
		send_toast (obj);
	}

	// TODO: notification actions
	public void send_toast (API.Notification obj) {
		if (!toast_inhibitors.is_empty) return;

		string descr;
		describe_kind (obj.kind, null, out descr, obj.account);

		var toast = new GLib.Notification ( HtmlUtils.remove_tags (descr) );
		if (obj.status != null) {
			var body = "";
			body += HtmlUtils.remove_tags (obj.status.content);
			toast.set_body (body);
		}

		var file = GLib.File.new_for_uri (avatar);
		var icon = new FileIcon (file);
		toast.set_icon (icon);

		var id = obj.id.to_string ();
		toast.set_data<string> ("id", id);
		app.send_notification (id, toast);
		unread_toasts.add (toast);
	}

}
