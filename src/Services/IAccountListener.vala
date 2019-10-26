public interface Tootle.IAccountListener : GLib.Object {

	protected void connect_account_service () {
		accounts.notify["active"].connect (() => on_account_changed (accounts.active));
		accounts.saved.notify["size"].connect (() => on_accounts_changed (accounts.saved));
	}

	public virtual void on_account_changed (InstanceAccount? account) {}
	public virtual void on_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {}

}
