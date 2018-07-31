using Gtk;
using Tootle;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/new_account_dialog.ui")]
public class Tootle.NewAccountDialog : Gtk.Dialog {

    private static NewAccountDialog dialog;

    [GtkChild]
    private Gtk.Grid grid;
    [GtkChild]
    private Gtk.Entry instance_entry;
    [GtkChild]
    private Gtk.Label instance_register;
    [GtkChild]
    private Gtk.Label code_name;
    [GtkChild]
    private Gtk.Entry code_entry;

    private string? instance;
    private string? client_id;
    private string? client_secret;
    private string? code;
    private string? token;
    private string? username;

    public NewAccountDialog () {
        Object (
            transient_for: window
        );
        
        instance_register.set_markup("<a href=\"https://joinmastodon.org/\">%s</a>".printf (_("What's an instance?")));
        
        destroy.connect (() => {
            dialog = null;
            
            if (accounts.is_empty ())
                app.remove_window (window_dummy);
        });
    }
    
    [GtkCallback]
    private void on_done_clicked () {
        instance = "https://" + instance_entry.text
            .replace ("/", "")
            .replace (":", "")
            .replace ("http", "")
            .replace ("https", "");
        code = code_entry.text;
            
        if (this.client_id == null || this.client_secret == null) {
            request_client_tokens ();
            return;
        }
        
        if (code == "")
            app.error (_("Error"), _("Please paste valid instance authorization code"));
        else
            try_auth (code);
    }

    private bool show_error (Soup.Message msg) {
        if (msg.status_code != Soup.Status.OK) {
            var phrase = Soup.Status.get_phrase (msg.status_code);
            app.error (_("Network Error"), phrase);
            return true;
        }
        return false;
    }

    private void request_client_tokens (){
        var pars = "?client_name=Tootle";
        pars += "&redirect_uris=urn:ietf:wg:oauth:2.0:oob";
        pars += "&website=https://github.com/bleakgrey/tootle";
        pars += "&scopes=read%20write%20follow";

        grid.sensitive = false;
        var msg = new Soup.Message ("POST", "%s/api/v1/apps%s".printf (instance, pars));
        msg.finished.connect (() => {
            grid.sensitive = true;
            if (show_error (msg)) return;
            
            var root = network.parse (msg);
            var id = root.get_string_member ("client_id");
            var secret = root.get_string_member ("client_secret");
            client_id = id;
            client_secret = secret;
            
            info ("Received tokens from %s", instance);
            request_auth_code ();
            code_name.show ();
            code_entry.show ();
        });
        network.queue_custom (msg);
    }
    
    private void request_auth_code (){
        var pars = "?scope=read%20write%20follow";
        pars += "&response_type=code";
        pars += "&redirect_uri=urn:ietf:wg:oauth:2.0:oob";
        pars += "&client_id=" + client_id;
        
        info ("Requesting auth token");
        Desktop.open_uri ("%s/oauth/authorize%s".printf (instance, pars));
    }
    
    private void try_auth (string code){
        var pars = "?client_id=" + client_id;
        pars += "&client_secret=" + client_secret;
        pars += "&redirect_uri=urn:ietf:wg:oauth:2.0:oob";
        pars += "&grant_type=authorization_code";
        pars += "&code=" + code;

        var msg = new Soup.Message ("POST", "%s/oauth/token%s".printf (instance, pars));
        msg.finished.connect (() => {
            try{
                if (show_error (msg)) return;
                var root = network.parse (msg);
                token = root.get_string_member ("access_token");
                
                debug ("Got access token");
                get_username ();
            }
            catch (GLib.Error e) {
                warning ("Can't get access token");
                warning (e.message);
            }
        });
        network.queue_custom (msg);
    }
    
    private void get_username () {
        var msg = new Soup.Message("GET", "%s/api/v1/accounts/verify_credentials".printf (instance));
        msg.request_headers.append ("Authorization", "Bearer " + token);
        msg.finished.connect (() => {
            try{
                if (show_error (msg)) return;
                var root = network.parse (msg);
                username = root.get_string_member ("username");
                
                add_account ();
                window.show ();
                window.present ();
                destroy ();
            }
            catch (GLib.Error e) {
                warning ("Can't get username");
                warning (e.message);
            }
        });
        network.queue_custom (msg);
    }
    
    private void add_account () {
        var account = new InstanceAccount ();
        account.username = username;
        account.instance = instance;
        account.client_id = client_id;
        account.client_secret = client_secret;
        account.token = token;
        accounts.add (account);
        app.activate ();
    }

    public static void open () {
        if (dialog == null)
            dialog = new NewAccountDialog ();
    }

}
