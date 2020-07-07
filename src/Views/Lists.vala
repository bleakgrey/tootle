public class Tootle.Views.Lists : Views.Timeline {

    public Lists () {
        Object (
        	url: @"/api/v1/lists",
            name: _("Lists"),
            icon: "view-list-symbolic"
        );
        accepts = typeof (API.List);
    }

}
