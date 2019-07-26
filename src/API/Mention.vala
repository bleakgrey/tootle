public class Tootle.API.Mention : GLib.Object {

    public string id;
    public string username;
    public string acct;
    public string url;

    public Mention (string _id){
        id = _id;
    }

    public Mention.from_account (Account account){
        id = account.id;
        username = account.username;
        acct = account.acct;
        url = account.url;
    }

    public static Mention parse (Json.Object obj){
        var id = obj.get_string_member ("id");
        var mention = new Mention (id);

        mention.username = obj.get_string_member ("username");
        mention.acct = obj.get_string_member ("acct");
        mention.url = obj.get_string_member ("url");

        return mention;
    }

    public Json.Node? serialize () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("id");
        builder.add_string_value (id.to_string ());
        builder.set_member_name ("username");
        builder.add_string_value (username);
        builder.set_member_name ("acct");
        builder.add_string_value (acct);
        builder.set_member_name ("url");
        builder.add_string_value (url);
        builder.end_object ();
        return builder.get_root ();
    }

}
