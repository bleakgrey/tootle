using Gee;
public class Tootle.API.Poll {
    public string id { get; set; }
    public string expires_at{ get; set; }
    public bool expired { get; set; }
    public bool multiple { get; set; }
    public int64 votes_count { get; set; }
    public int64 voters_count { get; set; }
    public bool voted { get; set; }
    public int64[] own_votes { get; set; }
    public PollOption[]? options{ get; set; default = null; }

    public Poll (string _id) {
        id = _id;
    }
    public static Poll from_json (Json.Node node){
        Json.Object obj=node.get_object();
        var id = obj.get_string_member("id");
        var poll = new Poll (id);

        poll.expires_at = obj.get_string_member ("expires_at");
        poll.expired = obj.get_boolean_member ("expired");
        poll.multiple = obj.get_boolean_member ("multiple");
        poll.votes_count = obj.get_int_member ("votes_count");
        poll.voters_count = obj.get_int_member ("voters_count");
        poll.voted = obj.get_boolean_member ("voted");

        var votes = obj.get_array_member ("own_votes");
        int64[] array_votes={};
        votes.foreach_element((array, i, node) => {
            array_votes+=node.get_int();
        });
        poll.own_votes=array_votes;

        PollOption[]? _options = {};
        obj.get_array_member ("options").foreach_element ((array, i, node) => {
            var object = node.get_object ();
            if (object != null)
                _options += API.PollOption.parse (object);
        });
        if (_options.length > 0)
            poll.options = _options;
        return poll;
    }
    /**
    */
    public static Request vote (InstanceAccount acc,PollOption[] options,ArrayList<string> selection, string id) {
 		message (@"Voting poll $(id)...");
 		  //Creating json to send
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("choices");
        builder.begin_array ();
        var row_number=0;
        foreach (API.PollOption p in options){
            foreach (string select in selection){
                if (select == p.title){
	                builder.add_string_value (row_number.to_string());
	            }
            }
            row_number++;
	    }
	    builder.end_array ();
        builder.end_object ();
        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        var json = generator.to_data (null);
        //Send POST MESSAGE
		Request voting=new Request.POST (@"/api/v1/polls/$(id)/votes")
			.with_account (acc);
		voting.set_request("application/json",Soup.MemoryUse.COPY,json.data);
		return voting;

    }
}
