public class Tootle.Views.Home : Views.Timeline {

    public Home () {
        Object (timeline: "home");
    }

    public override string get_icon () {
        return "user-home-symbolic";
    }

    public override string get_name () {
        return _("Home");
    }

    public override Soup.Message? get_stream () {
        return accounts.active.get_stream ();
    }

}
