using Gst;
using GLib;

namespace Galactica {

  public class GalacticaCLI : GLib.Object {
    /* options stuff */
    static bool playbin2;
    static bool repeat;
    static bool shuffle;
    static bool version;
    static bool disable_audio;
    static bool disable_video;
    static bool custom_pipeline;
    [NoArrayLength ()]
    static string[] opt_media_files;
    static string configuration_file;
    static MainLoop loop;
    Galactica.Playlist playlist;
    Galactica.PlaylistBuilder builder;
    Galactica.Output output;
    Galactica.Console console;

    const OptionEntry[] options = {
      {"", 0, 0, OptionArg.FILENAME_ARRAY, ref opt_media_files, "media files", "FILE FOLDER..."},
      {"disable-audio", 'a', 0, OptionArg.NONE, ref disable_audio, "use fakesink as audio sink", null},
      {"custom-pipeline", 'p', 0, OptionArg.NONE, ref custom_pipeline, "Play a custom pipeline", null},
      {"disable-video", 'd', 0, OptionArg.NONE, ref disable_video, "use fakesink as video sink", null},
      {"playbin2", 'p', 0, OptionArg.NONE, ref playbin2, "Use Playbin2", null},
      {"repeat", 'r', 0, OptionArg.NONE, ref repeat, "Repeat the playlist", null},
      {"shuffle", 's', 0, OptionArg.NONE, ref shuffle, "Shuffle playlist", null},
      {"version", 'v', 0, OptionArg.NONE, ref version, "Display version number", null},
      {"configuration-file", 'c', 0, OptionArg.FILENAME, ref configuration_file, "provide a lua configuration file", null},
      {null}
    };

    construct {
      loop = new MainLoop (null, false);

      output = new Galactica.Output ();

      console = new Console ();
      console.key_press += (cons, code) => console_keypress (code);

      builder = new Galactica.PlaylistBuilder ();
      /* set some options on the builder */
      builder.disable_video = disable_video;
      builder.disable_audio = disable_audio;
      builder.custom_pipeline = custom_pipeline;
      builder.playbin2 = playbin2;

      /* add the media files */
      int i = 0;
      string uri = opt_media_files[i++];
      while (uri != null) {
        builder.uri_add (uri);
        uri = opt_media_files[i++];
      }

      playlist = builder.get_playlist ();
      /* set some options on the playlist */
      playlist.repeat = repeat;
      playlist.shuffle = shuffle;
      playlist.auto_next = true;
      playlist.new_track += (list, track, position) => output.new_track (track.to_string (), position, list.size);
      playlist.update_position += (list, pos, dur) => output.update_position (pos, dur);
      playlist.state_paused += list => output.state_paused ();
      playlist.end_of_playlist += list => quit ();
      playlist.error += (list, err) => {
        output.error (err);
        list.remove_current_track ();
        list.play_next ();
      };
      playlist.no_tracks += list => output.error ("No tracks in playlist");
      playlist.buffering += (list, per) => output.buffering (per);

      /* init lua bindings */
      Galactica.Lua.init (playlist, quit);
    }

    void console_keypress (int code) {
      Galactica.Lua.configuration_action (code);
      /*message ("code %d", code);*/
    }

    public void quit () {
      playlist.stop ();
      console.stop ();
      loop.quit ();
    }

    public void run () {
      Galactica.Lua.load_configuration_file (configuration_file);
      console.start ();
      playlist.start_query_position ();
      if (playlist.play_next ())
        loop.run ();
    }

    public static int main (string [] args) {
      try {
        var opt_context = new OptionContext ("- Galactica Player");
        opt_context.set_help_enabled (true);
        opt_context.add_main_entries (options, null);
        opt_context.parse (ref args);
      } catch (OptionError e) {
        stdout.printf ("%s\n", e.message);
        stdout.printf ("Run '%s --help' to see a full list of available command line options.", args[0]);
        return 1;
      }

      stdout.printf ("Galactica Player %s\n", Config.VERSION);
      if (version) {
        return 1;
      }

      if (opt_media_files == null) {
        stdout.printf ("No media files specified.\n");
        return 1;
      }

      Gst.init (ref args);

      var player = new GalacticaCLI ();

      player.run ();
      return 0;
    }
  }
}
