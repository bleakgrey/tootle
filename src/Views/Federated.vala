public class Tootle.Views.Federated : Views.Timeline {

    public Federated () {
        base ("public");
    }
    
    public override string get_icon () {
        return "network-workgroup-symbolic";
    }
    
    public override string get_name () {
        return _("Federated Timeline");
    }
    
    protected override bool is_public () {
        return true;
    }
    
    public override Soup.Message? get_stream () {
        var url = "%s/api/v1/streaming/?stream=public&access_token=%s".printf (accounts.active.instance, accounts.active.token);
        return new Soup.Message("GET", url);
    }

}
