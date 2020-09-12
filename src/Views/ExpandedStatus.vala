using Gtk;

public class Tootle.Views.ExpandedStatus : Views.Base, IAccountListener {

    public API.Status root_status { get; construct set; }
    protected InstanceAccount? account = null;
    protected Widget root_widget;

    public ExpandedStatus (API.Status status) {
        Object (
            root_status: status,
            status_message: STATUS_LOADING
        );
        account_listener_init ();
    }

    public override void on_account_changed (InstanceAccount? acc) {
        account = acc;
        request ();
    }

    Widget prepend (Entity entity, bool to_end = false){
        var w = entity.to_widget () as Widgets.Status;
        w.reveal_spoiler = true;

		if (to_end)
			content_list.insert (w, -1);
		else
			content_list.prepend (w);

        check_resize ();
        return w;
    }
    Widget append (Entity entity) {
    	return prepend (entity, true);
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

                root_widget = append (root_status);

                var descendants = root.get_array_member ("descendants");
                descendants.foreach_element ((array, i, node) => {
                	var status = Entity.from_json (typeof (API.Status), node);
                    append (status);
                });

                on_content_changed ();

                int x,y;
                translate_coordinates (root_widget, 0, 0, out x, out y);
                scrolled.vadjustment.value = (double)(y*-1);
                //content_list.select_row (root_widget);
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
                    window.open_view (new Views.ExpandedStatus (status));
                }
                else
                    Desktop.open_uri (q);
            })
            .exec ();
    }

}
