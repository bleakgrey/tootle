using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/view.ui")]
public class Tootle.Views.Sidebar : Box, AccountHolder {

	[GtkChild] unowned ToggleButton accounts_button;
	[GtkChild] unowned Stack mode;
	[GtkChild] unowned ListBox items;
	[GtkChild] unowned ListBox saved_accounts;

	[GtkChild] unowned Widgets.Avatar avatar;
	[GtkChild] unowned Label title;
	[GtkChild] unowned Label subtitle;

	protected InstanceAccount? account { get; set; default = null; }

	protected GLib.ListStore app_items;
	protected SliceListModel account_items;
	protected FlattenListModel item_model;

	public static Place PREFERENCES = new Place () {
			title = _("Preferences"),
			icon = "emblem-system-symbolic",
			//selectable = false,
			separated = true,
			open_func = () => {
				Dialogs.Preferences.open ();
			}
	};
	public static Place ABOUT = new Place () {
			title = _("About"),
			icon = "help-about-symbolic",
			//selectable = false,
			open_func = () => {
				app.lookup_action ("about").activate (null);
			}
	};

	construct {
		app_items = new GLib.ListStore (typeof (Place));
		app_items.append (PREFERENCES);
		app_items.append (ABOUT);

		account_items = new SliceListModel (null, 0, 15);

		var models = new GLib.ListStore (typeof (Object));
		models.append (account_items);
		models.append (app_items);
		item_model = new FlattenListModel (models);

		items.bind_model (item_model, on_item_create);
		items.set_header_func (on_item_header_update);
		saved_accounts.set_header_func (on_account_header_update);

		construct_account_holder ();
	}

	protected virtual void on_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {
		for (var w = saved_accounts.get_first_child (); w != null; w = w.get_next_sibling ()) {
			saved_accounts.remove (w);
		}

		accounts.foreach (acc => {
			saved_accounts.append (new AccountRow (acc));
			return true;
		});

		var new_acc_row = new AccountRow (null);
		saved_accounts.append (new_acc_row);
	}

	protected virtual void on_account_changed (InstanceAccount? account) {
		this.account = account;
		accounts_button.active = false;

		if (account != null) {
			title.label = account.display_name;
			subtitle.label = account.handle;
			avatar.account = account;
			account_items.model = account.known_places;
		}
		else {
			saved_accounts.unselect_all ();

			title.label = _("Anonymous");
			subtitle.label = _("No account selected");
			avatar.account = null;
			account_items.model = null;
		}
	}

	[GtkCallback] void on_mode_changed () {
		mode.visible_child_name = accounts_button.active ? "saved_accounts" : "items";
	}

	[GtkCallback] void on_open () {
		if (account != null)
			account.open ();
	}


	// Item

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/item.ui")]
	protected class ItemRow : ListBoxRow {
		public Place place;

		[GtkChild] unowned Image icon;
		[GtkChild] unowned Label label;
		[GtkChild] unowned Label badge;

		public ItemRow (Place place) {
			this.place = place;
			place.bind_property ("title", label, "label", BindingFlags.SYNC_CREATE);
			place.bind_property ("icon", icon, "icon-name", BindingFlags.SYNC_CREATE);
			place.bind_property ("badge", badge, "label", BindingFlags.SYNC_CREATE);
			place.bind_property ("badge", badge, "visible", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
				target.set_boolean (src.get_int () > 0);
				return true;
			});
		// 	bind_property ("selectable", item, "selectable", BindingFlags.SYNC_CREATE);
		}
	}

	Widget on_item_create (Object obj) {
		return new ItemRow (obj as Place);
	}

	[GtkCallback] void on_item_activated (ListBoxRow _row) {
		var row = _row as ItemRow;
		if (row.place.open_func != null)
			row.place.open_func (app.main_window);

        var flap = app.main_window.flap;
        if (flap.folded)
		    flap.reveal_flap = false;
	}

	void on_item_header_update (ListBoxRow _row, ListBoxRow? _before) {
		var row = _row as ItemRow;
		var before = _before as ItemRow;

		row.set_header (null);

		if (row.place.separated && before != null && !before.place.separated) {
			row.set_header (new Separator (Orientation.HORIZONTAL));
		}
	}



	// Account

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/account.ui")]
	protected class AccountRow : Adw.ActionRow {
		public InstanceAccount? account;

		[GtkChild] unowned Widgets.Avatar avatar;
		[GtkChild] unowned Button forget;

		public AccountRow (InstanceAccount? _account) {
			account = _account;
			if (account != null) {
				title = account.display_name;
				subtitle = account.handle;
				avatar.account = account;
			}
			else {
				title = _("Add Account");
				avatar.account = null;
				selectable = false;
				forget.hide ();
			}
		}

		[GtkCallback] void on_open () {
			if (account != null) {
				account.resolve_open (accounts.active);
			}
		}

		[GtkCallback] void on_forget () {
			var confirmed = app.question (
				_("Forget %s?".printf (account.handle)),
				_("This account will be removed from the application."),
				app.main_window
			);
			if (confirmed) {
				try {
					accounts.remove (account);
				}
				catch (Error e) {
					warning (e.message);
					app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
				}
			}
		}

	}

	void on_account_header_update (ListBoxRow _row, ListBoxRow? _before) {
		var row = _row as AccountRow;

		row.set_header (null);

		if (row.account == null && _before != null)
			row.set_header (new Separator (Orientation.HORIZONTAL));
	}

	[GtkCallback] void on_account_activated (ListBoxRow _row) {
		var row = _row as AccountRow;
		if (row.account != null)
			accounts.activate (row.account);
		else
			new Dialogs.NewAccount ().present ();
	}

}
