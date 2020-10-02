using Gtk;

public class Tootle.Views.Main : Views.TabbedBase {

	Widgets.AccountsButton account_button;
	Button compose_button;

	construct {
		back_button.visible = false;

		account_button = new Widgets.AccountsButton ();
		account_button.show ();
		header.pack_start (account_button);

		compose_button = new Button.from_icon_name ("document-edit-symbolic");
		compose_button.tooltip_text = _("Compose");
		compose_button.action_name = "view.compose";
		compose_button.show ();
		header.pack_start (compose_button);

        // timeline_switcher.stack = timeline_stack;
        // timeline_switcher.valign = Align.FILL;
        // timeline_stack.notify["visible-child"].connect (on_timeline_changed);

        // add_timeline_view (new Views.Home (), app.ACCEL_TIMELINE_0, 0);
        // add_timeline_view (new Views.Notifications (), app.ACCEL_TIMELINE_1, 1);
        // add_timeline_view (new Views.Local (), app.ACCEL_TIMELINE_2, 2);
        // add_timeline_view (new Views.Federated (), app.ACCEL_TIMELINE_3, 3);
	}

    // void on_timeline_changed (ParamSpec spec) {
    //     var view = timeline_stack.visible_child as Views.Base;

    //     if (last_view != null)
    //         last_view.current = false;

    //     if (view != null) {
    //         view.current = true;
    //         last_view = view;
    //     }
    // }

	public Main () {
		add_tab (new Views.Home ());
		add_tab (new Views.Notifications ());
		add_tab (new Views.Local ());
		add_tab (new Views.Federated ());
	}

}
