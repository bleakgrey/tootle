using GLib;
using Gee;

public class Tootle.InstanceAccount : API.Account, Streamable {

	public string? backend { set; get; }
	public string? instance { get; set; }
	public string? client_id { get; set; }
	public string? client_secret { get; set; }
	public string? access_token { get; set; }
	public Error? error { get; set; }

	public ArrayList<GLib.Notification> desktop_inbox { get; set; default = new ArrayList<GLib.Notification> (); }
	public int64 last_read_notification { get; set; default = 0; }
	public uint unread_notifications { get; set; default = 0; }

	public new string handle {
		owned get { return @"@$username@$domain"; }
	}

	construct {
		construct_streamable ();
		stream_event[Mastodon.Account.EVENT_NOTIFICATION].connect (on_notification);
	}

	public InstanceAccount.empty (string instance){
		Object (
			id: "",
			instance: instance
		);
	}
	~InstanceAccount () {
		destruct_streamable ();
	}

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



	// Streamable

	public string? _connection_url { get; set; }
	public bool subscribed { get; set; }

	public virtual string? get_stream_url () {
		return @"$instance/api/v1/streaming/?stream=user&access_token=$access_token";
	}

	public virtual void on_notification (Streamable.Event ev) {
		var obj = Entity.from_json (typeof (API.Notification), ev.get_node ()) as API.Notification;
		var toast = create_desktop_toast (obj);
		app.send_notification (obj.id.to_string (), toast);
	}

	// TODO: notification actions
	public virtual GLib.Notification create_desktop_toast (API.Notification obj) {
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

		return toast;
	}

}
