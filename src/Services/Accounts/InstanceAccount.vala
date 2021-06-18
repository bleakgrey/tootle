using GLib;
using Gee;

public class Tootle.InstanceAccount : API.Account, Streamable {

	public string? backend { set; get; }
	public string? instance { get; set; }
	public string? client_id { get; set; }
	public string? client_secret { get; set; }
	public string? access_token { get; set; }
	public Error? error { get; set; }

	public int64 last_seen_notification { get; set; default = 0; }
	public bool has_unread_notifications { get; set; default = false; }
	public ArrayList<API.Notification> cached_notifications { get; set; default = new ArrayList<API.Notification> (); }

	public new string handle {
		owned get { return @"@$username@$domain"; }
	}

	construct {
	    //TODO: Show notifications
		// on_notification.connect (show_notification);
		construct_streamable ();
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

	// TODO: notification actions
	void show_notification (API.Notification obj) {
		// var title = HtmlUtils.remove_tags (obj.kind.get_desc (obj.account));
		// var notification = new GLib.Notification (title);
		// if (obj.status != null) {
		// 	var body = "";
		// 	body += domain;
		// 	body += "\n";
		// 	body += HtmlUtils.remove_tags (obj.status.content);
		// 	notification.set_body (body);
		// }

		// app.send_notification (app.application_id + ":" + obj.id.to_string (), notification);
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

	public virtual void on_stream_event (Streamable.Event ev) {

	}

}
