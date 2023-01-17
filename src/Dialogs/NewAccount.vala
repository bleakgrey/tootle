using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/new_account.ui")]
public class Tootle.Dialogs.NewAccount: Adw.Window {

	const string scopes = "read write follow";

	protected bool is_working { get; set; default = false; }
	protected string? redirect_uri { get; set; }
	protected bool use_auto_auth { get; set; default = true; }
	protected InstanceAccount account { get; set; default = new InstanceAccount.empty (""); }

	[GtkChild] unowned Adw.Leaflet deck;
	[GtkChild] unowned Box instance_step;
	[GtkChild] unowned Box code_step;
	[GtkChild] unowned Box done_step;

	[GtkChild] unowned Entry instance_entry;
	[GtkChild] unowned Entry code_entry;
	[GtkChild] unowned Label code_label;
	[GtkChild] unowned Adw.StatusPage done_page;

	public NewAccount () {
		Object (transient_for: app.main_window);
		app.add_account_window = this;
		app.add_window (this);
		// StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), app.css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		reset ();
		present ();

		bind_property ("use-auto-auth", code_label, "visible", BindingFlags.SYNC_CREATE);
	}

	public override bool close_request () {
		warning ("CLose Request");
		app.add_account_window = null;
		return base.close_request ();
	}

	string setup_redirect_uri () {
		try {
			if (!use_auto_auth)
				throw new Oopsie.INTERNAL ("Using manual auth method");

			GLib.Process.spawn_command_line_sync (@"xdg-mime default $(Build.DOMAIN).desktop x-scheme-handler/tootle");

			message ("Successfully associated MIME type for automatic authorization");
			return "tootle://auth_code";
		}
		catch (Error e) {
			warning (e.message);
			use_auto_auth = false;
			return "urn:ietf:wg:oauth:2.0:oob";
		}
	}

	[GtkCallback]
	bool on_activate_code_label_link (string uri) {
		use_auto_auth = false;
		reset ();
		return true;
	}

	void reset () {
		message ("Reset state");
		account = new InstanceAccount.empty (account.instance);
		deck.visible_child = instance_step;
	}

	void oopsie (string title, string msg = "") {
		warning (@"$title   $msg");
		app.inform (Gtk.MessageType.ERROR, title, msg, this);
	}

	async void step () throws Error {
		if (deck.visible_child == done_step) {
			app.present_window ();
			destroy ();
			return;
		}

		if (deck.visible_child == instance_step) {
			setup_instance ();
			yield accounts.guess_backend (account);
		}

		if (account.client_secret == null || account.client_id == null) {
			yield register_client ();
			return;
		}

		yield request_token ();
	}

	void setup_instance () throws Error {
		message ("Checking instance URL");

		var str = instance_entry.text
			.replace ("/", "")
			.replace (":", "")
			.replace ("https", "")
			.replace ("http", "");
		account.instance = "https://"+str;
		instance_entry.text = str;

		if (str.char_count () <= 0 || !("." in account.instance))
			throw new Oopsie.USER (_("Please enter a valid instance URL"));
	}

	async void register_client () throws Error {
		message ("Registering client");

		var msg = new Request.POST (@"/api/v1/apps")
			.with_account (account)
			.with_form_data ("client_name", Build.NAME)
			.with_form_data ("redirect_uris", redirect_uri = setup_redirect_uri ())
			.with_form_data ("scopes", scopes)
			.with_form_data ("website", Build.WEBSITE);
		yield msg.await ();

		var root = network.parse (msg);
		account.client_id = root.get_string_member ("client_id");
		account.client_secret = root.get_string_member ("client_secret");
		message ("OK: Instance registered client");

		deck.visible_child = code_step;
		open_confirmation_page ();
	}

	void open_confirmation_page () {
		message ("Opening permission request page");

		var pars = @"scope=$scopes&response_type=code&redirect_uri=$redirect_uri&client_id=$(account.client_id)";
		var url = @"$(account.instance)/oauth/authorize?$pars";
		Host.open_uri (url);
	}

	async void request_token () throws Error {
		if (code_entry.text.char_count () <= 10)
			throw new Oopsie.USER (_("Please enter a valid authorization code"));

		message ("Requesting access token");
		var token_req = new Request.POST (@"/oauth/token")
			.with_account (account)
			.with_param ("client_id", account.client_id)
			.with_param ("client_secret", account.client_secret)
			.with_param ("redirect_uri", redirect_uri)
			.with_param ("grant_type", "authorization_code")
			.with_param ("code", code_entry.text);
		yield token_req.await ();

		var root = network.parse (token_req);
		account.access_token = root.get_string_member ("access_token");

		if (account.access_token == null)
			throw new Oopsie.INSTANCE (_("Instance failed to authorize the access token"));

		yield account.verify_credentials ();

		account = accounts.create_account (account.to_json ());

		message ("Saving account");
		accounts.add (account);

		done_page.title = _("Hello, %s!").printf (account.handle);
		deck.visible_child = done_step;

		message ("Switching to account");
		accounts.activate (account);
	}

	public void redirect (string uri) {
		present ();
		message (@"Received uri: $uri");

		var query = new Soup.URI (uri).get_query ();
		var split = query.split ("=");
		var code = split[1];

		code_entry.text = code;
		is_working = false;
		on_next_clicked ();
	}

	[GtkCallback]
	void on_next_clicked () {
		if (is_working) return;

		is_working = true;
		step.begin ((obj, res) => {
			try {
				step.end (res);
			}
			catch (Oopsie.INSTANCE e) {
				oopsie (_("Server returned an error"), e.message);
			}
			catch (Error e) {
				oopsie (e.message);
			}
			is_working = false;
		});
	}

	[GtkCallback]
	void on_back_clicked () {
		reset ();
	}

	[GtkCallback]
	void on_visible_child_notify () {
		if (!deck.child_transition_running && deck.visible_child == instance_step)
			reset ();

		deck.can_navigate_back = deck.visible_child != done_step;
	}

}

