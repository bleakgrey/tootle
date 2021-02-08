public class Tootle.Mastodon.Account : InstanceAccount {

	public const string BACKEND = "Mastodon";

	public static void register (AccountStore store) {
		store.create_for_backend[BACKEND].connect ((node) => {
			var account = Entity.from_json (typeof (Account), node) as Account;
			account.backend = BACKEND;
			return account;
		});
	}

}
