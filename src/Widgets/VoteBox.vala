using Gtk;
using Gdk;
using Gee;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/votebox.ui")]
public class Tootle.Widgets.VoteBox: Box {
	[GtkChild] protected Gtk.Box pollBox;
	[GtkChild] protected Gtk.Button button_vote;

	public API.Poll? poll { get; set;}
	public API.Account? account { get; set;}

    protected ArrayList<string> selectedIndex=new ArrayList<string>();

	construct{

        button_vote.set_label (_("Vote"));
        button_vote.clicked.connect ((button) =>{
            Request voting=API.Poll.vote(accounts.active,poll.options,selectedIndex,poll.id);
            voting.then ((sess, mess) => {
	            var node = network.parse_node (mess);
	            var poll_updated=API.Poll.from_json(typeof(API.Poll),node);
                poll.expired=poll_updated.expired;
                poll.votes_count=poll_updated.votes_count;
                poll.voters_count=poll_updated.voters_count;
                poll.voted=poll_updated.voted;
                poll.own_votes=poll_updated.own_votes;
                poll.options=poll_updated.options;
                update();
	            message ("OK: Voting correctly");
            })
            .on_error ((code, reason) => {
	            warning ("Voting invalid!");
	            app.error (
		            _("Network Error"),
		            _("The instance has invalidated this session. Please sign in again.\n\n%s").printf (reason)
	            );
            }).exec ();
        });
        notify["poll"].connect (update);
        notify["account"].connect (update);
        update();
	}

	void update(){
	    if (poll==null || account == null)
	    {
	        button_vote.hide();
	        return;
	    }
	    GLib.List<weak Gtk.Widget> children=pollBox.get_children();
	    foreach (Widget child in children){
	        pollBox.remove(child);
	    }
        var row_number=0;
        Gtk.RadioButton[] radios={};
        Gtk.CheckButton[] checks={};
        if (poll.own_votes.size==0 && !poll.multiple){
            var element=poll.options.get(0);
            selectedIndex.add(element.title);
        }
        foreach (API.PollOption p in poll.options){
            //if it is own poll
            if(account.id==accounts.active.id){
                // If multiple, Checkbox else radioButton
                var option = new Widgets.RichLabel (p.title+" "+_("Votes:  %s".printf ((p.votes_count).to_string())));
                pollBox.add(option);
           }
            else{
                 // If multiple, Checkbox else radioButton
                if (poll.multiple){
                    var check_option = new Gtk.CheckButton ();
                    check_option.set_label(p.title);
                    check_option.toggled.connect((radio)=>{
                        if (selectedIndex.contains(radio.get_label())){
                            selectedIndex.remove(radio.get_label());
                        }
                        else{
                            selectedIndex.add(radio.get_label());
                        }
                    });
                    foreach (int own_vote in poll.own_votes){
                        if (own_vote==row_number){
                             check_option.set_active(true);
                              if (!selectedIndex.contains(p.title)){
                                selectedIndex.add(p.title);
                              }
                        }
                    }
                    if(poll.expired || poll.voted){
                        check_option.set_sensitive(false);
                    }
                    pollBox.add(check_option);
                    checks+=check_option;
                }else{
                    //If not multiple, chose RadioButton
                    Gtk.RadioButton radio_option = null;
                    if (radios.length==0){
                        radio_option=new Gtk.RadioButton (null);
                    }
                    else{
                        radio_option=new Gtk.RadioButton (radios[0].get_group());
                    }
                    radio_option.set_label(p.title);
                    radio_option.toggled.connect((radiobutton)=>{
                        if (selectedIndex.contains(radiobutton.get_label()))
                        {
                            selectedIndex.remove(radiobutton.get_label());
                        }
                        else{
                            selectedIndex.add(radiobutton.get_label());
                        }
                    });

                    foreach (int own_vote in poll.own_votes){
                        if (own_vote==row_number){
                             radio_option.set_active(true);
                             selectedIndex=new ArrayList<string>();
                             if (!selectedIndex.contains(p.title)){
                                selectedIndex.add(p.title);
                             }
                        }
                    }
                    if(poll.expired || poll.voted){
                        radio_option.set_sensitive(false);
                    }
                    pollBox.add(radio_option);
                    radios+=radio_option;
                }
            }
            row_number++;
        }
        if(row_number>0 && !poll.expired && !poll.voted &&
            account.id!=accounts.active.id ){
            button_vote.show();
        }
        else{
            button_vote.hide();
        }
        pollBox.show_all();
	}

}
