using Gtk;

public class Tootle.Views.Thread : Views.Base, IAccountListener {

	public API.Status root_status { get; construct set; }
	protected InstanceAccount? account = null;
	protected Widgets.Status root_widget;

	public Thread (API.Status status) {
		Object (
			root_status: status,
			status_message: STATUS_LOADING,
			label: _("Conversation")
		);
		account_listener_init ();
	}

	public override void on_account_changed (InstanceAccount? acc) {
		account = acc;
		request ();
	}

	Widgets.Status append (Entity entity){
		var w = entity.to_widget () as Widgets.Status;
		w.reveal_spoiler = true;
		content_list.insert (w, -1);
		return w;
	}

	void connect_threads () {
		Widgets.Status? last_w = null;
		string? last_id = null;

		content.get_children ().foreach (i => {
			var w = i as Widgets.Status;
			var id = w.status.formal.in_reply_to_id;

			if (id == last_id) {
				Widgets.Status.ThreadRole.connect_posts (last_w, w);
			}

			last_w = w;
			last_id = w.status.formal.id;
		});

		content.get_children ().foreach (i => {
			var w = i as Widgets.Status;
			w.install_thread_line ();
		});

		root_widget.thread_line.hide ();
	}

	public void request () {
		new Request.GET (@"/api/v1/statuses/$(root_status.id)/context")
			.with_account (account)
			.with_ctx (this)
			.then ((sess, msg) => {

				var root = network.parse (msg);

				var ancestors = root.get_array_member ("ancestors");
				ancestors.foreach_element ((array, i, node) => {
					var status = Entity.from_json (typeof (API.Status), node);
					append (status);
				});

				root_widget = append (root_status) as Widgets.Status;
				root_widget.expand_root ();

				var descendants = root.get_array_member ("descendants");
				descendants.foreach_element ((array, i, node) => {
					var status = Entity.from_json (typeof (API.Status), node);
					append (status);
				});

				connect_threads ();
				on_content_changed ();

				int x,y;
				translate_coordinates (root_widget, 0, header.get_allocated_height (), out x, out y);
				scrolled.vadjustment.value = (double)(y*-1);
			})
			.exec ();
	}

	public static void open_from_link (string q) {
		new Request.GET ("/api/v1/search")
			.with_account ()
			.with_param ("q", q)
			.with_param ("resolve", "true")
			.then ((sess, msg) => {
				var root = network.parse (msg);
				var statuses = root.get_array_member ("statuses");
				var node = statuses.get_element (0);
				if (node != null){
					var status = API.Status.from (node);
					window.open_view (new Views.Thread (status));
				}
				else
					Desktop.open_uri (q);
			})
			.exec ();
	}

}
