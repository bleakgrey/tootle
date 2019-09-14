using Gtk;
using Granite;

public class Tootle.Views.Profile : Views.Timeline {

    public API.Account account { get; construct set; } 

    protected RadioButton filter_all;
    protected RadioButton filter_replies;
    protected RadioButton filter_media;
    
    protected Label posts_label;
    protected Label following_label;
    protected Label followers_label;
    protected RadioButton posts_tab;
    protected RadioButton following_tab;
    protected RadioButton followers_tab;

    construct {
        var builder = new Builder.from_resource (@"$(Build.RESOURCES)ui/views/profile_header.ui");
		view.pack_start (builder.get_object ("grid") as Grid, false, false, 0);
		
		var avatar = builder.get_object ("avatar") as Widgets.Avatar;
		avatar.url = account.avatar;
		
		var name = builder.get_object ("name") as Widgets.RichLabel;
		account.bind_property ("display-name", name, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			var label = (string) src;
			target.set_string (@"<span size='x-large' weight='bold'>$label</span>");
			return true;
		});
		
		var handle = builder.get_object ("handle") as Widgets.RichLabel;
		account.bind_property ("acct", handle, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string ("@" + (string) src);
			return true;
		});
		
		var note = builder.get_object ("note") as Widgets.RichLabel;
		account.bind_property ("note", note, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (Html.simplify ((string) src));
			return true;
		});
		
		posts_label = builder.get_object ("posts_label") as Label;
		account.bind_property ("posts_count", posts_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		    var val = (int64) src;
			target.set_string (_("%s Posts").printf (@"<b>$val</b>"));
			return true;
		});
		following_label = builder.get_object ("following_label") as Label;
		account.bind_property ("following_count", following_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		    var val = (int64) src;
			target.set_string (_("%s Follows").printf (@"<b>$val</b>"));
			return true;
		});
		followers_label = builder.get_object ("followers_label") as Label;
		account.bind_property ("followers_count", followers_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		    var val = (int64) src;
			target.set_string (_("%s Followers").printf (@"<b>$val</b>"));
			return true;
		});
		
		filter_all = builder.get_object ("filter_all") as RadioButton;
		filter_all.toggled.connect (on_filter_changed);
		filter_replies = builder.get_object ("filter_replies") as RadioButton;
		filter_replies.toggled.connect (on_filter_changed);
		filter_media = builder.get_object ("filter_media") as RadioButton;
		filter_media.toggled.connect (on_filter_changed);
		
		posts_tab = builder.get_object ("posts_tab") as RadioButton;
		posts_tab.toggled.connect (on_filter_changed);
		following_tab = builder.get_object ("following_tab") as RadioButton;
		following_tab.toggled.connect (on_filter_changed);
		followers_tab = builder.get_object ("followers_tab") as RadioButton;
		followers_tab.toggled.connect (on_filter_changed);
    }

    public Profile (API.Account acc) {
        Object (account: acc);
        //account.updated.connect (rebind);

        account.get_relationship ();
        request ();
    }

    public override bool is_status_owned (API.Status status) {
        return status.is_owned ();
    }

	protected void on_filter_changed () {
		clear ();
		request ();
	}

    public override string get_url () {
        if (page_next != null)
            return page_next;
    
    	if (following_tab.active)
    		return @"/api/v1/accounts/$(account.id)/following";
    	else if (followers_tab.active)
    		return @"/api/v1/accounts/$(account.id)/followers";
    	else
        	return @"/api/v1/accounts/$(account.id)/statuses";
    }

	public override Request append_params (Request req) {
		req.with_param ("exclude_replies", (!filter_replies.active).to_string ());
		req.with_param ("only_media", filter_media.active.to_string ());
		return base.append_params (req);
	}

    public override void request () {
        if (accounts.active == null) {
            empty_state ();
            return;
        }

		append_params (new Request.GET (get_url ()))
		.with_account ()
		.then_parse_array ((node, msg) => {
            var obj = node.get_object ();
            if (obj != null) {
            	API.Status status;
            	if (posts_tab.active)
                	status = API.Status.parse (obj);
                else {
                	var account = API.Account.parse (obj);
                	status = API.Status.from_account (account);
                }
                
                append (status);
            }
            get_pages (msg.response_headers.get_one ("Link"));
            empty_state ();
        })
		.on_error (network.on_error)
		.exec ();
    }

    public static void open_from_id (int64 id){
        var url = "%s/api/v1/accounts/%lld".printf (accounts.active.instance, id);
        var msg = new Soup.Message ("GET", url);
        msg.priority = Soup.MessagePriority.HIGH;
        network.queue (msg, (sess, mess) => {
            var root = network.parse (mess);
            var acc = API.Account.parse (root);
            window.open_view (new Views.Profile (acc));
        }, (status, reason) => {
            network.on_error (status, reason);
        });
    }

}
