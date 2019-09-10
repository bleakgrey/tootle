using Gee;
using Gdk;

public class Tootle.Cache : GLib.Object {

    protected HashTable<string, Pixbuf> items { get; set; }
    protected HashTable<string, Soup.Message> items_in_progress { get; set; }
    protected uint size {
        get {
            return items.size ();
        }
    }

    construct {
        items = new HashTable<string, Pixbuf> (GLib.str_hash, GLib.str_equal);
        items_in_progress = new HashTable<string, Soup.Message> (GLib.str_hash, GLib.str_equal);
    }

    public delegate void CachedResultCallback (Reference? result);

    public struct Reference {
        public string key;
        public weak Pixbuf item;
    }

    public void unload (Reference? item) {
        // warning ("Unloading %s", item.key);
        // if (item != null) {
        //     info (@"X REMOVE $(item.key)");
        //     items.remove (item.key);
        // }
    }

    public void load (string? url, owned CachedResultCallback cb) {
        if (url == null)
            return;
        
        var key = url + "@-1";

        var item = items.@get (key);
        if (item != null) {
            //info (@"> LOAD $key");
            cb (Reference () {
                item = item,
                key = key
            });
            return;
        }

        var message = items_in_progress.@get (key);
        if (message == null) {
            message = new Soup.Message ("GET", url);
            ulong id = 0;
            id = message.finished.connect (() => {
                Pixbuf? pixbuf = null;

                var data = message.response_body.flatten ().data;
                var stream = new MemoryInputStream.from_data (data);
                pixbuf = new Pixbuf.from_stream (stream);
                stream.close ();

                store (key, pixbuf);
                cb (Reference () {
                    item = items[key],
                    key = key
                });

                message.disconnect (id);
            });
            
            network.queue (message, (sess, msg) => {
                // no one cares
            },
            (code, reason) => {
                cb (null);
            });

            items_in_progress.insert (key, message);
        }
        else {
            //debug ("| AWAIT: %s", key);
            ulong id = 0;
            id = message.finished.connect_after (() => {
                cb (Reference () {
                    item = items[key],
                    key = key
                });
                message.disconnect (id);
            });
        }
    }

    private void store (string key, Pixbuf pixbuf) {
        //info (@"< STORE $key");
        items[key] = pixbuf;
        items_in_progress.remove (key);
    }

    public void clear () {
        //info ("X BYE");
        items.remove_all ();
        items_in_progress.remove_all ();
    }
}
