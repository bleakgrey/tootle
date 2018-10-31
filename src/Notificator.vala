using GLib;
using Soup;

public class Tootle.Notificator : GLib.Object {
    
    private WebsocketConnection? connection;
    private Soup.Message msg;
    private bool closing = false;
    private int timeout = 2;
    
    public signal void notification (Notification notification);
    public signal void status_added (Status status);
    public signal void status_removed (int64 id);
    
    public Notificator (Soup.Message _msg){
        msg = _msg;
        msg.priority = Soup.MessagePriority.VERY_HIGH;
        msg.set_flags (Soup.MessageFlags.IGNORE_CONNECTION_LIMITS);
    }
    
    public string get_url () {
        return msg.get_uri ().to_string (false);
    }
    
    public string get_name () {
        var name = msg.get_uri ().to_string (true);
        if ("&access_token" in name) {
            var pos = name.last_index_of ("&access_token");
            name = name.slice (0, pos);
        }
            
        return name;
    }
    
    public async void start () {
        if (connection != null)
            return;
    
        try {
            info ("Starting: %s", get_name ());
            connection = yield network.stream (msg);
            connection.error.connect (on_error);
            connection.message.connect (on_message);
            connection.closed.connect (on_closed);
            timeout = 2;
        }
        catch (GLib.Error e) {
            warning (e.message);
            on_closed ();
        }
    }
    
    public void close () {
        if (connection == null)
            return;
        
        info ("Closing: %s", get_name ());
        closing = true;
        connection.close (0, null);
    }
    
    private bool reconnect () {
        start ();
        return false;
    }
    
    private void on_closed () {
        if (closing)
            return;
        
        warning ("Aborted: %s. Reconnecting in %i seconds.", get_name (), timeout);
        GLib.Timeout.add_seconds (timeout, reconnect);
        timeout = int.min (timeout*2, 60);
    }
    
    private void on_error (Error e) {
    	if (!closing)
        	warning ("Error in %s: %s", get_name (), e.message);
    }
    
    private void on_message (int i, Bytes bytes) {
        var msg = (string) bytes.get_data ();
        
        var parser = new Json.Parser ();
        parser.load_from_data (msg, -1);
        var root = parser.get_root ().get_object ();
        
        var type = root.get_string_member ("event");
        switch (type) {
            case "update":
                if (!settings.live_updates)
                    return;
                
                var status = Status.parse (sanitize (root));
                status_added (status);
                break;
            case "delete":
                if (!settings.live_updates)
                    return;
                
                var id = int64.parse (root.get_string_member("payload"));
                status_removed (id);
                break;
            case "notification":
                var notif = Notification.parse (sanitize (root));
                notification (notif);
                break;
            default:
                warning ("Unknown push event: %s", type);
                break;
        }
    }
    
    private Json.Object sanitize (Json.Object root) {
        var payload = root.get_string_member ("payload");
        var sanitized = Soup.URI.decode (payload);
        var parser = new Json.Parser ();
        parser.load_from_data (sanitized, -1);
        return parser.get_root ().get_object ();
    }
    
}
