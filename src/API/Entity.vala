public class Tootle.Entity : GLib.Object, Json.Serializable {

	public static Entity from_json (Type type, Json.Node? node) throws Oopsie {
        if (node == null)
            throw new Oopsie.PARSING (@"Received Json.Node for $(type.name ()) is null!");

        var obj = node.get_object ();
        if (obj == null)
            throw new Oopsie.PARSING (@"Received Json.Node for $(type.name ()) is not a Json.Object!");

        var kind = obj.get_member ("type");
        if (kind != null) {
        	obj.set_member ("kind", kind);
        	obj.remove_member ("type");
        }

        return Json.gobject_deserialize (type, node) as Entity;
	}

	public override bool deserialize_property (string prop, out Value val, ParamSpec spec, Json.Node node) {
		var success = default_deserialize_property (prop, out val, spec, node);

		var type = spec.value_type;
		if (val.type () == Type.INVALID) { // Fix for glib-json < 1.5.1
			val.init (type);
			spec.set_value_default (ref val);
			type = spec.value_type;
		}

		if (type.is_a (typeof (Gee.ArrayList))) {
			Type contains;
			switch (prop) {
				case "media-attachments":
					contains = typeof (API.Attachment);
					break;
				case "mentions":
					contains = typeof (API.Mention);
					break;
				default:
					contains = typeof (Entity);
					break;
			}
			return des_list (out val, node, contains);
		}
		else if (type.is_a (typeof (API.NotificationType)))
			return des_notification_type (out val, node);

		return success;
	}

	bool des_notification_type (out Value val, Json.Node node) {
		var str = node.get_string ();
		val = API.NotificationType.from_string (str);
		return true;
	}

	bool des_list (out Value val, Json.Node node, Type type) {
		if (!node.is_null ()) {
			var arr = new Gee.ArrayList<Entity> ();
			node.get_array ().foreach_element ((array, i, elem) => {
				var obj = Entity.from_json (type, elem);
				arr.add (obj);
			});
			val = arr;
		}
		return true;
	}

}
