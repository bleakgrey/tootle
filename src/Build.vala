public class Build {

	public const string NAME = "@NAME@";
	public const string VERSION = "@VERSION@";
	public const string DOMAIN = "@EXEC_NAME@";
	public const string RESOURCES = "@RESOURCES@";
	public const string WEBSITE = "@WEBSITE@";
	public const string SUPPORT_WEBSITE = "@SUPPORT_WEBSITE@";
	public const string COPYRIGHT = "@COPYRIGHT@";
	public const string PREFIX = "@PREFIX@";

	// Please do not remove the credits below. You may add your own, but keep the existing ones intact.

	// TRANSLATORS: Replace this with your name. It will be displayed in the About dialog.
	public const string TRANSLATOR = _(" ");

	public static string[] get_authors () {
		return new string[] {
			"bleak_grey"
		};
	}

	public static string[] get_artists () {
		return new string[] {
			"Tobias Bernard"
		};
	}

    public static void print_info () {
    	var os_name = get_os_info ("NAME");
    	var os_ver = get_os_info ("VERSION");
        message (@"$NAME $VERSION");
        message (@"Running on: $os_name $os_ver");
        message (@"Build prefix: \"$PREFIX\"");
    }

	static string get_os_info (string key) {
		return GLib.Environment.get_os_info (key) ?? "Unknown";
	}

}
