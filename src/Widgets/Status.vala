using Gtk;
using Gdk;
using Gee;
using GLib;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/status.ui")]
public class Tootle.Widgets.Status : ListBoxRow {

	public API.Status status { get; construct set; }
	public API.NotificationType? kind { get; construct set; }

	public enum ThreadRole {
		NONE,
		START,
		MIDDLE,
		END;

		public static void connect_posts (Widgets.Status? prev, Widgets.Status curr) {
			if (prev == null) {
				curr.thread_role = NONE;
				return;
			}

			switch (prev.thread_role) {
				case NONE:
					prev.thread_role = START;
					curr.thread_role = END;
					break;
				case END:
					prev.thread_role = MIDDLE;
					curr.thread_role = END;
					break;
			}
		}
	}

	public ThreadRole thread_role { get; set; default = ThreadRole.NONE; }

	[GtkChild] protected Grid grid;

	[GtkChild] protected Image header_icon;
	[GtkChild] protected Widgets.RichLabel header_label;
	[GtkChild] public Image thread_line;

	[GtkChild] public Widgets.Avatar avatar;
	[GtkChild] protected Widgets.RichLabel name_label;
	[GtkChild] protected Widgets.RichLabel handle_label;
	[GtkChild] protected Box indicators;
	[GtkChild] protected Widgets.RichLabel date_label;
	[GtkChild] protected Image pin_indicator;
	[GtkChild] protected Image indicator;
	[GtkChild] protected Box poll;

	[GtkChild] protected Box content_column;
	[GtkChild] protected Stack spoiler_stack;
	[GtkChild] protected Box content_box;
	[GtkChild] protected Widgets.RichLabel content;
	[GtkChild] protected Widgets.Attachment.Box attachments;
	[GtkChild] protected Button spoiler_button;
	[GtkChild] protected Widgets.RichLabel spoiler_label;

	[GtkChild] protected Box actions;
	[GtkChild] protected Button reply_button;
	[GtkChild] protected Image reply_button_icon;
	[GtkChild] protected ToggleButton reblog_button;
	[GtkChild] protected Image reblog_icon;
	[GtkChild] protected ToggleButton favorite_button;
	[GtkChild] protected ToggleButton bookmark_button;
	[GtkChild] protected Button menu_button;

	protected Button vote_button;

	protected string spoiler_text {
		owned get {
			var text = status.formal.spoiler_text;
			if (text == null || text == "")
				return _("Click to show sensitive content");
			else
				return text;
		}
	}
	public bool reveal_spoiler { get; set; default = false; }

	protected string date {
		owned get {
			return DateTime.humanize (status.formal.created_at);
		}
	}

	public string title_text {
		owned get {
			return Html.simplify (status.formal.account.display_name);
		}
	}

	public string subtitle_text {
		owned get {
			return status.formal.account.handle;
		}
	}

	public string? avatar_url {
		owned get {
			return status.formal.account.avatar;
		}
	}
	public void get_poll(){
        if (status.poll!=null){
            var row_number=0;
            Gtk.RadioButton[] radios={};
            Gtk.CheckButton[] checks={};
            ArrayList<string> selectedIndex=new ArrayList<string>();
            if (status.poll.own_votes.length==0 && !status.poll.multiple){
                selectedIndex.add(status.poll.options[0].title);
            }
            foreach (API.PollOption p in status.poll.options){
                //if it is own poll
                if(status.account.id==accounts.active.username){
                    // If multiple, Checkbox else radioButton
                    var option = new Widgets.RichLabel (p.title);
                    var counts = new Widgets.RichLabel ("Votes: "+p.votes_count.to_string()+" %");
                }
                else{
                     // If multiple, Checkbox else radioButton
                    if (status.poll.multiple){
                        var button_vote = new Gtk.CheckButton ();
                        button_vote.set_label(p.title);
                        button_vote.toggled.connect((radio)=>{
                            if (selectedIndex.contains(radio.get_label())){
                                selectedIndex.remove(radio.get_label());
                            }
                            else{
                                selectedIndex.add(radio.get_label());
                            }
                        });
                        foreach (int64 own_vote in status.poll.own_votes){
                            if (own_vote==row_number){
                                 button_vote.set_active(true);
                                 selectedIndex.add(p.title);
                            }
                        }
                        if(status.poll.expired || status.poll.voted){
                            button_vote.set_sensitive(false);
                        }
                        poll.add(button_vote);
                        checks+=button_vote;
                    }else{
                        Gtk.RadioButton button_vote = null;
                        if (radios.length==0){
                            button_vote=new Gtk.RadioButton (null);
                        }
                        else{
                            button_vote=new Gtk.RadioButton (radios[0].get_group());
                        }
                        button_vote.set_label(p.title);
                        button_vote.toggled.connect((radiobutton)=>{
                            if (selectedIndex.contains(radiobutton.get_label()))
                            {
                                selectedIndex.remove(radiobutton.get_label());
                            }
                            else{
                                selectedIndex.add(radiobutton.get_label());
                            }
                        });

                        foreach (int64 own_vote in status.poll.own_votes){
                            if (own_vote==row_number){
                                 button_vote.set_active(true);
                                 selectedIndex=new ArrayList<string>();
                                 selectedIndex.add(p.title);
                            }
                        }
                        if(status.poll.expired || status.poll.voted){
                            button_vote.set_sensitive(false);
                        }
                        poll.add(button_vote);
                        radios+=button_vote;
                    }
                }
                row_number++;
            }
            if(row_number>0 && !status.poll.expired && !status.poll.voted &&
                status.account.id!=accounts.active.id &&
                status.poll.own_votes.length==0){
                Gtk.Box buttonsPoll=new Box (Orientation.HORIZONTAL, 6);
                vote_button = new Gtk.Button();
                vote_button.set_label (_("Vote"));
	            vote_button.clicked.connect ((button) =>{
                    Request voting=API.Poll.vote(accounts.active,status.poll.options,selectedIndex,status.poll.id);
                    voting.then ((sess, mess) => {
				        var node = network.parse_node (mess);
                        status.poll=API.Poll.from_json(node);
				        message ("OK: Voting correctly");
				        GLib.List<weak Gtk.Widget> children=this.poll.get_children();
				        foreach (Widget child in children){
				            this.poll.remove(child);
				        }
				        get_poll();
			        })
			        .on_error ((code, reason) => {
				        warning ("Voting invalid!");
				        app.error (
					        _("Network Error"),
					        _("The instance has invalidated this session. Please sign in again.\n\n%s").printf (reason)
				        );
			        })
			        .exec ();

	            });
	            buttonsPoll.add(vote_button);
	            buttonsPoll.show_all();
                poll.add(buttonsPoll);
            }
        }
        poll.show_all();
	}

	public signal void open ();

	public virtual void on_open () {
		if (status.id == "")
			on_avatar_clicked ();
		else
			status.open ();
	}

	construct {
		notify["kind"].connect (on_kind_changed);
		open.connect (on_open);

		if (kind == null) {
			if (status.reblog != null)
				kind = API.NotificationType.REBLOG_REMOTE_USER;
		}

		status.formal.bind_property ("favourited", favorite_button, "active", BindingFlags.SYNC_CREATE);
		favorite_button.clicked.connect (() => {
			status.action (status.formal.favourited ? "unfavourite" : "favourite");
		});

		status.formal.bind_property ("reblogged", reblog_button, "active", BindingFlags.SYNC_CREATE);
		reblog_button.clicked.connect (() => {
			status.action (status.formal.reblogged ? "unreblog" : "reblog");
		});

		status.formal.bind_property ("bookmarked", bookmark_button, "active", BindingFlags.SYNC_CREATE);
		bookmark_button.clicked.connect (() => {
			status.action (status.formal.bookmarked ? "unbookmark" : "bookmark");
		});

		reply_button.clicked.connect (() => new Dialogs.Compose.reply (status));
		if (status.formal.in_reply_to_id != null)
			reply_button_icon.icon_name = "mail-reply-all-symbolic";
		else
			reply_button_icon.icon_name = "mail-reply-sender-symbolic";

		bind_property ("spoiler-text", spoiler_label, "text", BindingFlags.SYNC_CREATE);
		status.formal.bind_property ("content", content, "text", BindingFlags.SYNC_CREATE);
		bind_property ("title_text", name_label, "text", BindingFlags.SYNC_CREATE);
		bind_property ("subtitle_text", handle_label, "text", BindingFlags.SYNC_CREATE);
		bind_property ("date", date_label, "label", BindingFlags.SYNC_CREATE);
		status.formal.bind_property ("pinned", pin_indicator, "visible", BindingFlags.SYNC_CREATE);
		status.formal.bind_property ("account", avatar, "account", BindingFlags.SYNC_CREATE);

		// is it a poll?
		get_poll();


		status.formal.bind_property ("has-spoiler", this, "reveal-spoiler", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_boolean (!src.get_boolean ());
			return true;
		});
		bind_property ("reveal-spoiler", spoiler_stack, "visible-child-name", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			var name = reveal_spoiler ? "content" : "spoiler";
			target.set_string (name);
			return true;
		});

		if (status.formal.visibility == API.Visibility.DIRECT) {
			reblog_icon.icon_name = status.formal.visibility.get_icon ();
			reblog_button.sensitive = false;
			reblog_button.tooltip_text = _("This post can't be boosted");
		}

		if (status.id == "") {
			actions.destroy ();
			date_label.destroy ();
			content.single_line_mode = true;
			content.lines = 2;
			content.ellipsize = Pango.EllipsizeMode.END;
		}

		if (!attachments.populate (status.formal.media_attachments) || status.id == "") {
			attachments.destroy ();
		}

		menu_button.clicked.connect (open_menu);
	}

	public Status (API.Status status, API.NotificationType? kind = null) {
		Object (
			status: status,
			kind: kind
		);
	}
	~Status () {
		notify["kind"].disconnect (on_kind_changed);
	}

	[GtkCallback]
	public void toggle_spoiler () {
		reveal_spoiler = !reveal_spoiler;
	}

	protected virtual void on_kind_changed () {
		header_icon.visible = header_label.visible = (kind != null);
		if (kind == null)
			return;

		header_icon.icon_name = kind.get_icon ();
		header_label.label = kind.get_desc (status.account);
	}

	[GtkCallback]
	public void on_avatar_clicked () {
		status.formal.account.open ();
	}

	protected void open_menu () {
		var menu = new Gtk.Menu ();

		var item_open_link = new Gtk.MenuItem.with_label (_("Open in Browser"));
		item_open_link.activate.connect (() => Desktop.open_uri (status.formal.url));
		var item_copy_link = new Gtk.MenuItem.with_label (_("Copy Link"));
		item_copy_link.activate.connect (() => Desktop.copy (status.formal.url));
		var item_copy = new Gtk.MenuItem.with_label (_("Copy Text"));
		item_copy.activate.connect (() => {
			var sanitized = Html.remove_tags (status.formal.content);
			Desktop.copy (sanitized);
		});

		// if (is_notification) {
		//	 var item_muting = new Gtk.MenuItem.with_label (status.muted ? _("Unmute Conversation") : _("Mute Conversation"));
		//	 item_muting.activate.connect (() => status.update_muted (!is_muted) );
		//	 menu.add (item_muting);
		// }

		menu.add (item_open_link);
		menu.add (new SeparatorMenuItem ());
		menu.add (item_copy_link);
		menu.add (item_copy);

		if (status.is_owned ()) {
			menu.add (new SeparatorMenuItem ());

			var item_pin = new Gtk.MenuItem.with_label (status.pinned ? _("Unpin from Profile") : _("Pin on Profile"));
			item_pin.activate.connect (() => {
				status.action (status.formal.pinned ? "unpin" : "pin");
			});
			menu.add (item_pin);

			var item_delete = new Gtk.MenuItem.with_label (_("Delete"));
			item_delete.activate.connect (() => {
				status.annihilate ()
					.then ((sess, mess) => {
						streams.force_delete (status.id);
					})
					.exec ();
			});
			menu.add (item_delete);

			var item_redraft = new Gtk.MenuItem.with_label (_("Redraft"));
			item_redraft.activate.connect (() => new Dialogs.Compose.redraft (status.formal));
			menu.add (item_redraft);
		}

		menu.show_all ();
		menu.popup_at_widget (menu_button, Gravity.SOUTH_EAST, Gravity.SOUTH_EAST);
	}

	public void expand_root () {
		activatable = false;
        content.selectable = true;
        content.get_style_context ().add_class ("ttl-large-body");

        var parent = content_column.get_parent () as Container;
        var left_attach = parent.find_child_property ("left-attach");
        var width = parent.find_child_property ("width");
        parent.set_child_property (content_column, 1, 0, left_attach);
        parent.set_child_property (content_column, 3, 2, width);
	}

	public void install_thread_line () {
		var l = thread_line;
		switch (thread_role) {
			case NONE:
				l.visible = false;
				break;
			case START:
				l.valign = Align.FILL;
				l.margin_top = 24;
				l.visible = true;
				break;
			case MIDDLE:
				l.valign = Align.FILL;
				l.margin_top = 0;
				l.visible = true;
				break;
			case END:
				l.valign = Align.START;
				l.margin_top = 0;
				l.visible = true;
				break;
		}
	}

}
