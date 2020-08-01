using Gtk;

public class Tootle.Widgets.Conversation : Widgets.Status {

	public API.Conversation conversation { get; construct set; }

	public Conversation (API.Conversation entity) {
		Object (conversation: entity, status: entity.last_status);
		this.actions.destroy ();
	}

	public new string title_text {
		owned get {
			var label = "";
			foreach (API.Account account in conversation.accounts) {
				label += "<b>" + Html.simplify (account.display_name) + "</b>";
				if (conversation.accounts.last () != account)
					label += ", ";
			}
			return @"$label";
		}
	}

	public new string subtitle_text {
		owned get {
			var label = "";
			foreach (API.Account account in conversation.accounts) {
				label += account.handle + " ";
			}
			return @"<small>$label</small>";
		}
	}

	public new string? avatar_url {
		owned get {
			if (conversation.accounts.size > 1)
				return null;
			else
				return conversation.accounts.get (0).avatar;
		}
	}

	public override void on_open () {
		conversation.open ();
	}

}
