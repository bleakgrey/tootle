public class Tootle.API.Relationship : GLib.Object {

    public int64 id { get; set; }
    public bool following { get; set; default = false; }
    public bool followed_by { get; set; default = false; }
    public bool muting { get; set; default = false; }
    public bool muting_notifications { get; set; default = false; }
    public bool requested { get; set; default = false; }
    public bool blocking { get; set; default = false; }
    public bool domain_blocking { get; set; default = false; }

    public Relationship (int64 id) {
        Object (id: id);
    }

    public static Relationship parse (Json.Object obj) {
        var id = int64.parse (obj.get_string_member ("id"));
        var rs = new Relationship (id);
        rs.following = obj.get_boolean_member ("following");
        rs.followed_by = obj.get_boolean_member ("followed_by");
        rs.blocking = obj.get_boolean_member ("blocking");
        rs.muting = obj.get_boolean_member ("muting");
        rs.muting_notifications = obj.get_boolean_member ("muting_notifications");
        rs.requested = obj.get_boolean_member ("requested");
        rs.domain_blocking = obj.get_boolean_member ("domain_blocking");
        return rs;
    }

}
