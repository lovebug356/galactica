using Galactica;
using GLib;

namespace Galactica {
  public class FilePlayer : Object {
    GLib.MainLoop loop;
    Galactica.Playlist list;
    Galactica.PlaylistBuilder builder;

    construct {
      loop = new MainLoop (null, false);

      builder = new Galactica.PlaylistBuilder ();

    }

    public void add_uri (string uri) {
      builder.uri_add (uri);
    }

    public void go () {
      list = builder.get_playlist ();

      list.end_of_playlist += list => {
        loop.quit ();
      };

      list.error += (list, msg) => {
        stdout.printf ("error: %s\n", msg);
        list.remove_current_track ();
        list.play_next ();
      };

      list.new_track += (list, track, position) => {
        stdout.printf ("playing track %u/%u: %s\n", position, list.size, track.to_string());
      };
      list.play_next ();
      loop.run ();
    }

    public static void main (string[] args) {
      Gst.init (ref args);
      var ap = new FilePlayer ();
      for (int i= 1; i < args.length ; i++) {
        ap.add_uri (args[i]);
      }
      ap.go ();
    }
  }
}
