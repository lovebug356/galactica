using Galactica;

namespace Collective {
  public class Playlist : Collective.Session {
    public Galactica.Playlist playlist;

    construct {
      playlist = new Galactica.Playlist ();
    }

    public override void new_item_cb (Item item) {
      if (item.url == null) {
        return;
      }
      playlist.add_track (new Playbin2 (item.url));
    }
  }
}
