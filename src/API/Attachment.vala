public class Tootle.API.Attachment : Entity {

	public string id { get; set; }
	public string kind { get; set; }
	public string url { get; set; }
	public string? description { get; set; }
	public string? _preview_url { get; set; }
	public string? preview_url {
		set { this._preview_url = value; }
		get { return (this._preview_url == null || this._preview_url == "") ? url : _preview_url; }
	}

	public static Attachment from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Attachment), node) as API.Attachment;
	}

}
