using GLib;

public class Tootle.Time {

	public static string humanize_iso8601 (string iso8601) {
		var date = new DateTime.from_iso8601 (iso8601, null);
			//var humanized = Dazzle.g_date_time_format_for_display (date);
			// var time = date.difference (new GLib.DateTime.now ());
			// var humanized = Dazzle.g_time_span_to_label (time);
		return "";
	}

}
