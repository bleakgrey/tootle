using Gtk;

public class Tootle.Views.NewAccount : Views.Abstract {

	private string? instance { get; set; }
	private string? code { get; set; }

	private string? client_id { get; set; }
	private string? client_secret { get; set; }
	private string? access_token { get; set; }
	private string redirect_uri { get; set; default = "urn:ietf:wg:oauth:2.0:oob"; } //TODO: Investigate URI handling for automatic token getting

	private Button next_button;
	private Entry instance_entry;
	private Entry code_entry;
	private Label reset_label;

	private Stack stack;
	private Widget step1;
	private Widget step2;

	public NewAccount (bool allow_closing = true) {
		base ();
		this.allow_closing = allow_closing;

		var builder = new Builder.from_resource (@"$(Build.RESOURCES)ui/views/new_account.ui");
		content.pack_start (builder.get_object ("wizard") as Grid);
		next_button = builder.get_object ("next") as Button;
		reset_label = builder.get_object ("reset") as Label;
		instance_entry = builder.get_object ("instance_entry") as Entry;
		code_entry = builder.get_object ("code_entry") as Entry;

		stack = builder.get_object ("stack") as Stack;
		step1 = builder.get_object ("step1") as Widget;
		step2 = builder.get_object ("step2") as Widget;

		next_button.clicked.connect (on_next_clicked);
		reset_label.activate_link.connect (reset);
		instance_entry.text = "https://mastodon.social/"; //TODO: REMOVE ME
	}

	private bool reset () {
		debug ("Resetting instance state");
		instance = code = client_id = client_secret = access_token = null;
		instance_entry.sensitive = true;
		stack.visible_child = step1;
		return true;
	}

	private void oopsie (string message) {
		warning (message);
	}

	private void on_next_clicked () {
		try {
			step ();
		}
		catch (Oopsie e) {
			oopsie (e.message);
		}
	}

	private void step () throws Error {
		if (instance == null)
			setup_instance ();

		if (client_secret == null || client_id == null) {
			register_client ();
			return;
		}

		code = code_entry.text;
		request_token ();
	}

	private void setup_instance () throws Error {
		debug ("Checking instance URL");

		var str = instance_entry.text
			.replace ("/", "")
			.replace (":", "")
			.replace ("https", "")
			.replace ("http", "");
		instance = "https://"+str;
		instance_entry.text = str;

		if (str.char_count () <= 0 || !("." in instance))
			throw new Oopsie.USER (_("Instance URL is invalid"));
	}

	private void register_client () throws Error {
		debug ("Registering client");

        var pars = @"client_name=$(Build.NAME)&website=$(Build.WEBSITE)&scopes=read%20write%20follow&redirect_uris=$redirect_uri";
        var url = @"$instance/api/v1/apps?$pars";
		var message = new Soup.Message ("POST", url);
		instance_entry.sensitive = false;

		network.queue (message, (sess, msg) => {
			var root = network.parse (msg);
			client_id = root.get_string_member ("client_id");
			client_secret = root.get_string_member ("client_secret");
			debug ("OK: instance registered client");
			stack.visible_child = step2;

			open_confirmation_page ();
		}, (status, reason) => {
			oopsie (reason);
			instance_entry.sensitive = true;
		});
	}

	private void open_confirmation_page () {
		debug ("Opening permission request page");

		var pars = @"scope=read%20write%20follow&response_type=code&redirect_uri=$redirect_uri&client_id=$client_id";
		var url = @"$instance/oauth/authorize?$pars";
		Desktop.open_uri (url);
	}

	private void request_token () throws Error {
		if (code.char_count () <= 10)
			throw new Oopsie.USER (_("Please paste a valid authorization code"));

		debug ("Requesting access token");

		var pars = @"client_id=$client_id&client_secret=$client_secret&redirect_uri=$redirect_uri&grant_type=authorization_code&code=$code";
		var url = @"$instance/oauth/token?$pars";
        var message = new Soup.Message ("POST", url);

        network.queue (message, (sess, msg) => {
        	var root = network.parse (msg);
        	access_token = root.get_string_member ("access_token");
        	debug ("OK: received access token");
        	request_profile ();
        }, (status, reason) => {
        	oopsie (reason);
        });
	}

	private void request_profile () throws Error {
		debug ("Testing received access token");
		var message = new Soup.Message ("GET", @"$instance/api/v1/accounts/verify_credentials");
		message.request_headers.append ("Authorization", @"Bearer $access_token");

		network.queue (message, (sess, msg) => {
			var root = network.parse (msg);
			var account = API.Account.parse (root);
			debug ("OK: received user profile");
			save (account);
		}, (status, reason) => {
			reset ();
			oopsie (reason);
		});
	}

	private void save (API.Account account) {
		debug ("Saving account");
		InstanceAccount saved = new InstanceAccount.from_account (account);
		saved.instance = instance;
		saved.client_id = client_id;
		saved.client_secret = client_secret;
		saved.token = access_token;
		//accounts.add (saved);

		destroy ();
	}

}
