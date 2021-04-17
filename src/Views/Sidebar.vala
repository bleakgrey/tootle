using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/view.ui")]
public class Tootle.Views.Sidebar : Box {

	[GtkChild] unowned ToggleButton accounts_button;
	[GtkChild] unowned Stack mode;
	[GtkChild] unowned ListBox items;
	[GtkChild] unowned ListBox saved_accounts;

	[GtkChild] unowned Widgets.Avatar avatar;
	[GtkChild] unowned Label title;
	[GtkChild] unowned Label subtitle;

	GLib.ListStore item_model = new GLib.ListStore (typeof (Object));

	Item item_preferences = new Item () {
			label = _("Preferences"),
			icon = "emblem-system-symbolic",
			selectable = false,
			separated = true,
			on_activated = () => {
				Dialogs.Preferences.open ();
			}
	};
	Item item_about = new Item () {
			label = _("About"),
			icon = "help-about-symbolic",
			selectable = false,
			on_activated = () => {
				app.lookup_action ("about").activate (null);
			}
	};

	construct {
		accounts.switched.connect (on_account_switch);
		on_account_switch (accounts.active);

		items.bind_model (item_model, on_item_create);
		items.set_header_func (on_item_header_update);
		saved_accounts.bind_model (accounts.model, on_account_create);
	}

	void on_account_switch (InstanceAccount? account) {
		warning (account.handle);
		item_model.remove_all ();

		if (account != null) {
			uint id;
			accounts.model.find (account, out id);
			var row = saved_accounts.get_row_at_index ((int)id);
			saved_accounts.select_row (row);
			warning (@"Selecting row: $id");

			title.label = account.display_name;
			subtitle.label = account.handle;
			avatar.account = account;

			account.populate_user_menu (item_model);
		}
		else {
			saved_accounts.unselect_all ();

			title.label = _("Anonymous");
			subtitle.label = _("No account selected");
			avatar.account = null;
		}

		item_model.append (item_preferences);
		item_model.append (item_about);
	}

	[GtkCallback]
	void on_mode_changed () {
		mode.visible_child_name = accounts_button.active ? "saved_accounts" : "items";
	}



	// Item

	public class Item : Object {
		public VoidFunc? on_activated;
		public string label { get; set; default = ""; }
		public string icon { get; set; default = ""; }
		public int badge { get; set; default = 0; }
		public bool selectable { get; set; default = false; }
		public bool separated { get; set; default = false; }
	}

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/item.ui")]
	protected class ItemRow : ListBoxRow {
		public Item item;

		[GtkChild] unowned Image icon;
		[GtkChild] unowned Label label;
		[GtkChild] unowned Label badge;

		public ItemRow (Item _item) {
			item = _item;
			item.bind_property ("label", label, "label", BindingFlags.SYNC_CREATE);
			item.bind_property ("icon", icon, "icon-name", BindingFlags.SYNC_CREATE);
			item.bind_property ("badge", badge, "label", BindingFlags.SYNC_CREATE);
			item.bind_property ("badge", badge, "visible", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
				target.set_boolean (src.get_int () > 0);
				return true;
			});
			bind_property ("selectable", item, "selectable", BindingFlags.SYNC_CREATE);
		}
	}

	Widget on_item_create (Object obj) {
		return new ItemRow (obj as Item);
	}

	[GtkCallback]
	void on_item_activated (ListBoxRow _row) {
		var row = _row as ItemRow;
		if (row.item.on_activated != null)
			row.item.on_activated ();
	}

	void on_item_header_update (ListBoxRow _row, ListBoxRow? _before) {
		var row = _row as ItemRow;
		var before = _before as ItemRow;

		row.set_header (null);

		if (row.item.separated && before != null && !before.item.separated) {
			row.set_header (new Separator (Orientation.HORIZONTAL));
		}
	}



	// Account

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/account.ui")]
	protected class AccountRow : Adw.ActionRow {
		InstanceAccount? account;

		[GtkChild] unowned Widgets.Avatar avatar;
		[GtkChild] unowned Spinner loading;

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
			}
		}

	}

	Widget on_account_create (Object obj) {
		return new AccountRow (obj as InstanceAccount);
	}

	[GtkCallback]
	void on_account_activated (ListBoxRow _row) {
		var row = _row as AccountRow;
		warning ("switching to account");
	}

}
