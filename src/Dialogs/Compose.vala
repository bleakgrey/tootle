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
	protected class MediaItem : Gtk.ListBoxRow {

		Compose dialog;
		public API.Attachment? entity { get; set; }
		public string? source { get; set; }

		[GtkChild]
		public Label title_label;
		[GtkChild]
		public Entry description;

		public MediaItem (Compose dialog, string? source, API.Attachment? entity) {
			this.dialog = dialog;
			this.source = source;
			this.entity = entity;

			if (source != null)
				message (@"Attached uri: $source");
			else
				message (@"Reattached $(entity.id)");

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

	void on_state_change (ParamSpec? p) {
		commit_stack.visible_child_name = working ? "working" : "ready";
		commit.sensitive = !working;
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
	void on_close () {
		destroy ();
	}

	void on_error (int32 code, string reason) { //TODO: display errors
		warning (reason);
		working = false;
	}

	[GtkCallback]
	void on_commit () {
		working = true;
		transaction.begin ((obj, res) => {
			try {
				transaction.end (res);
				on_close ();
			}
			catch (Error e) {
				working = false;
				on_error (0, e.message);
			}
		});
	}

	async void transaction () throws Error {
		if (status.id != "") {
			message ("Removing old status...");
			yield status.annihilate ().await ();
		}

		Gee.ArrayList<MediaItem> pending_media = new Gee.ArrayList<MediaItem>();
		Gee.ArrayList<string> media_ids = new Gee.ArrayList<string>();
		media_list.@foreach (w => {
			var item = w as MediaItem;
			if (item != null)
				pending_media.add (item);
		});

		var media_param = "";
		if (!pending_media.is_empty) {
			message ("Processing attachments...");

			if (!status.has_media ())
				status.media_attachments = new ArrayList<API.Attachment>();

			foreach (MediaItem item in pending_media) {
				if (item.entity != null) {
					message (@"Adding existing media: $(item.entity.url)");
					media_ids.add (item.entity.id);
					return;
				}
				else {
					var entity = yield upload_media (
						item.source,
						item.title_label.label,
						item.description.text);

					media_ids.add (entity.id);
				}
			}

			media_param = Request.array2string (media_ids, "media_ids");
			media_param += "&";
		}

		message ("Publishing status...");
		status.content = content.buffer.text;
		status.spoiler_text = cw.text;

		var req = new Request.POST (@"/api/v1/statuses?$media_param")
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

		yield req.await ();

		var node = network.parse_node (req);
		var status = API.Status.from (node);
		message (@"OK: Published with ID $(status.id)");

		on_close ();
	}

	async API.Attachment upload_media (string uri, string title, string? descr) throws Error {
		message (@"Uploading new media: $(uri)...");

		uint8[] contents;
		string mime;
		GLib.FileInfo type;
		try {
			GLib.File file = File.new_for_uri (uri);
			file.load_contents (null, out contents, null);
			type = file.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE, 0);
			mime = type.get_content_type ();
		}
		catch (Error e) {
			throw new Oopsie.USER (_("Can't open file $file:\n$reason")
				.replace ("$file", title)
				.replace ("$reason", e.message)
			);
		}

		var descr_param = "";
		if (descr != null && descr.replace (" ", "") != "") {
			descr_param = "?description=" + Html.uri_encode (descr);
		}

		var buffer = new Soup.Buffer.take (contents);
		var multipart = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
		multipart.append_form_file ("file", mime.replace ("/", "."), mime, buffer);
		var url = @"$(accounts.active.instance)/api/v1/media$descr_param";
		var msg = Soup.Form.request_new_from_multipart (url, multipart);
		msg.request_headers.append ("Authorization", @"Bearer $(accounts.active.access_token)");

		string? error = null;
		network.queue (msg,
		(sess, mess) => {
			upload_media.callback ();
		},
		(code, reason) => {
			error = reason;
			upload_media.callback ();
		});

		yield;

		if (error != null)
			throw new Oopsie.INSTANCE (error);
		else {
			var node = network.parse_node (msg);
			var entity = API.Attachment.from (node);
			message (@"OK! ID $(entity.id)");
			return entity;
		}
	}

}
