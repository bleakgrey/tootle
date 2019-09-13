using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/base.ui")]
public abstract class Tootle.Views.Abstract : ScrolledWindow {

    public static string STATUS_EMPTY = _("Nothing to see here");

    public bool current = false;
    public int stack_pos = -1;
    public Image? image;
    
    [GtkChild]
    public Grid view;
    [GtkChild]
    public Stack states;
    [GtkChild]
    public Box content;
    [GtkChild]
    public Label status_message_label;
    
    protected Grid? header; //TODO: Remove
    
    public string state { get; set; default = "status"; }
    public string status_message { get; set; default = STATUS_EMPTY; }
    public bool allow_closing { get; set; default = true; }
    
    public bool empty {
        get {
            return content.get_children ().length () <= 0;
        }
    }

    construct {
        bind_property ("state", states, "visible-child-name", BindingFlags.SYNC_CREATE);
		bind_property ("status-message", status_message_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		    var label = (string) src;
			target.set_string (@"<span size='large'>$label</span>");
			return true;
		});
        edge_reached.connect (pos => {
            if (pos == PositionType.BOTTOM)
                on_bottom_reached ();
        });
    }

    public virtual string get_icon () {
        return "null";
    }

    public virtual string get_name () {
        return "unnamed";
    }

    public virtual void clear (){
        content.forall (widget => {
            widget.destroy ();
        });
    }

    public virtual void on_bottom_reached () {}
    public virtual void on_set_current () {}

    public virtual bool empty_state () {
        if (empty) {
            status_message = STATUS_EMPTY;
            state = "status";
            return false;
        }
        else {
            state = "content";
            return true;
        }
    }

}
