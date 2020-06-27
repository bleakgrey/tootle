using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/timeline_filter.ui")]
public class Tootle.Widgets.TimelineFilter : MenuButton {

	[GtkChild]
	public Label title;

	[GtkChild]
	public RadioButton radio_entity;
	[GtkChild]
	public RadioButton radio_post_filter;

}
