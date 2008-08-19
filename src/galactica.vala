using Gst;
using GLib;

namespace Galactica {

  public class GalacticaApp : GLib.Object {
    const string version_string = "0.0.1";
    /* options stuff */
    static bool identify;
    static bool playbin2;
    static bool recursive;
    static bool repeat;
    static bool shuffle;
    static bool version;
    [NoArrayLength ()]
    static string[] opt_media_files;
    /* internal state stuff */
    private uint active_file;
    private List<string> media_files;
    /* GStreamer stuff */
    static MainLoop loop;
    private Gst.Pipeline pipeline;
    private Gst.Element playbin;
    private Gst.Bus bus;

    const OptionEntry[] options = {
      {"", 0, 0, OptionArg.FILENAME_ARRAY, ref opt_media_files, "media files", "FILE FOLDER..."},
      {"identify", 'i', 0, OptionArg.NONE, ref identify, "Print all the tags of the media files", null},
      {"playbin2", 'p', 0, OptionArg.NONE, ref version, "Use Playbin2", null},
      {"recursive", 'e', 0, OptionArg.NONE, ref recursive, "Search directories recursive", null},
      {"repeat", 'r', 0, OptionArg.NONE, ref repeat, "Repeat the playlist", null},
      {"shuffle", 's', 0, OptionArg.NONE, ref shuffle, "Shuffle playlist", null},
      {"version", 'v', 0, OptionArg.NONE, ref version, "Display version number", null},
      {null}
    };

    construct {
      active_file = 0;
      prepare_media_files ();
      pipeline = new Gst.Pipeline ("pipeline");
      if (playbin2)
        playbin = Gst.ElementFactory.make ("playbin2", "playbin");
      else
        playbin = Gst.ElementFactory.make ("playbin", "playbin");
      pipeline.add (playbin);
      bus = pipeline.get_bus ();
      bus.add_watch (bus_call);
      pipeline.set_state (Gst.State.NULL);
    }

    private void prepare_media_files () {
      media_files = new List<string> ();
      foreach (string media in opt_media_files)
        add_uri (media, true);
      media_files.sort ((CompareFunc)strcmp);
    }

    private void add_uri (string uri, bool recur) {
      if (FileUtils.test (uri, FileTest.EXISTS) && FileUtils.test (uri, FileTest.IS_DIR)) {
        if (!recur)
          return;
        Dir folder = Dir.open (uri);
        if (folder != null) {
          weak string item = folder.read_name ();
          while (item != null) {
            add_uri ("%s/%s".printf (uri, item), recursive);
            item = folder.read_name ();
          }
        }
      } else {
        string temp = convert_to_uri (uri);
        media_files.append (temp);
      }
    }

    ~GalacticaApp () {
      pipeline.set_state (Gst.State.NULL);
    }

    private bool bus_call (Gst.Bus bus, Gst.Message message) {
      switch (message.type) {
        case MessageType.EOS:
          stdout.printf ("EOS detected\n");
          load_next_or_quit ();
          break;
        case MessageType.ERROR:
          {
            remove_current_media_from_playlist ();
            GLib.Error error = null;
            message.parse_error (out error, null);
            stdout.printf ("Error:%s\n".printf (error.message));
            load_next_or_quit ();
          }
          break;
        case MessageType.TAG:
          {
            if (!identify)
              break;
            Gst.TagList tag_list = null;
            message.parse_tag (out tag_list);
            tag_list.foreach ((TagForeachFunc)dump_tag);
          }
          break;
        default:
          break;
      }
      return true;
    }

    private static void dump_tag_bool (Gst.TagList list, string tag, string name) {
      bool temp;
      list.get_boolean (tag, out temp);
      stdout.printf ("%s : %s\n", name, (temp ? "True" : "False"));
    }

    private static void dump_tag_time (Gst.TagList list, string tag, string name) {
      uint64 temp;
      list.get_uint64 (tag, out temp);
      uint64 second = temp / Gst.SECOND;
      temp %= Gst.SECOND;
      uint64 hour = second / 3600;
      second %= 3600;
      uint64 minute = second / 60;
      second %= 60;
      stdout.printf ("%s : %.2d:%.2d:%.2d.%d\n", name, (int)hour, (int)minute, (int)second, (int)temp);
    }

    private static void dump_tag (Gst.TagList list, string tag) {
      switch ((string)tag) {
        case TAG_TITLE:
        case TAG_ARTIST:
        case TAG_ALBUM:
        case TAG_GENRE:
        case TAG_AUDIO_CODEC:
        case TAG_ENCODER:
        case TAG_COMMENT:
        case "mode":
        case "emphasis":
        case "channel-mode":
          {
            string temp;
            list.get_string (tag, out temp);
            stdout.printf ("%s : %s\n", tag_get_nick (tag), temp);
          }
          break;
        case TAG_BITRATE:
        case TAG_NOMINAL_BITRATE:
        case TAG_ENCODER_VERSION:
        case TAG_TRACK_NUMBER:
        case "layer":
          {
            uint temp;
            list.get_uint (tag, out temp);
            if (tag == TAG_BITRATE || tag == TAG_NOMINAL_BITRATE)
            {
              double dtemp = temp / 1024.0;
              stdout.printf ("%s : %.2f kbits/sec\n", tag_get_nick (tag), dtemp);
            } else {
              stdout.printf ("%s : %d\n", tag_get_nick (tag), (int)temp);
            }
          }
          break;
        case "has-crc":
          dump_tag_bool (list, "has-crc", "Has CRC");
          break;
        case TAG_DURATION:
          dump_tag_time (list, TAG_DURATION, "Duration");
          break;
        default:
          stdout.printf ("unhandled tag : %s\n", tag);
          break;
      }
    }

    private void remove_current_media_from_playlist () {
      string media_file = media_files.nth_data (--active_file);
      media_files.remove_link (media_files.nth (active_file));
      stdout.printf ("Removing %s from playlist\n".printf (media_file));
    }

    private string convert_to_uri (string media_file) {
      if (Gst.uri_is_valid (media_file))
        return media_file;
      if (media_file.has_prefix ("/"))
        return "file://%s".printf (media_file);
      return "file://%s/%s".printf (Environment.get_current_dir (), media_file);
    }

    private void create_new_pipeline (string media_file) {
      stdout.printf ("Now playing (%d/%d): %s\n".printf ((int)active_file, (int)media_files.length (), media_file));
      if (pipeline != null) {
        pipeline.set_state (Gst.State.NULL);
      }
      playbin.set ("uri", media_file);
      pipeline.set_state (Gst.State.PAUSED);
    }

    public void load_next_or_quit () {
      if (!load_next ()) {
        stdout.printf ("End of playlist\n");
        loop.quit ();
      } else {
        start_playing ();
      }
    }

    private void shuffle_playlist () {
      stdout.printf ("Shuffle mode: shuffling playlist\n");
      var length = media_files.length ();
      List<string> temp_list = new List<string> ();
      foreach (string a in media_files)
        temp_list.append ("%s".printf (a));
      media_files = new List<string> ();
      while (temp_list.length () > 0) {
        int random = Random.int_range (0, (int32)temp_list.length ());
        media_files.append ("%s".printf (temp_list.nth_data (random)));
        temp_list.remove_link (temp_list.nth (random));
      }
    }

    public bool load_next () {
      if (media_files.length () == 0)
        return false;
      if (active_file == 0 && shuffle)
        shuffle_playlist ();
      string media_file = media_files.nth_data (active_file++);
      if (media_file != null) {
        create_new_pipeline (convert_to_uri (media_file));
        return true;
      } else {
        if (repeat && opt_media_files[0] != null) {
          stdout.printf ("Repeat mode: back to start of playlist\n");
          active_file = 0;
          return load_next ();
        }
        return false;
      }
    }

    public void start_playing () {
      pipeline.set_state (Gst.State.PLAYING);
    }

    public static int main (string [] args) {
      try {
        var opt_context = new OptionContext ("- Galactica Player");
        opt_context.set_help_enabled (true);
        opt_context.add_main_entries (options, null);
        opt_context.parse (ref args);
      } catch (OptionError e) {
        stdout.printf ("%s\n", e.message);
        stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
        return 1;
      }

      if (version) {
        stdout.printf ("Galactica Player %s\n".printf (version_string));
        return 1;
      }

      if (opt_media_files == null) {
        stderr.printf ("No media files specified.\n");
        return 1;
      }

      Gst.init (ref args);
      loop = new MainLoop (null, false);
      var gp = new GalacticaApp ();
      gp.load_next ();
      gp.start_playing ();
      loop.run ();
      return 0;
    }
  }
}
