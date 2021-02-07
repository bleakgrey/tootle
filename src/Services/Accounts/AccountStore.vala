using Gee;

public abstract class Tootle.AccountStore : GLib.Object {

	public ArrayList<InstanceAccount> saved { get; set; default = new ArrayList<InstanceAccount> (); }
	public InstanceAccount? active { get; set; default = null; }

	public bool ensure_active_account () {
		var has_active = false;

		if (!saved.is_empty) {
			if (settings.current_account > saved.size || settings.current_account <= 0)
				settings.current_account = 0;

			var last_account = saved[settings.current_account];
			if (active != last_account) {
				activate (last_account);
				has_active = true;
			}
		}

		if (!has_active)
			app.present_window ();

		return has_active;
	}

	public virtual void init () throws GLib.Error {
		load ();
		ensure_active_account ();
	}

	public abstract void load () throws GLib.Error;
	public abstract void save () throws GLib.Error;
	public void safe_save () {
		try {
			save ();
		}
		catch (GLib.Error e) {
			warning (e.message);
			app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
		}
	}

	public virtual void add (InstanceAccount account) throws GLib.Error {
		message (@"Adding new account: $(account.handle)");
		saved.add (account);
		save ();
		account.subscribe ();
		ensure_active_account ();
	}

	public virtual void remove (InstanceAccount account) throws GLib.Error {
		message (@"Removing account: $(account.handle)");
		account.unsubscribe ();
		saved.remove (account);
		saved.notify_property ("size");
		save ();

		var id = settings.current_account - 1;
		if (saved.size < 1)
			active = null;
		else {
			if (id > saved.size - 1)
				id = saved.size - 1;
			else if (id < saved.size - 1)
				id = 0;
		}
		settings.current_account = id;

		ensure_active_account ();
	}

	public void activate (InstanceAccount account) {
		message (@"Activating $(account.handle)...");
		account.probe.begin ((obj, res) => {
			try {
				account.probe.end (res);
				account.error = null;
			}
			catch (Error e) {
				warning (@"Couldn't activate account $(account.handle):");
				warning (e.message);
				account.error = e;
			}
		});

		accounts.active = account;
		settings.current_account = accounts.saved.index_of (account);
	}

}
