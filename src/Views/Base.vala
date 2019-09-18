using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/base.ui")]
public class Tootle.Views.Base : Box {

    public static string STATUS_EMPTY = _("Nothing to see here");

    public bool current = false;
    public int stack_pos = -1;
    public Image? image;

    [GtkChild]
    protected ScrolledWindow scrolled;
    [GtkChild]
    protected Box view;
    [GtkChild]
    protected Stack states;
    [GtkChild]
    protected Box content;
    [GtkChild]
    protected Label status_message_label;
    [GtkChild]
    protected Button status_button;

    public string state { get; set; default = "status"; }
    public string status_message { get; set; default = STATUS_EMPTY; }
    public bool allow_closing { get; set; default = true; }

    public bool empty {
        get {
            return content.get_children ().length () <= 0;
        }
    }

    construct {
        status_button.label = _("Reload");
        bind_property ("state", states, "visible-child-name", BindingFlags.SYNC_CREATE);
		bind_property ("status-message", status_message_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
		    var label = (string) src;
			target.set_string (@"<span size='large'>$label</span>");
			return true;
		});
        scrolled.edge_reached.connect (pos => {
            if (pos == PositionType.BOTTOM)
                on_bottom_reached ();
        });
        content.remove.connect (() => on_content_changed ());
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
        state = "status";
    }

    public virtual void on_bottom_reached () {}
    public virtual void on_set_current () {}

    public virtual void on_content_changed () {
        if (empty) {
            status_message = STATUS_EMPTY;
            status_button.visible = false;
            state = "status";
        }
        else {
            state = "content";
        }
        check_resize ();
    }

    public virtual void on_error (int32 code, string reason) {
        status_message = reason;
        status_button.visible = true;
        status_button.sensitive = true;
        state = "status";
    }

}
