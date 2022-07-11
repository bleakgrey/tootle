using Gtk;

namespace Tootle {

	public errordomain Oopsie {
		USER,
		PARSING,
		INSTANCE,
		INTERNAL
	}

	public static Application app;

	public static Settings settings;
	public static AccountStore accounts;
	public static Network network;
	public static Streams streams;

	public static EntityCache entity_cache;
	public static ImageCache image_cache;

	public static bool start_hidden = false;

	public class Application : Gtk.Application {

		public Dialogs.MainWindow? main_window { get; set; }
		public Dialogs.NewAccount? add_account_window { get; set; }

		// These are used for the GTK Inspector
		public Settings app_settings { get {return Tootle.settings; } }
		public AccountStore app_accounts { get {return Tootle.accounts; } }
		public Network app_network { get {return Tootle.network; } }
		public Streams app_streams { get {return Tootle.streams; } }

		public signal void refresh ();
		public signal void toast (string title);

		public CssProvider css_provider = new CssProvider ();
		public CssProvider zoom_css_provider = new CssProvider (); //FIXME: Zoom not working

		public const GLib.OptionEntry[] app_options = {
			{ "hidden", 0, 0, OptionArg.NONE, ref start_hidden, "Do not show main window on start", null },
			{ null }
		};

		public const GLib.ActionEntry[] app_entries = {
			{ "about", about_activated },
			{ "compose", compose_activated },
			{ "back", back_activated },
			{ "refresh", refresh_activated },
			{ "search", search_activated },
		};

		construct {
			application_id = Build.DOMAIN;
			flags = ApplicationFlags.HANDLES_OPEN;
		}

		public string[] ACCEL_ABOUT = {"F1"};
		public string[] ACCEL_NEW_POST = {"<Ctrl>T"};
		public string[] ACCEL_BACK = {"<Alt>BackSpace", "<Alt>Left"};
		public string[] ACCEL_REFRESH = {"<Ctrl>R", "F5"};
		public string[] ACCEL_SEARCH = {"<Ctrl>F"};

		public static int main (string[] args) {
			Gtk.init ();
			try {
				var opt_context = new OptionContext ("- Options");
				opt_context.add_main_entries (app_options, null);
				opt_context.parse (ref args);
			}
			catch (GLib.OptionError e) {
				warning (e.message);
			}

			app = new Application ();
			return app.run (args);
		}

		protected override void startup () {
			base.startup ();
			try {
				Build.print_info ();
				Adw.init ();

				settings = new Settings ();
				streams = new Streams ();
				network = new Network ();
				entity_cache = new EntityCache ();
				image_cache = new ImageCache ();
				accounts = new SecretAccountStore();
				accounts.init ();

				css_provider.load_from_resource (@"$(Build.RESOURCES)app.css");
				StyleContext.add_provider_for_display (Gdk.Display.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
				StyleContext.add_provider_for_display (Gdk.Display.get_default (), zoom_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
			}
			catch (Error e) {
				var msg = _("Could not start application: %s").printf (e.message);
				inform (Gtk.MessageType.ERROR, _("Error"), msg);
				error (msg);
			}

			set_accels_for_action ("app.about", ACCEL_ABOUT);
			set_accels_for_action ("app.compose", ACCEL_NEW_POST);
			set_accels_for_action ("app.back", ACCEL_BACK);
			set_accels_for_action ("app.refresh", ACCEL_REFRESH);
			set_accels_for_action ("app.search", ACCEL_SEARCH);
			add_action_entries (app_entries, this);
		}

		protected override void activate () {
			present_window ();

			if (start_hidden) {
				start_hidden = false;
				return;
			}
		}

		public override void open (File[] files, string hint) {
			foreach (File file in files) {
				string uri = file.get_uri ();
				if (add_account_window != null)
					add_account_window.redirect (uri);
				else
					warning (@"Received an unexpected uri to open: $uri");
				return;
			}
		}

		public void present_window () {
			if (accounts.saved.is_empty) {
				message ("Presenting NewAccount dialog");
				if (add_account_window == null)
					new Dialogs.NewAccount ();
				add_account_window.present ();
			}
			else {
				message ("Presenting MainWindow");
				if (main_window == null)
					main_window = new Dialogs.MainWindow (this);
				main_window.present ();
			}
		}

		// TODO: Background mode
		// public bool on_window_closed () {
		// 	if (!settings.work_in_background || accounts.saved.is_empty)
		// 		app.remove_window (window_dummy);
		// 		return false;
		// }

		public void compose_activated () {
			new Dialogs.Compose ();
		}

		public void back_activated () {
			main_window.back ();
		}

		public void search_activated () {
			main_window.open_view (new Views.Search ());
		}

		public void refresh_activated () {
			refresh ();
		}

		public void about_activated () {
			var dialog = new AboutDialog () {
				transient_for = main_window,
				modal = true,

				logo_icon_name = Build.DOMAIN,
				program_name = Build.NAME,
				version = Build.VERSION,
				website = Build.SUPPORT_WEBSITE,
				website_label = _("Report an issue"),
				license_type = License.GPL_3_0_ONLY,
				copyright = Build.COPYRIGHT,
				system_information = Build.SYSTEM_INFO
			};

			// For some obscure reason, const arrays produce duplicates in the credits.
			// Static functions seem to avoid this peculiar behavior.
			dialog.authors = Build.get_authors ();
			dialog.artists = Build.get_artists ();
			dialog.translator_credits = Build.TRANSLATOR != " " ? Build.TRANSLATOR : null;

			dialog.present ();
		}

		public void inform (Gtk.MessageType type, string text, string? msg = null, Gtk.Window? win = main_window){
			var dlg = new Gtk.MessageDialog (
				win,
				Gtk.DialogFlags.MODAL,
				type,
				Gtk.ButtonsType.OK,
				null
			);
			dlg.text = text;
			dlg.secondary_text = msg;
			dlg.transient_for = win;
			// dlg.run ();
			dlg.destroy ();
		}

		public bool question (string text, string? msg = null, Gtk.Window? win = main_window) {
			var dlg = new Gtk.MessageDialog (
				win,
				Gtk.DialogFlags.MODAL,
				Gtk.MessageType.QUESTION,
				Gtk.ButtonsType.YES_NO,
				null
			);
			dlg.text = text;
			dlg.secondary_text = msg;
			dlg.transient_for = win;
			// var i = dlg.run ();
			dlg.destroy ();
			// return i == ResponseType.YES;
			return false;
		}

	}

}
