using Gtk;

//FIXME: Timeline Header menu
public class Tootle.Widgets.TimelineMenu : Adw.Bin { //MenuButton

	public Label title;
	public Label subtitle;

	MenuButton widget;

	public TimelineMenu (string id) {
		var builder = new Builder.from_resource (@"$(Build.RESOURCES)widgets/timeline_menu.ui");
		widget = builder.current_object as MenuButton;
		title = builder.get_object ("title") as Label;
		subtitle = builder.get_object ("title") as Label;

		var menu_builder = new Builder.from_resource (@"$(Build.RESOURCES)ui/menus.ui");
		widget.menu_model = menu_builder.get_object (id) as MenuModel;
	}

}
