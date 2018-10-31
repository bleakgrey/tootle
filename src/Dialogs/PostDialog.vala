using Gtk;
using Tootle;

public class Tootle.PostDialog : Gtk.Dialog {
    
    private static PostDialog dialog;
    
    protected TextView text;
    private ScrolledWindow scroll;
    private Label counter;
    private ImageToggleButton spoiler;
    private MenuButton visibility;
    private Button attach;
    private Button cancel;
    private Button publish;
    protected AttachmentBox attachments;
    private Revealer spoiler_revealer;
    private Entry spoiler_text;
    
    protected Status? replying_to;
    protected Status? redrafting;
    protected StatusVisibility visibility_opt = StatusVisibility.PUBLIC;
    protected int char_limit;

    public PostDialog (Status? _replying_to = null, Status? _redrafting = null) {
        border_width = 6;
        deletable = false;
        resizable = true;
        title = _("Toot");
        transient_for = window;
        char_limit = settings.char_limit;
        replying_to = _replying_to;
        redrafting = _redrafting;
        
        if (replying_to != null)
            visibility_opt = replying_to.visibility;
        if (redrafting != null)
            visibility_opt = redrafting.visibility;
        
        var actions = get_action_area ().get_parent () as Gtk.Box;
        var content = get_content_area ();
        get_action_area ().hexpand = false;
        
        visibility = get_visibility_btn ();
        visibility.tooltip_text = _("Post Visibility");
        visibility.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        visibility.get_style_context ().remove_class ("image-button");
        visibility.can_default = false;
        (visibility as Widget).set_focus_on_click (false);
        
        attach = new Button.from_icon_name ("mail-attachment-symbolic");
        attach.tooltip_text = _("Add Media");
        attach.valign = Gtk.Align.CENTER;
        attach.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        attach.get_style_context ().remove_class ("image-button");
        attach.can_default = false;
        (attach as Widget).set_focus_on_click (false);
        attach.clicked.connect (() => attachments.select ());
        
        spoiler = new ImageToggleButton ("image-red-eye-symbolic");
        spoiler.tooltip_text = _("Spoiler Warning");
        spoiler.set_action ();
        spoiler.toggled.connect (() => {
            spoiler_revealer.reveal_child = spoiler.active;
            validate ();
        });
        
        cancel = add_button (_("Cancel"), 5) as Button;
        cancel.clicked.connect(() => destroy ());
        
        if (redrafting != null) {
            publish = add_button (_("Redraft"), 5) as Button;
            publish.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            publish.clicked.connect (redraft_post);
        }
        else {
            publish = add_button (_("Toot!"), 5) as Button;
            publish.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            publish.clicked.connect (publish_post);
        }
        
        spoiler_text = new Gtk.Entry ();
        spoiler_text.margin_start = 6;
        spoiler_text.margin_end = 6;
        spoiler_text.placeholder_text = _("Write your warning here");
        spoiler_text.changed.connect (validate);
        
        spoiler_revealer = new Gtk.Revealer ();
        spoiler_revealer.add (spoiler_text);
        
        text = new TextView ();
        text.get_style_context ().add_class ("toot-text");
        text.wrap_mode = Gtk.WrapMode.WORD;
        text.accepts_tab = false;
        text.vexpand = true;
        text.buffer.changed.connect (validate);
        
        scroll = new ScrolledWindow (null, null);
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.min_content_height = 120;
        scroll.vexpand = true;
        scroll.propagate_natural_height = true;
        scroll.margin_start = 6;
        scroll.margin_end = 6;
        scroll.add (text);
        scroll.show_all ();
        
        attachments = new AttachmentBox (true);
        counter = new Label ("");
        
        actions.pack_start (counter, false, false, 6);
        actions.pack_end (spoiler, false, false, 6);
        actions.pack_end (visibility, false, false, 0);
        actions.pack_end (attach, false, false, 6);
        content.pack_start (spoiler_revealer, false, false, 6);
        content.pack_start (scroll, false, false, 6);
        content.pack_start (attachments, false, false, 6);
        content.set_size_request (350, 120);
        
        if (replying_to != null) {
            spoiler.active = replying_to.sensitive;
            var status_spoiler_text = replying_to.spoiler_text != null ? replying_to.spoiler_text : "";
            spoiler_text.set_text (status_spoiler_text);
        }
        if (redrafting != null) {
            spoiler.active = redrafting.sensitive;
            var status_spoiler_text = redrafting.spoiler_text != null ? redrafting.spoiler_text : "";
            spoiler_text.set_text (status_spoiler_text);
        }
        
        destroy.connect (() => dialog = null);
        
        show_all ();
        attachments.hide ();
        text.grab_focus ();
        validate ();
    }
    
    private Gtk.MenuButton get_visibility_btn () {
        var button = new Gtk.MenuButton ();
        var menu = new Gtk.Popover (null);
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        box.margin = 12;
        menu.add (box);
        button.direction = Gtk.ArrowType.DOWN;
        button.image = new Gtk.Image.from_icon_name (visibility_opt.get_icon (), Gtk.IconSize.BUTTON);
        
        Gtk.RadioButton? first = null;
        foreach (StatusVisibility opt in StatusVisibility.get_all ()){
            var item = new Gtk.RadioButton.with_label_from_widget (first, opt.get_desc ());
            if (first == null)
                first = item;
                
            item.toggled.connect (() => {
                visibility_opt = opt;
                (button.image as Gtk.Image).icon_name = visibility_opt.get_icon ();
            });
            item.active = visibility_opt == opt;
            box.pack_start (item, false, false, 0);
        }
        
        box.show_all ();
        button.use_popover = true;
        button.popover = menu;
        button.valign = Gtk.Align.CENTER;
        button.show ();
        return button;
    }
    
    private void validate () {
        var remain = char_limit - text.buffer.text.length;
        if (spoiler.active)
            remain -= spoiler_text.buffer.text.length;
        
        counter.label = remain.to_string ();
        publish.sensitive = remain >= 0; 
    }
    
    public static void open (string? text = null, Status? reply_to = null) {
        if (dialog == null){
            dialog = new PostDialog (reply_to);
            
		    if (text != null)
		        dialog.text.buffer.text = text;
		}
		else if (text != null)
		    dialog.text.buffer.text += text;
    }
    
    public static void reply (Status status) {
        if (dialog != null)
            return;
        
        open (null, status);
        dialog.text.buffer.text = status.get_reply_mentions ();
    }
    
    public static void redraft (Status status) {
        if (dialog != null)
            return;
        dialog = new PostDialog (null, status);
        
        if (status.attachments != null) {
            foreach (Attachment attachment in status.attachments)
                dialog.attachments.append (attachment);
        }
        
        var content = Html.simplify (status.content);
        content = Html.remove_tags (content);
        content = RichLabel.restore_entities (content);
        dialog.text.buffer.text = content;
    }
    
    private void publish_post () {
        var pars = "?status=%s&visibility=%s".printf (Html.uri_encode (text.buffer.text), visibility_opt.to_string ());
        pars += attachments.get_uri_array ();
        if (replying_to != null)
            pars += "&in_reply_to_id=%s".printf (replying_to.id.to_string ());
        
        if (spoiler.active) {
            pars += "&sensitive=true";
            pars += "&spoiler_text=" + Html.uri_encode (spoiler_text.buffer.text);
        }
        
        var url = "%s/api/v1/statuses%s".printf (accounts.formal.instance, pars);
        var msg = new Soup.Message ("POST", url);
        network.queue (msg, (sess, mess) => {
            try {
                var root = network.parse (mess);
                var status = Status.parse (root);
                debug ("Posted: %s", status.id.to_string ()); //TODO: Live updates
                destroy ();
            }
            catch (GLib.Error e) {
                warning ("Can't publish post.");
                warning (e.message);
            }
        });
    }
    
    private void redraft_post () {
        redrafting.poof (false).finished.connect (publish_post);
    }

}
