using Soup;
using Gee;

public class Tootle.Request : Soup.Message {

	public string url { set; get; }
	private Network.SuccessCallback? cb;
	private Network.ErrorCallback? error_cb;
	private HashMap<string, string>? pars;
	private weak InstanceAccount? account;
	private bool needs_token = false;

	public Request.GET (string url) {
		Object (method: "GET", url: url);
	}
	public Request.POST (string url) {
		Object (method: "POST", url: url);
	}
	public Request.PUT (string url) {
		Object (method: "PUT", url: url);
	}
	public Request.DELETE (string url) {
		Object (method: "DELETE", url: url);
	}

	public Request then (owned Network.SuccessCallback cb) {
		this.cb = (owned) cb;
		return this;
	}

	public Request then_parse_array (owned Network.NodeCallback _cb) {
		this.cb = (sess, msg) => {
			Network.parse_array (msg, (owned) _cb);
		};
		return this;
	}

	public Request then_parse_obj (owned Network.ObjectCallback _cb) {
		this.cb = (sess, msg) => {
			_cb (network.parse (msg));
		};
		return this;
	}

	public Request on_error (owned Network.ErrorCallback cb) {
		this.error_cb = (owned) cb;
		return this;
	}

	public Request with_account (InstanceAccount? account = null) {
		this.needs_token = true;
		if (account != null)
			this.account = account;
		return this;
	}

	public Request with_param (string name, string val) {
		if (pars == null)
			pars = new HashMap<string, string> ();
		pars[name] = val;
		return this;
	}

	// Should be used for requests with default priority
	public Request queue () {
		var parameters = "";
		if (pars != null) {
			if ("?" in url)
				parameters = "";
			else
				parameters = "?";

			var parameters_counter = 0;
			pars.@foreach (entry => {
				parameters_counter++;
				var key = (string) entry.key;
				var val = (string) entry.value;
				parameters += @"$key=$val";

				if (parameters_counter < pars.size)
					parameters += "&";

				return true;
			});
		}

		if (needs_token) {
			if (account == null) {
				warning (@"No account was specified or found for $method: $url$parameters");
				return this;
			}
			request_headers.append ("Authorization", @"Bearer $(account.access_token)");
		}

		if (!("://" in url))
			url = account.instance + url;

		uri = new URI (url + parameters);
		url = uri.to_string (false);
		message (@"$method: $url");

		network.queue (this, (owned) cb, (owned) error_cb);
		return this;
	}

	// Should be used for real-time user interactions (liking, removing and browsing posts)
	public Request exec () {
		this.priority = MessagePriority.HIGH;
		return this.queue ();
	}

	public async Request await () throws Error {
		string? error = null;
		this.error_cb = (code, reason) => {
			error = reason;
			await.callback ();
		};
		this.cb = (sess, msg) => {
			await.callback ();
		};
		this.queue ();
		yield;

		if (error != null)
			throw new Oopsie.INSTANCE (error);
		else
		return this;
	}

	public static string array2string (Gee.ArrayList<string> array, string key) {
		var result = "";
		array.@foreach (i => {
			result += @"$key[]=$i";
			if (array.index_of (i)+1 != array.size)
				result += "&";
			return true;
		});
		return result;
	}

}
