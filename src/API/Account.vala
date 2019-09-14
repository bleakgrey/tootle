public class Tootle.API.Account : GLib.Object {

    public int64 id { get; set; }
    public string username { get; set; }
    public string acct { get; set; }
    public string? _display_name = null;
    public string display_name {
        set {
            this._display_name = value;
        }
    	get {
    		return (_display_name == null || _display_name == "") ? username : _display_name;
    	}
    }
    public string note { get; set; }
    public string header { get; set; }
    public string avatar { get; set; }
    public string url { get; set; }
    public string created_at { get; set; }
    public int64 followers_count { get; set; }
    public int64 following_count { get; set; }
    public int64 posts_count { get; set; }
    public Relationship? rs { get; set; default = null; }

    public Account (int64 _id){
        Object (id: _id);
    }

    public static Account parse (Json.Object obj) {
        var id = int64.parse (obj.get_string_member ("id"));
        var account = new Account (id);

        account.username = obj.get_string_member ("username");
        account.acct = obj.get_string_member ("acct");
        account.display_name = obj.get_string_member ("display_name");
        account.note = obj.get_string_member ("note");
        account.avatar = obj.get_string_member ("avatar");
        account.header = obj.get_string_member ("header");
        account.url = obj.get_string_member ("url");
        account.created_at = obj.get_string_member ("created_at");

        account.followers_count = obj.get_int_member ("followers_count");
        account.following_count = obj.get_int_member ("following_count");
        account.posts_count = obj.get_int_member ("statuses_count");

        if (obj.has_member ("fields")) {
            obj.get_array_member ("fields").foreach_element ((array, i, node) => {
                var field_obj = node.get_object ();
                var field_name = field_obj.get_string_member ("name");
                var field_val = field_obj.get_string_member ("value");
                account.note += "\n";
                account.note += field_name + ": ";
                account.note += field_val;
            });
        }

        return account;
    }

    public virtual Json.Node? serialize () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("id");
        builder.add_string_value (id.to_string ());
        builder.set_member_name ("created_at");
        builder.add_string_value (created_at);
        builder.set_member_name ("following_count");
        builder.add_int_value (following_count);
        builder.set_member_name ("followers_count");
        builder.add_int_value (followers_count);
        builder.set_member_name ("statuses_count");
        builder.add_int_value (posts_count);
        builder.set_member_name ("display_name");
        builder.add_string_value (display_name);
        builder.set_member_name ("username");
        builder.add_string_value (username);
        builder.set_member_name ("acct");
        builder.add_string_value (acct);
        builder.set_member_name ("note");
        builder.add_string_value (note);
        builder.set_member_name ("header");
        builder.add_string_value (header);
        builder.set_member_name ("avatar");
        builder.add_string_value (avatar);
        builder.set_member_name ("url");
        builder.add_string_value (url);

        builder.end_object ();
        return builder.get_root ();
    }

    public bool is_self () {
        return id == accounts.active.id;
    }

    public Request get_relationship () {
    	return new Request.GET ("/api/v1/accounts/relationships")
    		.with_account ()
    		.with_param ("id", id.to_string ())
    		.then_parse_array (node => {
                rs = Relationship.parse (node.get_object ());
    		})
    		.on_error (network.on_error)
    		.exec ();
    }

    public Request set_following (bool state = true) {
        var action = state ? "follow" : "unfollow";
        return new Request.POST (@"/api/v1/accounts/$id/$action")
            .with_account ()
            .then ((sess, msg) => {
                var root = network.parse (msg);
                rs = Relationship.parse (root);
            })
    		.on_error (network.on_error)
    		.exec ();
    }

    public Request set_muted (bool state = true) {
        var action = state ? "mute" : "unmute";
        return new Request.POST (@"/api/v1/accounts/$id/$action")
            .with_account ()
            .then ((sess, msg) => {
                var root = network.parse (msg);
                rs = Relationship.parse (root);
            })
    		.on_error (network.on_error)
    		.exec ();
    }

    public Request set_blocked (bool state = true) {
        var action = state ? "block" : "unblock";
        return new Request.POST (@"/api/v1/accounts/$id/$action")
            .with_account ()
            .then ((sess, msg) => {
                var root = network.parse (msg);
                rs = Relationship.parse (root);
            })
    		.on_error (network.on_error)
    		.exec ();
    }

}
