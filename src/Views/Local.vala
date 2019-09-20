public class Tootle.Views.Local : Views.Federated {

    public override string get_icon () {
        return Desktop.fallback_icon ("system-users-symbolic", "document-open-recent-symbolic");
    }

    public override string get_name () {
        return _("Local Timeline");
    }

    public override Request append_params (Request req) {
        return req.with_param ("local", "true");
    }

    public override Soup.Message? get_stream () {
        var url = @"/api/v1/streaming/?stream=public:local&access_token=$(accounts.active.token)";
        return new Soup.Message ("GET", url);
    }

}
