using Gtk;

public class Tootle.API.List : Entity, Widgetizable {

    [GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/lists.ui")]
    public class ListItemRow : ListBoxRow {

		API.List? list;

		[GtkChild]
		Stack stack;
		[GtkChild]
		Label title;
		[GtkChild]
		Button edit_button;
		[GtkChild]
		Button remove_button;

		public ListItemRow (List? list) {
			this.list = list;

			if (list == null) {
				stack.visible_child_name = "add";
			}
			else {
				this.title.label = list.title;
				this.remove_button.clicked.connect (() => {

				});
				this.edit_button.clicked.connect (() => {

				});
			}
		}

		public virtual signal void open () {
			if (this.list == null)
				return;

			var view = new Views.List (list);
			window.open_view (view);
		}
    }

    public string id { get; set; }
    public string title { get; set; }

	public static List from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.List), node) as API.List;
	}

    public override Gtk.Widget to_widget () {
        return new ListItemRow (this);
    }

}
