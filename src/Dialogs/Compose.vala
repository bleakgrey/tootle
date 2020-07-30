using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/compose.ui")]
public class Tootle.Dialogs.Compose : Window {

    public API.Status? status { get; construct set; }
    public string style_class { get; construct set; }
    public string label { get; construct set; }
    public int char_limit {
        get {
            return 500;
        }
    }

    [GtkChild]
    Box text;

    [GtkChild]
    ActionBar actions;
    [GtkChild]
    Revealer cw_revealer;
    [GtkChild]
    ToggleButton cw_button;
    [GtkChild]
    Entry cw;
    [GtkChild]
    Label counter;

    [GtkChild]
    MenuButton visibility_button;
    [GtkChild]
    Image visibility_icon;
    Widgets.VisibilityPopover visibility_popover;
    [GtkChild]
    Button post_button;
    [GtkChild]
    Label commit_label;

    [GtkChild]
    TextView content;

    construct {
        transient_for = window;

        commit_label.label = label;
		post_button.get_style_context ().add_class (style_class);

        actions.@foreach (w => {
            w.get_style_context ().remove_class ("flat");
        });

        visibility_popover = new Widgets.VisibilityPopover.with_button (visibility_button);
        visibility_popover.bind_property ("selected", visibility_icon, "icon-name", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (((API.Visibility)src).get_icon ());
			return true;
		});

        cw_button.bind_property ("active", cw_revealer, "reveal_child", BindingFlags.SYNC_CREATE);

        cw.buffer.deleted_text.connect (() => validate ());
        cw.buffer.inserted_text.connect (() => validate ());
        content.buffer.changed.connect (validate);

        if (status.spoiler_text != null) {
            cw.text = status.spoiler_text;
            cw_button.active = true;
        }
        content.buffer.text = Html.remove_tags (status.content);

		validate ();
        show ();
    }

    public Compose () {
        Object (
            status: new API.Status.empty (),
            style_class: STYLE_CLASS_SUGGESTED_ACTION,
            label: _("Publish")
        );
        set_visibility (status.visibility);
    }

    public Compose.redraft (API.Status status) {
        Object (
            status: status,
            style_class: STYLE_CLASS_DESTRUCTIVE_ACTION,
            label: _("Redraft")
        );
        set_visibility (status.visibility);
    }

	public Compose.reply (API.Status to) {
		var template = new API.Status.empty ();
		template.in_reply_to_id = to.id.to_string ();
		template.in_reply_to_account_id = to.account.id.to_string ();
		template.content = to.formal.get_reply_mentions ();
		Object (
		    status: template,
		    style_class: STYLE_CLASS_SUGGESTED_ACTION,
		    label: _("Reply")
		);
		set_visibility (to.visibility);
	}

    void set_visibility (API.Visibility v) {
        visibility_popover.selected = v;
        visibility_popover.invalidate ();
    }

    [GtkCallback]
    void validate () {
        var remain = char_limit - content.buffer.get_char_count ();
        if (cw_button.active)
            remain -= (int) cw.buffer.get_length ();

        counter.label = remain.to_string ();
        post_button.sensitive = remain >= 0;
        visibility_button.sensitive = true;
        text.sensitive = true;
    }

    void on_error (int32 code, string reason) { //TODO: display errors
        warning (reason);
        validate ();
    }

    [GtkCallback]
    void on_post () {
        post_button.sensitive = false;
        visibility_button.sensitive = false;
        text.sensitive = false;

        if (status.id != "") {
            info ("Removing old status...");
            status.poof (publish, on_error);
        }
        else {
            publish ();
        }
    }

    [GtkCallback]
    void on_close () {
        destroy ();
    }

    void publish () {
        info ("Publishing new status...");
        status.content = content.buffer.text;
        status.spoiler_text = cw.text;

        var req = new Request.POST ("/api/v1/statuses")
            .with_account (accounts.active)
            .with_param ("visibility", visibility_popover.selected.to_string ())
            .with_param ("status", Html.uri_encode (status.content));

        if (cw_button.active) {
            req.with_param ("sensitive", "true");
            req.with_param ("spoiler_text", Html.uri_encode (cw.text));
        }

        if (status.in_reply_to_id != null)
            req.with_param ("in_reply_to_id", status.in_reply_to_id);
        if (status.in_reply_to_account_id != null)
            req.with_param ("in_reply_to_account_id", status.in_reply_to_account_id);

        req.then ((sess, mess) => {
            var node = network.parse_node (mess);
            var status = API.Status.from (node);
            info ("OK: status id is %s", status.id.to_string ());
            destroy ();
        })
        .on_error (on_error)
        .exec ();
    }

}
