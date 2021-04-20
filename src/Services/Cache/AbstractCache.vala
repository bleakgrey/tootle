using Gee;

public class Tootle.AbstractCache : Object {

	public const string DATA_MIN_REF_COUNT = "refs";

    protected Map<string, Object> items;
    protected Map<string, Soup.Message> items_in_progress;

    public int maintenance_secs { get; set; default = 10; }
    public uint size {
        get { return items.size; }
    }

    construct {
        items = new HashMap<string, Object> ();
        items_in_progress = new HashMap<string, Soup.Message> ();

        Timeout.add_seconds (maintenance_secs, maintenance_func, Priority.LOW);
    }

	bool maintenance_func () {
		// message ("maintenance start");
		if (size > 0) {
			uint cleared = 0;
			var iter = items.map_iterator ();

			while (iter.has_next ()) {
				iter.next ();
				var obj = iter.get_value ();
				var min_ref_count = obj.get_data<uint> (DATA_MIN_REF_COUNT);
				var remove = obj.ref_count <= min_ref_count;

				if (remove) {
					cleared++;
					Value url = Value (typeof (string));
					obj.get_property ("url", ref url);
					message (@"Freeing: $((string) url)");
					iter.unset ();
					obj.dispose ();
				}
			}

			if (cleared > 0)
				message (@"Freed $cleared items from cache. Size: $size");
		}

		// message ("maintenance end");
		return Source.CONTINUE;
	}

	public Object? lookup (string key) {
		return items.@get (key);
	}

	protected virtual string get_key (string id) {
		return id;
	}

	public bool contains (string id) {
		return items.has_key (get_key (id));
	}

	public void insert (string id, owned Object obj) {
		var key = get_key (id);
		message ("Inserting: "+key);
		items.@set (key, (owned) obj);

		var nobj = items.@get (key);
		nobj.set_data<uint> (DATA_MIN_REF_COUNT, nobj.ref_count);
	}

}
