using Gtk;

public class Tootle.Views.ExpandedStatus : Views.Base {

    public API.Status root_status { get; construct set; }
    private bool sensitive_visible = false;

    public ExpandedStatus (API.Status status) {
        Object (root_status: status, state: "content");
        request ();

        window.button_reveal.clicked.connect (on_reveal_toggle);
    }

    ~ExpandedStatus () {
        if (window != null) {
            window.button_reveal.clicked.disconnect (on_reveal_toggle);
            window.button_reveal.hide ();
        }
    }

    private void prepend (API.Status status, bool is_root = false){
        var widget = new Widgets.Status (status);
        widget.avatar.button_press_event.connect (widget.on_avatar_clicked);
        if (!is_root)
            widget.button_press_event.connect (widget.open);
        else
            widget.highlight ();

        content.pack_start (widget, false, false, 0);

        if (status.has_spoiler)
            window.button_reveal.show ();
        if (sensitive_visible)
            reveal_sensitive (widget);
    }

    public Soup.Message request () {
        var req = new Request.GET (@"/api/v1/statuses/$(root_status.id)/context")
            .with_account ()
            .then ((sess, msg) => {
                var root = network.parse (msg);
                var ancestors = root.get_array_member ("ancestors");
                ancestors.foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null) {
                        var status = API.Status.parse (object);
                        prepend (status);
                    }
                });
                
                prepend (root_status, true);
                
                var descendants = root.get_array_member ("descendants");
                descendants.foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null) {
                        var status = API.Status.parse (object);
                        prepend (status);
                    }
                });
            })
            .exec ();
        return req;
    }

    public static void open_from_link (string q) {
        new Request.GET ("/api/v1/search")
            .with_account ()
            .with_param ("q", q)
            .with_param ("resolve", "true")
            .then ((sess, msg) => {
                var root = network.parse (msg);
                var statuses = root.get_array_member ("statuses");
                var object = statuses.get_element (0).get_object ();
                if (object != null){
                    var status = API.Status.parse (object);
                    window.open_view (new Views.ExpandedStatus (status));
                }
                else
                    Desktop.open_uri (q);
            })
            .exec ();
    }

    private void on_reveal_toggle () {
        sensitive_visible = !sensitive_visible;
        content.forall (w => {
            if (!(w is Widgets.Status))
                return;

            var widget = w as Widgets.Status;
            reveal_sensitive (widget);
        });
    }

    private void reveal_sensitive (Widgets.Status widget) {
        // if (widget.status.has_spoiler)
        //     widget.revealer.reveal_child = sensitive_visible;
    }

}
