using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/sidebar/view.ui")]
public class Tootle.Views.Sidebar : Box {

	[GtkChild] unowned ListBox accounts;

	public Sidebar () {}

}
