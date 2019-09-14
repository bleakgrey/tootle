public interface Tootle.IAccountListener : GLib.Object {

	protected void connect_account_service () {
		accounts.notify["active"].connect (() => on_account_changed (accounts.active));
	}

	public virtual void on_account_changed (InstanceAccount? account) {}
	public virtual void on_available_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {}

}
