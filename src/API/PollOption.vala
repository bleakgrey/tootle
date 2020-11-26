public class Tootle.API.PollOption {
    public string title { get; set; }
    public int64 votes_count{ get; set; }

    public static PollOption parse (Json.Object obj) {
        var pollOption = new PollOption ();
        pollOption.title = obj.get_string_member ("title");
        pollOption.votes_count = obj.get_int_member ("votes_count");
        return pollOption;
    }
}
