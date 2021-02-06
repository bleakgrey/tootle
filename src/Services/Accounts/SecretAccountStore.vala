using Secret;

public class Tootle.SecretAccountStore : AccountStore {

	const string SUPPORTED_VERSION = "1";
	const string ATTR_VERSION = "version";

	Secret.Schema schema;
	GLib.HashTable<string,SchemaAttributeType> schema_attributes;

	public override void init () throws GLib.Error {
		message (@"Using libsecret v$(Secret.MAJOR_VERSION).$(Secret.MINOR_VERSION).$(Secret.MICRO_VERSION)");

		schema_attributes = new GLib.HashTable<string,SchemaAttributeType> (str_hash, str_equal);
		schema_attributes["login"] = SchemaAttributeType.STRING;
		schema_attributes[ATTR_VERSION] = SchemaAttributeType.STRING;
		schema = new Secret.Schema.newv (
			Build.DOMAIN,
			Secret.SchemaFlags.NONE,
			schema_attributes
		);

		base.init ();
	}

	public override void load () {
		var attrs = new GLib.HashTable<string,string> (str_hash, str_equal);
		attrs["version"] = SUPPORTED_VERSION;

		var secrets = Secret.password_searchv_sync (
			schema,
			attrs,
			Secret.SearchFlags.ALL,
			null
		);

		secrets.foreach (item => {
			try {
				var account = secret_to_account (item);
				saved.add (account);
			}
			catch (GLib.Error e) {
				warning (@"Couldn't retrieve account from keyring: $(e.message)");
			}
		});

		message (@"Loaded $(saved.size) accounts");
	}

	public override void save () {

	}

	void account_to_secret (InstanceAccount account) throws GLib.Error {
		var attrs = new GLib.HashTable<string,string> (str_hash, str_equal);
		attrs["login"] = account.handle;
		attrs[ATTR_VERSION] = SUPPORTED_VERSION;

		var generator = new Json.Generator ();
		generator.set_root (account.to_json ());
		var secret = generator.to_data (null);
		warning (secret);
		var label = _("%s Account").printf ("Mastodon");

		Secret.password_storev_sync (
			schema,
			attrs,
			Secret.COLLECTION_DEFAULT,
			label,
			secret,
			null
		);
		message (@"Saved secret for $(account.handle)");
	}

	InstanceAccount? secret_to_account (Secret.Retrievable item) throws GLib.Error {
		var secret = item.retrieve_secret_sync ();
		var contents = secret.get_text ();

		var parser = new Json.Parser ();
		parser.load_from_data (contents, -1);

		var account = InstanceAccount.from (parser.get_root ());
		return account;
	}

}
