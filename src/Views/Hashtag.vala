public class Tootle.Views.Hashtag : Views.Timeline {

    public Hashtag (string tag) {
        Object (timeline: @"tag/$tag");
    }

    public override Soup.Message? get_stream () {
        var tag = timeline.substring (4);
        var url = @"/api/v1/streaming/?stream=hashtag&tag=$tag&access_token=$(accounts.active.token)";
        return new Soup.Message ("GET", url);
    }

}
