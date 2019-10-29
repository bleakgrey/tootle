using GLib;
using Soup;
using Gee;

public class Tootle.Streams : Object {

	public signal void notification (API.Notification n);
	public signal void status_removed (int64 id);

	protected HashTable<string, Connection> connections {
		get;
		set;
		default = new HashTable<string, Connection> (GLib.str_hash, GLib.str_equal);
	}

	protected class Connection : Object {
		public ArrayList<IStreamListener> subscribers;
		protected WebsocketConnection? socket;
		protected Message msg;

		protected bool closing = false;
		protected int timeout = 2;

		public string name {
			owned get {
				var url = msg.get_uri ().to_string (false);
				return url.slice (0, url.last_index_of ("&access_token"));
			}
		}

		public Connection (IStreamListener s, string url) {
			this.subscribers = new ArrayList<IStreamListener> ();
			this.subscribers.add (s);
			this.msg = new Message ("GET", url);
		}

		public bool start () {
			info (@"Connecting: $name");
			network.session.websocket_connect_async.begin (msg, null, null, null, (obj, res) => {
				socket = network.session.websocket_connect_async.end (res);
				socket.error.connect (on_error);
				socket.closed.connect (on_closed);
				socket.message.connect (on_message);
			});
			return false;
		}

		public void add (IStreamListener s) {
			info (@"Subscribing: $name");
			subscribers.add (s);
		}

		public void remove (IStreamListener s) {
			if (subscribers.contains (s)) {
				info (@"Unsubscribing: $name");
				subscribers.remove (s);
			}

			if (subscribers.size <= 0) {
				info (@"Closing: $name");
				closing = true;
				socket.close (0, null);
			}
		}

		void on_error (Error e) {
			warning (@"Error in $name: $(e.message)");
		}

		void on_closed () {
			if (closing)
				return;

			warning (@"CLOSED: $name. Reconnecting in $timeout seconds.");
			GLib.Timeout.add_seconds (timeout, start);
			timeout = int.min (timeout*2, 30);
		}

		void on_message (int i, Bytes bytes) {
			try {
				emit (bytes, this);
			}
			catch (Error e) {
				warning (@"Couldn't handle websocket event. Reason: $(e.message)");
			}
		}
	}

	public void subscribe (string? url, IStreamListener subscriber, out string stream) {
		if (url == null)
			return;

		if (connections.contains (url)) {
			connections[url].add (subscriber);
		}
		else {
			var con = new Connection (subscriber, url);
			connections[url] = con;
			con.start ();
		}
		stream = url;
	}

	public void unsubscribe (string? url, IStreamListener subscriber) {
		if (url == null)
			return;

		if (connections.contains (url))
			connections.@get (url).remove (subscriber);
	}

	static void decode (Bytes bytes, out string event, out Json.Object root) throws Error {
		var msg = (string) bytes.get_data ();
		var parser = new Json.Parser ();
		parser.load_from_data (msg, -1);
		root = parser.get_root ().get_object ();
		event = root.get_string_member ("event");
	}

	static Json.Object sanitize (Json.Object root) {
		var payload = root.get_string_member ("payload");
		var sanitized = Soup.URI.decode (payload);
		var parser = new Json.Parser ();
		parser.load_from_data (sanitized, -1);
		return parser.get_root ().get_object ();
	}

	static void emit (Bytes bytes, Connection c) throws Error {
		if (!settings.live_updates)
			return;

		string event;
		Json.Object root;
		decode (bytes, out event, out root); warning (@"$event for $(c.name)");

		switch (event) {
			case "update":
				var entity = API.Status.parse (sanitize (root));
				c.subscribers.@foreach (s => { 
					s.on_status_added (entity);
					return false;
				});
				break;
			case "delete":
				var id = int64.parse (root.get_string_member ("payload"));
				c.subscribers.@foreach (s => { 
					s.on_status_removed (id);
					return false;
				});
				break;
			case "notification":
				var entity = API.Notification.parse (sanitize (root));
				c.subscribers.@foreach (s => { 
					s.on_notification (entity);
					return false;
				});
				break;
			default:
				warning (@"Unknown websocket event: \"$event\". Ignoring.");
				break;
		}
	}

}
