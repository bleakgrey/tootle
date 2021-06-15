using Gtk;
using Gdk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/status.ui")]
public class Tootle.Widgets.Status : ListBoxRow {

	public API.Status? status { get; set; }
	public API.NotificationType? kind { get; set; }

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
	protected ToggleButton reblog_button;
	protected ToggleButton favorite_button;
	protected ToggleButton bookmark_button;

	construct {
		notify["kind"].connect (on_kind_changed);
		notify["status"].connect (on_rebind);
		open.connect (on_open);
		rebuild_actions ();
	}

	public Status (API.Status status, API.NotificationType? kind = null) {
		Object (
			status: status,
			kind: kind
		);
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

	protected virtual void on_rebind () {
		// Header
		if (kind == null) {
			if (status.reblog != null)
				kind = API.NotificationType.REBLOG_REMOTE_USER;
		}

		// Content
		bind_property ("spoiler-text", spoiler_label, "label", BindingFlags.SYNC_CREATE);
		status.formal.bind_property ("content", content, "content", BindingFlags.SYNC_CREATE);
		bind_property ("title_text", name_label, "label", BindingFlags.SYNC_CREATE);
		bind_property ("subtitle_text", handle_label, "label", BindingFlags.SYNC_CREATE);
		bind_property ("date", date_label, "label", BindingFlags.SYNC_CREATE);
		status.formal.bind_property ("pinned", pin_indicator, "visible", BindingFlags.SYNC_CREATE);
		status.formal.bind_property ("account", avatar, "account", BindingFlags.SYNC_CREATE);

		// Spoiler
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
		// bind_toggleable_prop (favorite_button, "favourited", "favourite", "unfavourite");
		// bind_toggleable_prop (reblog_button, "reblogged", "reblog", "unreblog");
		// bind_toggleable_prop (bookmark_button, "bookmarked", "bookmark", "unbookmark");

		if (status.formal.in_reply_to_id != null)
			reply_button.icon_name = "mail-reply-all-symbolic";
		else
			reply_button.icon_name = "mail-reply-sender-symbolic";

		if (status.formal.visibility == API.Visibility.DIRECT) {
			reblog_button.icon_name = status.formal.visibility.get_icon ();
			reblog_button.sensitive = false;
			reblog_button.tooltip_text = _("This post can't be boosted");
		}
		else {
			reblog_button.icon_name = "media-playlist-repeat-symbolic";
			reblog_button.sensitive = true;
			reblog_button.tooltip_text = null;
		}

		if (status.id == "") {
			actions.destroy ();
			date_label.destroy ();
		}

		// Attachments
		if (!attachments.populate (status.formal.media_attachments) || status.id == "") {
			attachments.destroy ();
		}
	}

	protected virtual void append_actions () {
		reply_button = new Button ();
		reply_button.clicked.connect (() => new Dialogs.Compose.reply (status));
		actions.append (reply_button);

		reblog_button = new ToggleButton ();
		actions.append (reblog_button);

		favorite_button = new ToggleButton ();
		favorite_button.icon_name = "non-starred-symbolic";
		actions.append (favorite_button);

		bookmark_button = new ToggleButton ();
		bookmark_button.icon_name = "user-bookmarks-symbolic";
		actions.append (bookmark_button);
	}

	void rebuild_actions () {
		for (var w = actions.get_first_child (); w != null; w = w.get_next_sibling ())
			actions.remove (w);

		append_actions ();

		var menu_button = new MenuButton ();
		menu_button.icon_name = "view-more-symbolic";
		actions.append (menu_button);

		menu_button.get_first_child ().add_css_class ("flat");
		for (var w = actions.get_first_child (); w != null; w = w.get_next_sibling ())
			w.add_css_class ("flat");
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
		// FIXME: Gtk.Menu is gone.
		// var menu = new Gtk.Menu ();

		// var item_open_link = new Gtk.MenuItem.with_label (_("Open in Browser"));
		// item_open_link.activate.connect (() => Desktop.open_uri (status.formal.url));
		// var item_copy_link = new Gtk.MenuItem.with_label (_("Copy Link"));
		// item_copy_link.activate.connect (() => Desktop.copy (status.formal.url));
		// var item_copy = new Gtk.MenuItem.with_label (_("Copy Text"));
		// item_copy.activate.connect (() => {
		// 	var sanitized = HtmlUtils.remove_tags (status.formal.content);
		// 	Desktop.copy (sanitized);
		// });

		// if (is_notification) {
		//	 var item_muting = new Gtk.MenuItem.with_label (status.muted ? _("Unmute Conversation") : _("Mute Conversation"));
		//	 item_muting.activate.connect (() => status.update_muted (!is_muted) );
		//	 menu.add (item_muting);
		// }

		// menu.add (item_open_link);
		// menu.add (new SeparatorMenuItem ());
		// menu.add (item_copy_link);
		// menu.add (item_copy);

		// if (status.is_owned ()) {
		// 	menu.add (new SeparatorMenuItem ());

		// 	var item_pin = new Gtk.MenuItem.with_label (status.pinned ? _("Unpin from Profile") : _("Pin on Profile"));
		// 	item_pin.activate.connect (() => {
		// 		status.action (status.formal.pinned ? "unpin" : "pin");
		// 	});
		// 	menu.add (item_pin);

		// 	var item_delete = new Gtk.MenuItem.with_label (_("Delete"));
		// 	item_delete.activate.connect (() => {
		// 		status.annihilate ()
		// 			.then ((sess, mess) => {
		// 				streams.force_delete (status.id);
		// 			})
		// 			.exec ();
		// 	});
		// 	menu.add (item_delete);

		// 	var item_redraft = new Gtk.MenuItem.with_label (_("Redraft"));
		// 	item_redraft.activate.connect (() => new Dialogs.Compose.redraft (status.formal));
		// 	menu.add (item_redraft);
		// }

		// menu.show_all ();
		// menu.popup_at_widget (menu_button, Gravity.SOUTH_EAST, Gravity.SOUTH_EAST);
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

	public void bind_toggleable_prop (ToggleButton button, string prop, string on, string off) {
		var init_val = Value (Type.BOOLEAN);
		((GLib.Object) status.formal).get_property (prop, ref init_val);
		button.active = init_val.get_boolean ();

		status.formal.bind_property (prop, button, "active", BindingFlags.DEFAULT);

		button.toggled.connect (() => {
			if (!(button.has_focus && button.sensitive))
				return;

			warning ("bruh");

			// button.sensitive = false;
			// var val = Value (Type.BOOLEAN);
			// ((GLib.Object) status.formal).get_property (prop, ref val);
			// var act = val.get_boolean () ? off : on;

			// var req = status.action (act);
			// req.await.begin ((obj, res) => {
			// 	try {
			// 		warning ("yeah");
			// 		var msg = req.await.end (res);
			// 		var node = network.parse_node (msg);
			// 		var entity = API.Status.from (node);

			// 		var new_val = Value (Type.BOOLEAN);
			// 		((GLib.Object) entity.formal).get_property (prop, ref new_val);
			// 		((GLib.Object) status.formal).set_property (prop, new_val.get_boolean ());
			// 	}
			// 	catch (Error e) {
			// 		warning (@"Couldn't perform action \"$act\" on a Status:");
			// 		warning (e.message);
			// 		app.inform (Gtk.MessageType.WARNING, _("Network Error"), e.message);
			// 	}
			// 	button.sensitive = true;
			// });
		});
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
