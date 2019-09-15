using Gtk;
using GLib;
using Gee;

public class Tootle.Widgets.Attachment.Box : FlowBox {

	public bool editing { get; construct set; }

	construct {
	    hexpand = true;
	}

	public Box (bool editing = false) {
		Object (editing: editing);
	}

    public void select () {
        var filter = new Gtk.FileFilter ();
        filter.add_mime_type ("image/jpeg");
        filter.add_mime_type ("image/png");
        filter.add_mime_type ("image/gif");
        filter.add_mime_type ("video/webm");
        filter.add_mime_type ("video/mp4");

        var chooser = new Gtk.FileChooserDialog (
            _("Select media files to add"),
            null,
            Gtk.FileChooserAction.OPEN,
            _("_Cancel"),
            Gtk.ResponseType.CANCEL,
            _("_Open"),
            Gtk.ResponseType.ACCEPT);

        chooser.select_multiple = true;
        chooser.set_filter (filter);

        if (chooser.run () == ResponseType.ACCEPT) {
            show ();
            foreach (unowned string uri in chooser.get_uris ()) {
                //var widget = new ImageAttachment.upload (uri);
                //append_widget (widget);
            }
        }
        chooser.close ();
    }

}
