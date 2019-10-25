using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/accounts_button.ui")]
public class Tootle.Widgets.AccountsButton : Gtk.MenuButton, IAccountListener {

    [GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/accounts_button_item.ui")]
    private class Item : Grid {

        [GtkChild]
        private Label name;
        [GtkChild]
        private Label handle;

        public Item (InstanceAccount acc) {
            name.label = acc.display_name;
            handle.label = acc.handle;
        }
    }

    private bool invalidated = true;

    [GtkChild]
    private Widgets.Avatar avatar;
    [GtkChild]
    private Spinner spinner;

    [GtkChild]
    private ListBox account_list;

    [GtkChild]
    private ModelButton item_prefs;
    [GtkChild]
    private ModelButton item_refresh;
    [GtkChild]
    private ModelButton item_search;
    [GtkChild]
    private ModelButton item_favs;
    [GtkChild]
    private ModelButton item_direct;
    [GtkChild]
    private ModelButton item_watchlist;

    construct {
        connect_account_service ();

        item_refresh.clicked.connect (() => app.refresh ());
        Desktop.set_hotkey_tooltip (item_refresh, null, app.ACCEL_REFRESH);

        item_favs.clicked.connect (() => window.open_view (new Views.Favorites ()));
        item_direct.clicked.connect (() => window.open_view (new Views.Direct ()));
        item_search.clicked.connect (() => window.open_view (new Views.Search ()));
        item_watchlist.clicked.connect (() => Dialogs.WatchlistEditor.open ());
        item_prefs.clicked.connect (() => Dialogs.Preferences.open ());
        
        network.started.connect (() => spinner.show ());
        network.finished.connect (() => spinner.hide ());
        
        notify["active"].connect (() => {
            if (active && invalidated)
                rebuild ();
        });
    }

    public virtual void on_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {
    	invalidated = true;
    	warning ("INVALIDATED");
    	if (active)
    	    rebuild ();
    }

    public virtual void on_account_changed (InstanceAccount? account) {
    	avatar.url = account == null ? null : account.avatar;
    }

    private void rebuild () {
        account_list.@foreach (w => account_list.remove (w));
        accounts.saved.@foreach (acc => {
            var item = new Item (acc);
            account_list.insert (item, -1);
            return true;
        });

        invalidated = false;
    }

}
