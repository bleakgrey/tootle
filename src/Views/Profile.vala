using Gtk;

public class Tootle.Views.Profile : Views.Timeline {

	public API.Account profile { get; construct set; }
	public bool include_replies { get; set; default = false; }
	public bool only_media { get; set; default = false; }
	public string source { get; set; default = "statuses"; }

	SimpleActionGroup? actions;

	ListBox profile_list;
	Label relationship;
	Widgets.TimelineMenu menu_button;
	Button rs_button;
	Label rs_button_label;

	weak ListBoxRow note_row;

	construct {
		rebuild_actions ();

		profile.notify["rs"].connect (on_rs_updated);

		menu_button = new Widgets.TimelineMenu ("profile-menu");

		var builder = new Builder.from_resource (@"$(Build.RESOURCES)ui/views/profile_header.ui");
		profile_list = builder.get_object ("profile_list") as ListBox;

		var hdr = builder.get_object ("grid") as Grid;
		column_view.pack_start (hdr, false, false, 0);
		column_view.reorder_child (hdr, 0);

		var avatar = builder.get_object ("avatar") as Widgets.Avatar;
		avatar.url = profile.avatar;

		profile.bind_property ("display-name", menu_button.title, "label", BindingFlags.SYNC_CREATE);

		var handle = builder.get_object ("handle") as Widgets.RichLabel;
		profile.bind_property ("acct", handle, "text", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			var text = "@" + (string) src;
			target.set_string (@"<span size=\"x-large\" weight=\"bold\">$text</span>");
			return true;
		});

		note_row = builder.get_object ("note_row") as ListBoxRow;
		var note = builder.get_object ("note") as Widgets.RichLabel;
		profile.bind_property ("note", note, "text", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			var text = Html.simplify ((string) src);
			target.set_string (text);
			note_row.visible = text != "";
			return true;
		});

		relationship = builder.get_object ("relationship") as Label;

		// posts_label = builder.get_object ("posts_label") as Label;
		// profile.bind_property ("statuses_count", posts_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		//	 var val = (int64) src;
		// 	target.set_string (_("%s Posts").printf (@"<b>$val</b>"));
		// 	return true;
		// });
		// following_label = builder.get_object ("following_label") as Label;
		// profile.bind_property ("following_count", following_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		//	 var val = (int64) src;
		// 	target.set_string (_("%s Follows").printf (@"<b>$val</b>"));
		// 	return true;
		// });
		// followers_label = builder.get_object ("followers_label") as Label;
		// profile.bind_property ("followers_count", followers_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		//	 var val = (int64) src;
		// 	target.set_string (_("%s Followers").printf (@"<b>$val</b>"));
		// 	return true;
		// });

		rs_button = builder.get_object ("rs_button") as Button;
		rs_button.clicked.connect (on_rs_button_clicked);
		rs_button_label = builder.get_object ("rs_button_label") as Label;

		rebuild_fields ();
	}

	public Profile (API.Account acc) {
		Object (
			profile: acc,
			label: acc.acct,
			url: @"/api/v1/accounts/$(acc.id)/statuses"
		);
		profile.get_relationship ();
	}
	~Profile () {
		menu_button.destroy ();
	}

	void rebuild_actions () {
		actions = new SimpleActionGroup ();

		var media_action = new SimpleAction.stateful ("only-media", null, only_media);
		media_action.change_state.connect (v => {
			only_media = v.get_boolean ();
			media_action.set_state (only_media);

			on_refresh ();
		});
		actions.add_action (media_action);

		var replies_action = new SimpleAction.stateful ("include-replies", null, include_replies);
		replies_action.change_state.connect (v => {
			include_replies = v.get_boolean ();
			replies_action.set_state (include_replies);

			on_refresh ();
		});
		actions.add_action (replies_action);

		var source_action = new SimpleAction.stateful ("source", VariantType.STRING, source);
		source_action.change_state.connect (v => {
			source = v.get_string ();
			source_action.set_state (source);

			accepts = source == "statuses" ? typeof (API.Status) : typeof (API.Account);
			replies_action.set_enabled (source == "statuses");
			media_action.set_enabled (source == "statuses");

			url = @"/api/v1/accounts/$(profile.id)/$source";
			on_refresh ();
		});
		actions.add_action (source_action);
	}

	public override void on_shown () {
		window.header.custom_title = menu_button;
		menu_button.valign = Align.FILL;
		window.set_header_controls (rs_button);

		window.insert_action_group ("view", actions);
	}

	public override void on_hidden () {
		window.header.custom_title = null;
		window.reset_header_controls ();

		window.insert_action_group ("view", null);
	}

	void on_rs_button_clicked () {
		rs_button.sensitive = false;
		profile.set_following (!profile.rs.following);
	}

	 void on_rs_updated () {
		var rs = profile.rs;
		var label = "";
		if (rs_button.sensitive = rs != null) {
			if (rs.requested)
				label = _("Sent follow request");
			else if (rs.followed_by && rs.following)
				label = _("Mutually follows you");
			else if (rs.followed_by)
				label = _("Follows you");

			foreach (Widget w in new Widget[] { rs_button }) {
				var ctx = w.get_style_context ();
				ctx.remove_class (STYLE_CLASS_SUGGESTED_ACTION);
				ctx.remove_class (STYLE_CLASS_DESTRUCTIVE_ACTION);
				ctx.add_class (rs.following ? STYLE_CLASS_DESTRUCTIVE_ACTION : STYLE_CLASS_SUGGESTED_ACTION);
			}

			rs_button_label.label = rs.following ? _("Unfollow") : _("Follow");
		}

		relationship.label = label;
		relationship.visible = label != "";
	}

	public override Request append_params (Request req) {
		if (page_next == null && source == "statuses") {
			req.with_param ("exclude_replies", @"$(!include_replies)");
			req.with_param ("only_media", @"$(only_media)");
			return base.append_params (req);
		}
		else return req;
	}

	public static void open_from_id (string id) {
		var msg = new Soup.Message ("GET", @"$(accounts.active.instance)/api/v1/accounts/$id");
		network.queue (msg, (sess, mess) => {
			var node = network.parse_node (mess);
			var acc = API.Account.from (node);
			window.open_view (new Views.Profile (acc));
		}, (status, reason) => {
			network.on_error (status, reason);
		});
	}

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/profile_field_row.ui")]
	protected class Field : ListBoxRow {

		[GtkChild]
		Widgets.RichLabel name_label;
		[GtkChild]
		Widgets.RichLabel value_label;

		public Field (API.AccountField field) {
			name_label.text = field.name;
			value_label.text = field.val;
		}

	}

	void rebuild_fields () {
		if (profile.fields != null) {
			foreach (Entity e in profile.fields) {
				var w = new Field (e as API.AccountField);
				profile_list.insert (w, -1);
			}
		}
	}

}
