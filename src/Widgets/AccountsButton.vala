using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/accounts_button.ui")]
public class Tootle.Widgets.AccountsButton : Gtk.MenuButton, IAccountListener {

    [GtkChild]
    private Widgets.Avatar avatar;
    [GtkChild]
    private Spinner spinner;

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
    }

    public virtual void on_available_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {
    	//TODO: account list
    }

    public virtual void on_account_changed (InstanceAccount? account) {
    	avatar.url = account == null ? null : account.avatar;
    }

}
