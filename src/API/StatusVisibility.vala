public enum Tootle.StatusVisibility {
    PUBLIC,
    UNLISTED,
    PRIVATE,
    DIRECT;

    public string to_string () {
        switch (this) {
            case PUBLIC:
                return "public";
            case UNLISTED:
                return "unlisted";
            case PRIVATE:
                return "private";
            case DIRECT:
                return "direct";
            default:
                assert_not_reached();
        }
    }
    
    public static StatusVisibility from_string (string str) {
        switch (str) {
            case "public":
                return StatusVisibility.PUBLIC;
            case "unlisted":
                return StatusVisibility.UNLISTED;
            case "private":
                return StatusVisibility.PRIVATE;
            case "direct":
                return StatusVisibility.DIRECT;
            default:
                assert_not_reached();
        }
    }
        
    public string get_desc () {
        switch (this) {
            case PUBLIC:
                return _("Post to public timelines");
            case UNLISTED:
                return _("Don\'t post to public timelines");
            case PRIVATE:
                return _("Post to followers only");
            case DIRECT:
                return _("Post to mentioned users only");
            default:
                assert_not_reached();
        }
    }
        
    public string get_icon () {
        switch (this) {
            case PUBLIC:
                return "network-workgroup-symbolic";
            case UNLISTED:
                return "view-private-symbolic";
            case PRIVATE:
                return "security-medium-symbolic";
            case DIRECT:
                return "mail-send-symbolic";
            default:
                assert_not_reached();
        }
    }
    
    public static StatusVisibility[] get_all () {
    	return {StatusVisibility.PUBLIC, StatusVisibility.UNLISTED, StatusVisibility.PRIVATE, StatusVisibility.DIRECT};
    }
    
}
