using Gtk;

// This is a helper interface that calls dispose()
// when the widget's parent is destroyed
public interface Disposable: Widget {

	protected void construct_disposable () {
		map.connect (() => {
			var parent = get_parent ();
			parent.destroy.connect (() => {
				dispose ();
			});
		});
	}

}
