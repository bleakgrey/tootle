public class Tootle.Mastodon.Account : InstanceAccount {

	public const string BACKEND = "Mastodon";

	public const string EVENT_NEW_POST = "update";
	public const string EVENT_DELETE_POST = "delete";
	public const string EVENT_NOTIFICATION = "notification";

	class Test : AccountStore.BackendTest {

		public override string? get_backend (Json.Object obj) {
			return BACKEND; // Always treat instances as compatible with Mastodon
		}

	}

	public static void register (AccountStore store) {
		store.backend_tests.add (new Test ());
		store.create_for_backend[BACKEND].connect ((node) => {
			var account = Entity.from_json (typeof (Account), node) as Account;
			account.backend = BACKEND;
			return account;
		});
	}

	public override void populate_user_menu (GLib.ListStore model) {
		model.append (new Views.Sidebar.Item () {
			label = "Timelines",
			icon = "user-home-symbolic"
		});
		// model.append (new Views.Sidebar.Item () {
		// 	label = "Notifications",
		// 	icon = "preferences-system-notifications-symbolic"
		// });
		model.append (new Views.Sidebar.Item () {
			label = "Direct Messages",
			icon = API.Visibility.DIRECT.get_icon ()
		});
		model.append (new Views.Sidebar.Item () {
			label = "Bookmarks",
			icon = "user-bookmarks-symbolic"
		});
		model.append (new Views.Sidebar.Item () {
			label = "Favorites",
			icon = "non-starred-symbolic"
		});
		model.append (new Views.Sidebar.Item () {
			label = "Lists",
			icon = "view-list-symbolic"
		});
		model.append (new Views.Sidebar.Item () {
			label = "Search",
			icon = "system-search-symbolic"
		});
	}

}
