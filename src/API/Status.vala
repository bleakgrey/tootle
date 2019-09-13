using Gee;

public class Tootle.API.Status : GLib.Object {

    public signal void updated (); //TODO: get rid of this

    public API.Account account { get; set; }
    public int64 id { get; set; }
    public string uri { get; set; }
    public string? url { get; set; }
    public string? spoiler_text { get; set; }
    public string content { get; set; default = ""; }
    public int64 replies_count { get; set; default = 0; }
    public int64 reblogs_count { get; set; default = 0; }
    public int64 favourites_count { get; set; default = 0; }
    public string created_at { get; set; default = "0"; }
    public bool reblogged { get; set; default = false; }
    public bool favorited { get; set; default = false; }
    public bool sensitive { get; set; default = false; }
    public bool muted { get; set; default = false; }
    public bool pinned { get; set; default = false; }
    public API.Visibility visibility { get; set; default = API.Visibility.PUBLIC; }
    public API.Status? reblog { get; set; default = null; }
    public ArrayList<API.Mention>? mentions { get; set; default = null; }
    public ArrayList<API.Attachment>? attachments { get; set; default = null; }

    public Status formal {
        get { return reblog ?? this; }
    }

	public bool has_spoiler {
        get {
            return formal.spoiler_text != null || formal.sensitive;
        }
	}

    public Status (int64 id) {
        Object (id: id);
    }

	public static Status from_account (API.Account account) {
        var status = new API.Status (-10);
        status.account = account;
        status.created_at = account.created_at;

        if (account.note == "")
            status.content = "";
        else if ("\n" in account.note)
            status.content = Html.remove_tags (account.note.split ("\n")[0]);
        else
            status.content = Html.remove_tags (account.note);

        return status;
	}

    public static Status parse (Json.Object obj) {
        var id = int64.parse (obj.get_string_member ("id"));
        var status = new Status (id);

        status.account = Account.parse (obj.get_object_member ("account"));
        status.uri = obj.get_string_member ("uri");
        status.created_at = obj.get_string_member ("created_at");
        status.replies_count = obj.get_int_member ("replies_count");
        status.reblogs_count = obj.get_int_member ("reblogs_count");
        status.favourites_count = obj.get_int_member ("favourites_count");
        status.content = Html.simplify ( obj.get_string_member ("content"));
        status.sensitive = obj.get_boolean_member ("sensitive");
        status.visibility = Visibility.from_string (obj.get_string_member ("visibility"));

        if (obj.has_member ("url"))
            status.url = obj.get_string_member ("url");
        else
            status.url = obj.get_string_member ("uri").replace ("/activity", "");

        var spoiler = obj.get_string_member ("spoiler_text");
        if (spoiler != "")
            status.spoiler_text = Html.simplify (spoiler);

        if (obj.has_member ("reblogged"))
            status.reblogged = obj.get_boolean_member ("reblogged");
        if (obj.has_member ("favourited"))
            status.favorited = obj.get_boolean_member ("favourited");
        if (obj.has_member ("muted"))
            status.muted = obj.get_boolean_member ("muted");
        if (obj.has_member ("pinned"))
            status.pinned = obj.get_boolean_member ("pinned");

        if (obj.has_member ("reblog") && obj.get_null_member("reblog") != true)
            status.reblog = Status.parse (obj.get_object_member ("reblog"));

        obj.get_array_member ("mentions").foreach_element ((array, i, node) => {
            var entity = node.get_object ();
            if (entity != null) {
                if (status.mentions == null)
                    status.mentions = new ArrayList<API.Mention> ();
                status.mentions.add (API.Mention.parse (entity));
            }
        });

        obj.get_array_member ("media_attachments").foreach_element ((array, i, node) => {
            var entity = node.get_object ();
            if (entity != null) {
                if (status.attachments == null)
                    status.attachments = new ArrayList<API.Attachment> ();
                status.attachments.add (API.Attachment.parse (entity));
            }
        });

        return status;
    }

    public Json.Node? serialize () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("id");
        builder.add_string_value (id.to_string ());
        builder.set_member_name ("uri");
        builder.add_string_value (uri);
        builder.set_member_name ("url");
        builder.add_string_value (url);
        builder.set_member_name ("content");
        builder.add_string_value (content);
        builder.set_member_name ("created_at");
        builder.add_string_value (created_at);
        builder.set_member_name ("visibility");
        builder.add_string_value (visibility.to_string ());
        builder.set_member_name ("sensitive");
        builder.add_boolean_value (sensitive);
        builder.set_member_name ("sensitive");
        builder.add_boolean_value (sensitive);
        builder.set_member_name ("replies_count");
        builder.add_int_value (replies_count);
        builder.set_member_name ("favourites_count");
        builder.add_int_value (favourites_count);
        builder.set_member_name ("reblogs_count");
        builder.add_int_value (reblogs_count);
        builder.set_member_name ("account");
        builder.add_value (account.serialize ());

        if (spoiler_text != null) {
            builder.set_member_name ("spoiler_text");
            builder.add_string_value (spoiler_text);
        }
        if (reblog != null) {
            builder.set_member_name ("reblog");
            builder.add_value (reblog.serialize ());
        }
        if (attachments != null) {
            builder.set_member_name ("media_attachments");
            builder.begin_array ();
            foreach (API.Attachment attachment in attachments)
                builder.add_value (attachment.serialize ());
            builder.end_array ();
        }
        if (mentions != null) {
            builder.set_member_name ("mentions");
            builder.begin_array ();
            foreach (API.Mention mention in mentions)
                builder.add_value (mention.serialize ());
            builder.end_array ();
        }

        builder.end_object ();
        return builder.get_root ();
    }

    public bool is_owned (){
        return formal.account.id == accounts.active.id;
    }

    public string get_reply_mentions () {
        var result = "";
        if (account.acct != accounts.active.acct)
            result = "@%s ".printf (account.acct);

        if (mentions != null) {
            foreach (var mention in mentions) {
                var equals_current = mention.acct == accounts.active.acct;
                var already_mentioned = mention.acct in result;

                if (!equals_current && ! already_mentioned)
                    result += "@%s ".printf (mention.acct);
            }
        }

        return result;
    }

    public void update_reblogged (bool state, owned Network.ErrorCallback? err = network.on_error) {
        var action = state ? "reblog" : "unreblog";
        new Request.POST (@"/api/v1/statuses/$id/$action")
        	.with_account ()
        	.then ((sess, msg) => {
                reblogged = state;
                updated ();
            })
            .on_error ((status, reason) => err (status, reason))
        	.exec ();
    }

    public void update_favorited (bool state, owned Network.ErrorCallback? err = network.on_error) {
        var action = state ? "favourite" : "unfavourite";
        new Request.POST (@"/api/v1/statuses/$id/$action")
        	.with_account ()
        	.then ((sess, msg) => {
                favorited = state;
                updated ();
            })
            .on_error ((status, reason) => err (status, reason))
        	.exec ();
    }

    public void update_muted (bool state, owned Network.ErrorCallback? err = network.on_error) {
        var action = state ? "mute" : "unmute";
        new Request.POST (@"/api/v1/statuses/$id/$action")
        	.with_account ()
        	.then ((sess, msg) => {
                muted = state;
                updated ();
            })
            .on_error ((status, reason) => err (status, reason))
        	.exec ();
    }

    public void update_pinned (bool state, owned Network.ErrorCallback? err = network.on_error) {
        var action = state ? "pin" : "unpin";
        new Request.POST (@"/api/v1/statuses/$id/$action")
        	.with_account ()
        	.then ((sess, msg) => {
                pinned = state;
                updated ();
            })
            .on_error ((status, reason) => err (status, reason))
        	.exec ();
    }

    public void poof (owned Soup.SessionCallback? cb = null, owned Network.ErrorCallback? err = network.on_error) {
        new Request.DELETE (@"/api/v1/statuses/$id")
        	.with_account ()
        	.then ((sess, msg) => {
        	    network.status_removed (id);
        	    cb (sess, msg);
        	})
            .on_error ((status, reason) => err (status, reason))
        	.exec ();
    }

}
