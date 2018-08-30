public class Tootle.Status {

    public abstract signal void updated ();

    public Account account;
    public int64 id;
    public string uri;
    public string url;
    public string? spoiler_text;
    public string content;
    public int64 reblogs_count;
    public int64 favourites_count;
    public string created_at;    
    public bool reblogged = false;
    public bool favorited = false;
    public bool sensitive = false;
    public bool muted = false;
    public bool pinned = false;
    public StatusVisibility visibility;
    public Status? reblog;
    public Mention[]? mentions;
    public Attachment[]? attachments;

    public Status(int64 id) {
        this.id = id;
    }
    
    public Status get_formal (){
        return reblog != null ? reblog : this;
    }

    public static Status parse(Json.Object obj) {
        var id = int64.parse (obj.get_string_member ("id"));
        var status = new Status (id);
        
        status.account = Account.parse (obj.get_object_member ("account"));
        status.uri = obj.get_string_member ("uri");
        status.created_at = obj.get_string_member ("created_at");
        status.reblogs_count = obj.get_int_member ("reblogs_count");
        status.favourites_count = obj.get_int_member ("favourites_count");
        status.content = Html.simplify ( obj.get_string_member ("content"));
        status.sensitive = obj.get_boolean_member ("sensitive");
        status.visibility = StatusVisibility.from_string (obj.get_string_member ("visibility"));
        
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
        
        Mention[]? _mentions = {};
        obj.get_array_member ("mentions").foreach_element ((array, i, node) => {
            var object = node.get_object ();
            if (object != null)
                _mentions += Mention.parse (object);
        });
        if (_mentions.length > 0)
            status.mentions = _mentions;
        
        Attachment[]? _attachments = {};
        obj.get_array_member ("media_attachments").foreach_element ((array, i, node) => {
            var object = node.get_object ();
            if (object != null)
                _attachments += Attachment.parse (object);
        });
        if (_attachments.length > 0)
            status.attachments = _attachments;
        
        return status;
    }
    
    public bool is_owned (){
        return get_formal ().account.id == Tootle.accounts.current.id;
    }
    
    public string get_reply_mentions () {
        var result = "";
        if (account.acct != accounts.current.acct)
            result = "@%s ".printf (account.acct);
        
        if (mentions != null) {
            foreach (var mention in mentions) {
                var equals_current = mention.acct == accounts.current.acct;
                var already_mentioned = mention.acct in result;
                
                if (!equals_current && ! already_mentioned)
                    result += "@%s ".printf (mention.acct);
            }
        }
        
        return result;
    }
    
    public void set_reblogged (bool rebl = true){
        var action = rebl ? "reblog" : "unreblog";
        var msg = new Soup.Message("POST", "%s/api/v1/statuses/%lld/%s".printf (Tootle.accounts.formal.instance, id, action));
        msg.priority = Soup.MessagePriority.HIGH;
        msg.finished.connect (() => {
            reblogged = rebl;
            updated ();
            if(rebl)
                Tootle.app.toast (_("Boosted!"));
            else
                Tootle.app.toast (_("Removed boost"));
        });
        Tootle.network.queue (msg);
    }
    
    public void set_favorited (bool fav = true){
        var action = fav ? "favourite" : "unfavourite";
        var msg = new Soup.Message("POST", "%s/api/v1/statuses/%lld/%s".printf (Tootle.accounts.formal.instance, id, action));
        msg.priority = Soup.MessagePriority.HIGH;
        msg.finished.connect (() => {
            favorited = fav;
            updated ();
            if(fav)
                Tootle.app.toast (_("Favorited!"));
            else
                Tootle.app.toast (_("Removed from favorites"));
        });
        Tootle.network.queue (msg);
    }
    
    public void set_muted (bool mute = true){
        var action = mute ? "mute" : "unmute";
        var msg = new Soup.Message("POST", "%s/api/v1/statuses/%lld/%s".printf (Tootle.accounts.formal.instance, id, action));
        msg.priority = Soup.MessagePriority.HIGH;
        msg.finished.connect (() => {
            muted = mute;
            updated ();
            if (mute)
                Tootle.app.toast (_("Conversation muted"));
            else
                Tootle.app.toast (_("Conversation unmuted"));
        });
        Tootle.network.queue (msg);
    }
    
    public void set_pinned (bool pin = true){
        var action = pin ? "pin" : "unpin";
        var msg = new Soup.Message("POST", "%s/api/v1/statuses/%lld/%s".printf (Tootle.accounts.formal.instance, id, action));
        msg.priority = Soup.MessagePriority.HIGH;
        msg.finished.connect (() => {
            pinned = pin;
            updated ();
            if (pin)
                Tootle.app.toast (_("Pinned!"));
            else
                Tootle.app.toast (_("Unpinned"));
        });
        Tootle.network.queue (msg);
    }

    public void poof (){
        var msg = new Soup.Message("DELETE", "%s/api/v1/statuses/%lld".printf (Tootle.accounts.formal.instance, id));
        msg.priority = Soup.MessagePriority.HIGH;
        msg.finished.connect (() => {
            Tootle.app.toast (_("Poof!"));
            Tootle.network.status_removed (this.id);
        });
        Tootle.network.queue (msg);
    }

}
