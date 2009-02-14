using Galactica;
using GLib;

namespace Galactica {
  public class AudiotestsrcPlaylist : Object {
    GLib.MainLoop loop;
    Galactica.Playlist list;

    construct {
      loop = new MainLoop (null, false);
      list = new Galactica.Playlist ();
      list.add_track (new Galactica.CustomPipeline ("audiotestsrc freq=300 num-buffers=100 ! autoaudiosink"));
      list.add_track (new Galactica.CustomPipeline ("audiotestsrc freq=400 num-buffers=100 ! autoaudiosink"));
      list.add_track (new Galactica.CustomPipeline ("audiotestsrc freq=500 num-buffers=100 ! autoaudiosink"));

      list.auto_next = true;

      list.end_of_playlist += list => {
        loop.quit ();
      };

      list.new_track += (list, track, position) => {
        stdout.printf ("playing track %u/%u: %s\n", position, list.size, track.to_string());
      };
    }

    public void go () {
      list.play_next ();
      loop.run ();
    }

    public static void main (string[] args) {
      Gst.init (ref args);
      var ap = new AudiotestsrcPlaylist ();
      ap.go ();
    }
  }
}
