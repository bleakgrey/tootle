using Gtk;

public class Tootle.Views.Lists : Views.Timeline {

    public Lists () {
        Object (
        	url: @"/api/v1/lists",
            label: _("Lists"),
            icon: "view-list-symbolic"
        );
        accepts = typeof (API.List);
    }

    public override void on_request_finish () {
        var add_row = new API.List.ListItemRow (null);
        append (add_row);
    }

}
