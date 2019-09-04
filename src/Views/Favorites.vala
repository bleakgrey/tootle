public class Tootle.Views.Favorites : Views.Timeline {

    public Favorites () {
        base ("favorites");
    }
    
    public override string get_url (){
        if (page_next != null)
            return page_next;
        
        var url = "%s/api/v1/favourites/?limit=%i".printf (accounts.active.instance, this.limit);
        return url;
    }

}
