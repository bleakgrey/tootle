using Soup;
using Gee;

public class Tootle.Request : Soup.Message {

	public string url { construct set; get; }
	private Network.SuccessCallback? cb;
	private Network.ErrorCallback? error_cb;
	private HashMap<string, string>? pars;
	private weak InstanceAccount? account;

	public Request.GET (string url) {
		Object (method: "GET", url: url);
	}
	public Request.POST (string url) {
		Object (method: "POST", url: url);
	}
	public Request.DELETE (string url) {
		Object (method: "DELETE", url: url);
	}
	
	public Request then (owned Network.SuccessCallback cb) {
		this.cb = (owned) cb;
		return this;
	}
	
	public Request on_error (owned Network.ErrorCallback cb) {
		this.error_cb = (owned) cb;
		return this;
	}
	
	public Request with_account (InstanceAccount? account = null) {
		if (account == null)
			account = accounts.active;
		else
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
		if (account != null && account.id >= 0) {
			request_headers.append ("Authorization", @"Bearer $(account.token)");
		}
		
		var parameters = "";
		if (pars != null) {
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
		
		warning (@"$method: $url$parameters");
		this.uri = new URI (account.instance + "" + url + parameters);
		network.queue (this, (owned) cb, (owned) error_cb);
		return this;
	}

	// Should be used for real-time user interactions (liking, removing and browsing posts)
	public Request exec () {
		this.priority = MessagePriority.HIGH;
		return this.queue ();
	}

}
