using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/view.ui")]
public class Tootle.Views.Sidebar : Box {

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/action.ui")]
	public class Action : ListBoxRow {

	}

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/account.ui")]
	public class Account : Adw.ActionRow {
		InstanceAccount account;

		[GtkChild] unowned Widgets.Avatar avatar;
		[GtkChild] unowned Spinner loading;

		public Account (InstanceAccount _account) {
			account = _account;
			title = account.display_name;
			subtitle = account.handle;
			avatar.account = account;
		}

	}



	[GtkChild] unowned Stack mode;
	[GtkChild] unowned ListBox saved_accounts;
	[GtkChild] unowned ToggleButton accounts_button;

	construct {
		accounts.switched.connect (on_account_switch);
		saved_accounts.bind_model (accounts.model, on_create_account_widget);
	}

	Widget on_create_account_widget (Object obj) {
		var account = obj as InstanceAccount;
		var widget = new Account (account);
		return widget;
	}

	[GtkCallback]
	void on_account_selected () {
		var id = saved_accounts.get_selected_row ().get_index ();
	}

	void on_account_switch (InstanceAccount? account) {

	}

	[GtkCallback]
	void on_action_selected () {
		// var id = saved_accounts.get_selected_row ().get_index ();
	}

	[GtkCallback]
	void on_mode_changed () {
		mode.visible_child_name = accounts_button.active ? "saved_accounts" : "actions";
	}

}
