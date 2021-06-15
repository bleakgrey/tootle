public class Tootle.EntityCache : AbstractCache {

	public Entity lookup_or_insert (owned Json.Node node, owned Type type) {
		var obj = node.get_object ();
		var id = obj.get_member ("uri").get_string ();
		var key = get_key (id);

		Entity entity;
		if (contains (key)) {
			entity = lookup (key) as Entity;
			message ("serving cached: "+id);
		}
		else {
			entity = Entity.from_json (type, node);
			insert (id, entity);
		}

		if (entity == null)
			warning ("lookup_or_insert() returned null. This should not happen.");

		return entity;
	}

}
