using Gtk;
using Gdk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/status.ui")]
public class Tootle.Widgets.Status : ListBoxRow {

    API.Status? _bound_status = null;
	public API.Status? status {
	    get { return _bound_status; }
	    set {
	        if (_bound_status != null)
	            warning ("Trying to rebind a Status widget! This is not supposed to happen!");

            _bound_status = value;
	        if (_bound_status != null)
	            bind ();
	    }
	}

    public API.Account? kind_instigator { get; set; default = null; }

    string? _kind = null;
	public string? kind {
	    get { return _kind; }
	    set {
	        _kind = value;
	        change_kind ();
	    }
	}

	[GtkChild] protected unowned Grid grid;

	[GtkChild] protected unowned Image header_icon;
	[GtkChild] protected unowned Widgets.RichLabel header_label;
	[GtkChild] public unowned Image thread_line;

	[GtkChild] public unowned Widgets.Avatar avatar;
	[GtkChild] protected unowned Widgets.RichLabel name_label;
	[GtkChild] protected unowned Label handle_label;
	[GtkChild] protected unowned Box indicators;
	[GtkChild] protected unowned Label date_label;
	[GtkChild] protected unowned Image pin_indicator;
	[GtkChild] protected unowned Image indicator;

	[GtkChild] protected unowned Box content_column;
	[GtkChild] protected unowned Stack spoiler_stack;
	[GtkChild] protected unowned Box content_box;
	[GtkChild] protected unowned Widgets.MarkupView content;
	[GtkChild] protected unowned Widgets.Attachment.Box attachments;
	[GtkChild] protected unowned Button spoiler_button;
	[GtkChild] protected unowned Widgets.RichLabel spoiler_label;

	[GtkChild] protected unowned Box actions;

	protected Button reply_button;
	protected StatusActionButton reblog_button;
	protected StatusActionButton favorite_button;
	protected StatusActionButton bookmark_button;

	construct {
	    open.connect (on_open);
		rebuild_actions ();
	}

	public Status (API.Status status) {
		Object (
		    kind_instigator: status.account,
			status: status
		);

		if (kind == null && status.reblog != null) {
			kind = Mastodon.Account.KIND_REMOTE_REBLOG;
		}
	}
	~Status () {
		message ("Destroying Status widget");
	}

	protected string spoiler_text {
		owned get {
			var text = status.formal.spoiler_text;
			if (text == null || text == "")
				return _("Click to show sensitive content");
			else
				return text;
		}
	}
	public bool reveal_spoiler { get; set; default = true; }

	protected string date {
		owned get {
			return DateTime.humanize (status.formal.created_at);
		}
	}

	public string title_text {
		owned get {
			return status.formal.account.display_name;
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

	public signal void open ();
	public virtual void on_open () {
		if (status.id == "")
			on_avatar_clicked ();
		else
			status.open ();
	}

	protected virtual void change_kind () {
	    string icon = null;
	    string descr = null;
	    accounts.active.describe_kind (this.kind, out icon, out descr, this.kind_instigator);

	    header_icon.visible = header_label.visible = (icon != null);
	    if (icon == null) return;

	    header_icon.icon_name = icon;
		header_label.label = descr;
	}

	protected virtual void bind () {
		// Content
		bind_property ("spoiler-text", spoiler_label, "label", BindingFlags.SYNC_CREATE);
		status.formal.bind_property ("content", content, "content", BindingFlags.SYNC_CREATE);
		bind_property ("title_text", name_label, "label", BindingFlags.SYNC_CREATE);
		bind_property ("subtitle_text", handle_label, "label", BindingFlags.SYNC_CREATE);
		bind_property ("date", date_label, "label", BindingFlags.SYNC_CREATE);
		status.formal.bind_property ("pinned", pin_indicator, "visible", BindingFlags.SYNC_CREATE);
		status.formal.bind_property ("account", avatar, "account", BindingFlags.SYNC_CREATE);

		// Spoiler //TODO: Spoilers
		reveal_spoiler = true;
		spoiler_stack.visible_child_name = "content";

		// status.formal.bind_property ("has-spoiler", this, "reveal-spoiler", BindingFlags.INVERT_BOOLEAN);

		// status.formal.bind_property ("has-spoiler", this, "reveal-spoiler", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		// 	target.set_boolean (!src.get_boolean ());
		// 	return true;
		// }); !!!
		// bind_property ("reveal-spoiler", spoiler_stack, "visible-child-name", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		// 	var name = reveal_spoiler ? "content" : "spoiler";
		// 	target.set_string (name);
		// 	return true;
		// });

		// Actions
		reblog_button.bind (status.formal);
		favorite_button.bind (status.formal);
		bookmark_button.bind (status.formal);

		if (status.formal.in_reply_to_id != null)
			reply_button.icon_name = "mail-reply-all-symbolic";
		else
			reply_button.icon_name = "mail-reply-sender-symbolic";

		if (!status.can_be_boosted) {
			reblog_button.sensitive = false;
			reblog_button.tooltip_text = _("This post can't be boosted");
			reblog_button.icon_name = accounts.active.visibility[status.visibility].icon_name;
		}
		else {
			reblog_button.sensitive = true;
			reblog_button.tooltip_text = null;
			reblog_button.icon_name = "media-playlist-repeat-symbolic";
		}

		if (status.id == "") {
			actions.destroy ();
			date_label.destroy ();
		}

		// Attachments
		attachments.list = status.formal.media_attachments;
	}

	protected virtual void append_actions () {
		reply_button = new Button ();
		reply_button.clicked.connect (() => new Dialogs.Compose.reply (status));
		actions.append (reply_button);

		reblog_button = new StatusActionButton () {
		    prop_name = "reblogged",
		    action_on = "reblog",
		    action_off = "unreblog"
		};
		actions.append (reblog_button);

		favorite_button = new StatusActionButton () {
		    prop_name = "favourited",
		    action_on = "favourite",
		    action_off = "unfavourite",
		    icon_name = "non-starred-symbolic"
		};
		actions.append (favorite_button);

		bookmark_button = new StatusActionButton () {
		    prop_name = "bookmarked",
		    action_on = "bookmark",
		    action_off = "unbookmark",
		    icon_name = "user-bookmarks-symbolic"
		};
		actions.append (bookmark_button);
	}

	void rebuild_actions () {
		for (var w = actions.get_first_child (); w != null; w = w.get_next_sibling ())
			actions.remove (w);

		append_actions ();

		// var menu_button = new MenuButton (); //TODO: Status menu
		// menu_button.icon_name = "view-more-symbolic";
		// menu_button.get_first_child ().add_css_class ("flat");
		// actions.append (menu_button);

		for (var w = actions.get_first_child (); w != null; w = w.get_next_sibling ())
			w.add_css_class ("flat");
	}

	[GtkCallback] public void toggle_spoiler () {
		reveal_spoiler = !reveal_spoiler;
	}

	[GtkCallback] public void on_avatar_clicked () {
		status.formal.account.open ();
	}

	public void expand_root () {
		activatable = false;
		content.selectable = true;
		content.get_style_context ().add_class ("ttl-large-body");

		var mgr = (content_column.get_parent () as Grid).get_layout_manager ();
		var child = mgr.get_layout_child (content_column);
		child.set_property ("column", 0);
		child.set_property ("column_span", 2);
	}



	// Threads

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
