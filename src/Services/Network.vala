using Soup;
using GLib;
using Gdk;
using Json;

public class Tootle.Network : GLib.Object {

    public signal void started ();
    public signal void finished ();
    public signal void notification (API.Notification notification);
    public signal void status_removed (int64 id);

	public delegate void ErrorCallback (int32 code, string reason);
	public delegate void SuccessCallback (Session session, Message msg) throws Error;
	public delegate void NodeCallback (Json.Node node, Message msg) throws Error;

    private int requests_processing = 0;
    public Soup.Session session;

    construct {
        session = new Soup.Session ();
        session.ssl_strict = true;
        session.ssl_use_system_ca_file = true;
        session.timeout = 15;
        session.max_conns = 20;
        session.request_unqueued.connect (msg => {
            requests_processing--;
            if (requests_processing <= 0)
                finished ();
        });

        // Soup.Logger logger = new Soup.Logger (Soup.LoggerLogLevel.BODY, -1);
        // session.add_feature (logger);
    }

    public async WebsocketConnection stream (Soup.Message msg) throws Error {
        return yield session.websocket_connect_async (msg, null, null, null);
    }

    public void cancel_request (Soup.Message? msg) {
        if (msg == null)
            return;

        switch (msg.status_code) {
            case Soup.Status.CANCELLED:
            case Soup.Status.OK:
                return;
        }
        session.cancel_message (msg, Soup.Status.CANCELLED);
    }

    public void queue (owned Soup.Message message, owned SuccessCallback? cb = null, owned ErrorCallback? errcb = null) {
        requests_processing++;
        started ();

        session.queue_message (message, (sess, msg) => {
        	var status = msg.status_code;
            if (status != Soup.Status.CANCELLED) {
            	if (status == Soup.Status.OK) {
            		try {
            		    cb (session, msg);
            		}
            		catch (Error e) {
            		    warning ("Caught exception on network request: %s", e.message);
                    	errcb (Soup.Status.NONE, e.message);
            		}
            	}
            	else {
            		errcb ((int32)status, get_error_reason ((int32)status));
            	}
            }
        });
    }

	public string get_error_reason (int32 status) {
		return "Error " + status.to_string () + ": " + Soup.Status.get_phrase (status);
	}

    public void on_error (int32 code, string message) {
        warning (message);
        app.toast (message);
    }

    public void on_show_error (int32 code, string message) {
    	warning (message);
    	app.error (_("Network Error"), message);
    }

    public Json.Object parse (Soup.Message msg) throws Error {
        // debug ("Status Code: %u", msg.status_code);
        // debug ("Message length: %lld", msg.response_body.length);
        // debug ("Object: %s", (string) msg.response_body.data);

        var parser = new Json.Parser ();
        parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
        return parser.get_root ().get_object ();
    }

    //TODO: Cache
    public delegate void PixbufCallback (Gdk.Pixbuf pixbuf);
    public Soup.Message load_pixbuf (string url, PixbufCallback cb) {
        var message = new Soup.Message("GET", url);
        network.queue (message, (sess, msg) => {
            Gdk.Pixbuf? pixbuf = null;
            try {
                var data = msg.response_body.flatten ().data;
                var stream = new MemoryInputStream.from_data (data);
                pixbuf = new Gdk.Pixbuf.from_stream (stream);
            }
            catch (Error e) {
                warning ("Can't get image: %s".printf (url));
                warning ("Reason: " + e.message);
            }
            finally {
                if (msg.status_code != Soup.Status.OK)
                    warning ("Invalid response code %s: %s", msg.status_code.to_string (), url);
            }
            cb (pixbuf);
        });
        return message;
    }

    //TODO: Cache
    public void load_image (string url, Gtk.Image image) {
        var message = new Soup.Message("GET", url);
        network.queue (message, (sess, msg) => {
            if (msg.status_code != Soup.Status.OK) {
                image.set_from_icon_name ("image-missing", Gtk.IconSize.LARGE_TOOLBAR);
                return;
            }

            var data = msg.response_body.data;
            var stream = new MemoryInputStream.from_data (data);
            var pixbuf = new Gdk.Pixbuf.from_stream (stream);
            image.set_from_pixbuf (pixbuf);
        });
    }

    //TODO: Cache
    public void load_scaled_image (string url, Gtk.Image image, int size) {
        var message = new Soup.Message("GET", url);
        network.queue (message, (sess, msg) => {
            if (msg.status_code != Soup.Status.OK) {
                image.set_from_icon_name ("image-missing", Gtk.IconSize.LARGE_TOOLBAR);
                return;
            }

            var data = msg.response_body.data;
            var stream = new MemoryInputStream.from_data (data);
            var pixbuf = new Gdk.Pixbuf.from_stream_at_scale (stream, size, size, true);
            image.set_from_pixbuf (pixbuf);
        });
    }

}
