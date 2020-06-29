using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/timeline_filter.ui")]
public class Tootle.Widgets.TimelineFilter : MenuButton {

	[GtkChild]
	public Label title;

	[GtkChild]
	public RadioButton radio_source;

	[GtkChild]
	public Revealer post_filter;
	[GtkChild]
	public RadioButton radio_post_filter;

	construct {
		radio_source.bind_property ("active", post_filter, "reveal-child", BindingFlags.SYNC_CREATE);
	}

	public TimelineFilter.with_profile (Views.Profile view) {
		radio_source.get_group ().@foreach (w => {
			w.toggled.connect (() => {
				if (w.active) {
					var entity = typeof (API.Status);
					if (w.name != "statuses")
						entity = typeof (API.Account);

					view.page_next = null;
					view.url = @"/api/v1/accounts/$(view.profile.id)/$(w.name)";
					view.accepts = entity;
					view.on_refresh ();
				}
			});
		});
	}

}
