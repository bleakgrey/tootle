using Gtk;
using Granite;

public class Tootle.Views.Profile : Views.Timeline {

    const int AVATAR_SIZE = 128;
    protected API.Account account;

    protected Grid header_image;
    protected Box header_info;
    protected Granite.Widgets.Avatar avatar;
    protected Widgets.RichLabel display_name;
    protected Label username;
    protected Label relationship;
    protected Widgets.RichLabel note;
    protected Grid counters;
    protected Box actions;
    protected Button button_follow;

    protected Gtk.Menu menu;
    protected Gtk.MenuItem menu_edit;
    protected Gtk.MenuItem menu_mention;
    protected Gtk.MenuItem menu_mute;
    protected Gtk.MenuItem menu_block;
    protected Gtk.MenuItem menu_report;
    protected Gtk.MenuButton button_menu;


    construct {
        header = new Grid ();
        header_info = new Box (Orientation.VERTICAL, 0);
        header_info.margin = 12;
        actions = new Box (Orientation.HORIZONTAL, 0);
        actions.hexpand = false;
        actions.halign = Align.END;
        actions.vexpand = false;
        actions.valign = Align.START;
        actions.margin = 12;

        relationship = new Label ("");
        relationship.get_style_context ().add_class ("relationship");
        relationship.halign = Align.START;
        relationship.valign = Align.START;
        relationship.margin = 12;
        header.attach (relationship, 0, 0, 1, 1);

        avatar = new Granite.Widgets.Avatar.with_default_icon (AVATAR_SIZE);
        avatar.hexpand = true;
        avatar.margin_bottom = 6;
        header_info.pack_start (avatar, false, false, 0);

        display_name = new Widgets.RichLabel ("");
        display_name.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_info.pack_start (display_name, false, false, 0);

        username = new Label ("");
        header_info.pack_start (username, false, false, 0);

        note = new Widgets.RichLabel ("");
        note.set_line_wrap (true);
        note.selectable = true;
        note.margin_top = 12;
        note.can_focus = false;
        note.justify = Justification.CENTER;
        header_info.pack_start (note, false, false, 0);
        header_info.show_all ();
        header.attach (header_info, 0, 0, 1, 1);

        counters = new Grid ();
        counters.column_homogeneous = true;
        counters.get_style_context ().add_class ("header-counters");
        header.attach (counters, 0, 1, 1, 1);

        header_image = new Grid ();
        header_image.get_style_context ().add_class ("header");
        header.attach (header_image, 0, 0, 2, 2);

        menu = new Gtk.Menu ();
        menu_edit = new Gtk.MenuItem.with_label (_("Edit Profile"));
        menu_mention = new Gtk.MenuItem.with_label (_("Mention"));
        menu_report = new Gtk.MenuItem.with_label (_("Report"));
        menu_mute = new Gtk.MenuItem.with_label (_("Mute"));
        menu_block = new Gtk.MenuItem.with_label (_("Block"));
        menu.add (menu_mention);
        //menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (menu_mute);
        menu.add (menu_block);
        //menu.add (menu_report); //TODO: Report users
        //menu.add (menu_edit); //TODO: Edit profile
        menu.show_all ();

        button_follow = add_counter ("contact-new-symbolic");
        button_menu = new MenuButton ();
        button_menu.image = new Image.from_icon_name ("view-more-symbolic", IconSize.LARGE_TOOLBAR);
        button_menu.tooltip_text = _("More Actions");
        button_menu.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        (button_menu as Widget).set_focus_on_click (false);
        button_menu.can_default = false;
        button_menu.can_focus = false;
        button_menu.popup = menu;
        actions.pack_end(button_menu, false, false, 0);
        actions.pack_end(button_follow, false, false, 0);
        button_menu.hide ();
        button_follow.hide ();
        header.attach (actions, 0, 0, 2, 2);

        view.pack_start (header, false, false, 0);
    }

    public Profile (API.Account acc) {
        base ("");
        account = acc;
        account.updated.connect (rebind);

        add_counter (_("Toots"), 1, account.statuses_count);
        add_counter (_("Follows"), 2, account.following_count).clicked.connect (() => {
            var view = new Views.Following (account);
            window.open_view (view);
        });
        add_counter (_("Followers"), 3, account.followers_count).clicked.connect (() => {
            var view = new Views.Followers (account);
            window.open_view (view);
        });

        show_all ();

        //TODO: Has this thing always been synchronous???
        //var stylesheet = ".header{background-image: url(\"%s\")}".printf (account.header);
        //var css_provider = Granite.Widgets.Utils.get_css_provider (stylesheet);
        //header_image.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        menu_mention.activate.connect (() => Dialogs.Compose.open ("@%s ".printf (account.acct)));
        menu_mute.activate.connect (() => account.set_muted (!account.rs.muting));
        menu_block.activate.connect (() => account.set_blocked (!account.rs.blocking));
        button_follow.clicked.connect (() => account.set_following (!account.rs.following));

        rebind ();
        account.get_relationship ();
        request ();
    }



    public void rebind (){
        display_name.set_label ("<b>%s</b>".printf (account.display_name));
        username.label = "@" + account.acct;
        note.set_label (account.note);
        button_follow.visible = !account.is_self ();
        network.load_avatar (account.avatar, avatar, 128);

        menu_edit.visible = account.is_self ();

        if (account.rs != null && !account.is_self ()) {
            button_follow.show ();
            if (account.rs.following) {
                button_follow.tooltip_text = _("Unfollow");
                (button_follow.get_image () as Image).icon_name = "close-symbolic";
            }
            else{
                button_follow.tooltip_text = _("Follow");
                (button_follow.get_image () as Image).icon_name = "contact-new-symbolic";
            }
        }

        if (account.rs != null){
            button_menu.show ();
            menu_block.label = account.rs.blocking ? _("Unblock") : _("Block");
            menu_mute.label = account.rs.muting ? _("Unmute") : _("Mute");
            menu_report.visible = menu_mute.visible = menu_block.visible = !account.is_self ();

            var rs_label = get_relationship_label ();
            if (rs_label != null) {
                relationship.label = rs_label;
                relationship.show ();
            }
            else
                relationship.hide ();
        }
        else
            relationship.hide ();
    }

    public override bool is_status_owned (API.Status status) {
        return status.is_owned ();
    }

    private Button add_counter (string name, int? i = null, int64? val = null) {
        Button btn;
        if (val != null){
            btn = new Button ();
            var label = new Label ("<b>%s</b>\n%s".printf (name.up (), val.to_string ()));
            label.justify = Justification.CENTER;
            label.use_markup = true;
            label.margin = 8;
            btn.add (label);
        }
        else
            btn = new Button.from_icon_name (name, IconSize.LARGE_TOOLBAR);

        btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        (btn as Widget).set_focus_on_click (false);
        btn.can_default = false;
        btn.can_focus = false;

        if (i != null)
            counters.attach (btn, i, 1, 1, 1);
        return btn;
    }

    public override bool is_empty () {
        return view.get_children ().length () <= 2;
    }

    public override string get_url () {
        if (page_next != null)
            return page_next;

        var url = "%s/api/v1/accounts/%s/statuses?limit=%i".printf (accounts.formal.instance, account.id, this.limit);
        return url;
    }

    public override void request () {
        if (account != null)
            base.request ();
    }

    private string? get_relationship_label () {
        if (account.rs.requested)
            return _("Sent follow request");
        else if (account.rs.blocking)
            return _("Blocked");
        else if (account.rs.followed_by)
            return _("Follows you");
        else if (account.rs.domain_blocking)
            return _("Blocking this instance");
        else
            return null;
    }

    public static void open_from_id (string id){
        var url = "%s/api/v1/accounts/%s".printf (accounts.formal.instance, id);
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
