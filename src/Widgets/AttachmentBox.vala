using Gtk;
using GLib;

public class Tootle.AttachmentBox : Gtk.ScrolledWindow {

    private Gtk.Box box;
    private bool edit_mode;

    construct {
        box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.hexpand = true;
        add (box);
        show_all ();
    }

    public AttachmentBox (bool edit = false) {
        Object ();
        edit_mode = edit;
        vscrollbar_policy = Gtk.PolicyType.NEVER;
    }
    
    public void clear () {
        box.forall (widget => widget.destroy ());
    }
    
    public void append (Attachment attachment) {
        var widget = new AttachmentWidget (attachment);
        box.add (widget);
    }
    
    public void select () {
        var filter = new Gtk.FileFilter ();
        filter.add_mime_type ("image/jpeg");
        filter.add_mime_type ("image/png");
        filter.add_mime_type ("image/gif");
        filter.add_mime_type ("video/webm");
        filter.add_mime_type ("video/mp4");
        
        var chooser = new Gtk.FileChooserNative (
            _("Select media files to add"),
            null,
            Gtk.FileChooserAction.OPEN,
            _("_Open"),
            _("_Cancel"));
        
        chooser.select_multiple = true;
        chooser.set_filter (filter);
        
        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            show ();
            foreach (unowned string uri in chooser.get_uris ()) {
                var widget = new AttachmentWidget.upload (uri);
                box.pack_start (widget, false, false, 6);
            }
        }
    }
    
    public string get_uri_array () {
        var str = "";
        box.get_children ().@foreach (widget => {
            var w = (AttachmentWidget) widget;
            if (w.attachment != null)
                str += "&media_ids[]=%lld".printf (w.attachment.id);
        });
        return str;
    }

}
