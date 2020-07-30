using Gtk;
using Gee;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/compose.ui")]
public class Tootle.Dialogs.Compose : Window {

	public API.Status? status { get; construct set; }
	public string style_class { get; construct set; }
	public string label { get; construct set; }
	public bool working { get; set; default = false; }
	public int char_limit {
		get {
			return 500;
		}
	}

	[GtkChild]
	Hdy.ViewSwitcherTitle mode_switcher;
	[GtkChild]
	Button commit;
	[GtkChild]
	Stack commit_stack;
	[GtkChild]
	Label commit_label;

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
	TextView content;

	[GtkChild]
	ListBox media_list;

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/compose_attachment.ui")]
	class MediaItem : Gtk.ListBoxRow {

		Compose dialog;
		public API.Attachment? entity { get; set; }
		public string? source { get; set; }

		[GtkChild]
		Label title_label;

		public MediaItem (Compose dialog, string? source, API.Attachment? entity) {
			this.dialog = dialog;
			this.source = source;
			this.entity = entity;

			if (source != null)
				message (@"Attached uri: $source");
			else
				message (@"Reattached $(entity.id)");

			if (!dialog.status.has_media ())
				dialog.status.media_attachments = new ArrayList<API.Attachment>();

			dialog.set_media_mode (true);

			title_label.label = GLib.Path.get_basename (source ?? entity.url).replace ("%20", " ");
		}

		[GtkCallback]
		void on_remove () {
			var remove = app.question (
				_(@"Delete \"%s\"?").printf (title_label.label),
				_("This action cannot be reverted."),
				this.dialog
			);
			if (remove)
				destroy ();
		}
	}

	construct {
		transient_for = window;

		notify["working"].connect (on_state_change);

		commit_label.label = label;
		commit.get_style_context ().add_class (style_class);

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
		set_media_mode (status.has_media ());
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

	void set_media_mode (bool has_media) {
		mode_switcher.sensitive = has_media;
		mode_switcher.opacity = has_media ? 1 : 0;
	}

	[GtkCallback]
	void validate () {
		var remain = char_limit - content.buffer.get_char_count ();
		if (cw_button.active)
			remain -= (int) cw.buffer.get_length ();

		counter.label = remain.to_string ();
		commit.sensitive = remain >= 0;
	}

	void on_error (int32 code, string reason) { //TODO: display errors
		warning (reason);
		working = false;
	}

	void on_state_change (ParamSpec? p) {
		commit.sensitive = !working;
		commit_stack.visible_child_name = working ? "working" : "ready";
		validate ();
	}

	[GtkCallback]
	void on_select_media () {
		var filter = new Gtk.FileFilter ();
		filter.add_mime_type ("image/jpeg");
		filter.add_mime_type ("image/png");
		filter.add_mime_type ("image/gif");
		filter.add_mime_type ("video/webm");
		filter.add_mime_type ("video/mp4");

		var chooser = new Gtk.FileChooserNative (
			 _("Select media"),
			 this,
			 Gtk.FileChooserAction.OPEN,
			 _("_Open"),
			 _("_Cancel")
		);
		chooser.select_multiple = true;
		chooser.set_filter (filter);

		if (chooser.run () == Gtk.ResponseType.ACCEPT) {
			foreach (unowned string uri in chooser.get_uris ())
				media_list.insert (new MediaItem (this, uri, null), 0);
		}
	}

	[GtkCallback]
	void on_media_list_row_activated (Widget w) {
		if (!(w is MediaItem))
			on_select_media ();
	}

	[GtkCallback]
	void on_post () {
		working = true;

		if (status.id != "") {
			message ("Removing old status...");
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
		message ("Publishing new status...");
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
			message (@"OK: Published status $(status.id)");
			on_close ();
		})
		.on_error (on_error)
		.exec ();
	}

}
