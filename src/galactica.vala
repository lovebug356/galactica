using Gst;
using GLib;

namespace Galactica {

  public class GalacticaApp : GLib.Object {
    const string version_string = "0.1.0";
    /* options stuff */
    static bool identify;
    static bool playbin2;
    static bool recursive;
    static bool repeat;
    static bool shuffle;
    static bool version;
    static bool no_qos;
    static bool no_audio;
    static bool no_video;
    static bool sync;
    [NoArrayLength ()]
    static string[] opt_media_files;
    static string custom_pipeline;
    static string m3u_filename;
    static Output output;
    /* internal state stuff */
    private uint active_file;
    private GLib.List<string> media_files;
    private Console cons;
    private bool playing;
    /* GStreamer stuff */
    static MainLoop loop;
    private Gst.Pipeline pipeline;
    private Gst.Element playbin;
    private Gst.Bus bus;
    private Gst.Element audio_sink;
    private Gst.Element video_sink;

    const OptionEntry[] options = {
      {"", 0, 0, OptionArg.FILENAME_ARRAY, ref opt_media_files, "media files", "FILE FOLDER..."},
      {"no-audio", 'a', 0, OptionArg.NONE, ref no_audio, "use fakesink as audio sink", null},
      {"custom-pipeline", 'c', 0, OptionArg.STRING, ref custom_pipeline, "Play a custom pipeline", null},
      {"no-video", 'd', 0, OptionArg.NONE, ref no_video, "use fakesink as video sink", null},
      {"recursive", 'e', 0, OptionArg.NONE, ref recursive, "Search directories recursive", null},
      {"sync", 'y', 0, OptionArg.NONE, ref sync, "Disable sync on the clock", null},
      {"identify", 'i', 0, OptionArg.NONE, ref identify, "Print all the tags of the media files", null},
      {"playbin2", 'p', 0, OptionArg.NONE, ref playbin2, "Use Playbin2", null},
      {"no-qos", 'q', 0, OptionArg.NONE, ref no_qos, "Disable qos", null},
      {"repeat", 'r', 0, OptionArg.NONE, ref repeat, "Repeat the playlist", null},
      {"shuffle", 's', 0, OptionArg.NONE, ref shuffle, "Shuffle playlist", null},
      {"version", 'v', 0, OptionArg.NONE, ref version, "Display version number", null},
      {"save-m3u", 'u', 0, OptionArg.STRING, ref m3u_filename, "Save playlist as m3u file", null},
      {null}
    };

    construct {
      active_file = 0;
      prepare_media_files ();
      save_m3u_file ();
      pipeline = new Gst.Pipeline ("pipeline");
      audio_sink = null;
      video_sink = null;
      if (custom_pipeline == null) {
        if (playbin2)
          playbin = Gst.ElementFactory.make ("playbin2", "playbin");
        else
          playbin = Gst.ElementFactory.make ("playbin", "playbin");
        disable_audio_sink ();
        disable_video_sink ();
        no_qos_element ();
        sync_element ();
      } else {
        output.message ("Using a custom pipeline: %s".printf (custom_pipeline), true);
        playbin = Gst.parse_launch (custom_pipeline);
      }
      pipeline.add (playbin);
      bus = pipeline.get_bus ();
      bus.add_watch (bus_call);
      output.query_stop ();
      pipeline.set_state (Gst.State.NULL);
      playing = false;
      cons = new Console ();
      cons.start ();
      cons.key_press += (cons, code) => console_keypress (code);
      cons.stopped += cons => console_stopped ();
    }

    private void console_stopped () {
      output.query_stop ();
      output.message ("Bye Bye", true);
      loop.quit ();
    }

    private void save_m3u_file () {
      if (m3u_filename != null) {
        string content = "";
        FileStream m3u = FileStream.open (m3u_filename, "w");
        foreach (string uri in media_files) {
          string[] parts = uri.split ("file://");
          foreach (string part in parts) {
            if (part != "") {
              m3u.printf (part);
              m3u.printf ("\n");
            }
          }
        }
        output.message ("saving playlist to : %s".printf (m3u_filename), true);
      }
    }

    private void no_qos_element () {
      if (no_qos) {
        if (audio_sink == null) {
          audio_sink = Gst.ElementFactory.make ("alsasink", null);
          playbin.set ("audio-sink", audio_sink);
        }
        audio_sink.set ("qos", false);
        if (video_sink == null) {
         video_sink = Gst.ElementFactory.make ("xvimagesink", null);
         playbin.set ("video-sink", video_sink);
        }
        video_sink.set ("qos", false);
      }
    }

    private void sync_element () {
      if (sync) {
        output.message ("Disable sync to clock", true);
        if (audio_sink == null) {
          audio_sink = Gst.ElementFactory.make ("alsasink", null);
          playbin.set ("audio-sink", audio_sink);
        }
        audio_sink.set ("sync", false);
        if (video_sink == null) {
         video_sink = Gst.ElementFactory.make ("xvimagesink", null);
          playbin.set ("video-sink", video_sink);
        }
        video_sink.set ("sync", false);
      }
    }

    private void disable_audio_sink () {
      if (no_audio ) {
        audio_sink = Gst.ElementFactory.make ("fakesink", null);
        playbin.set ("audio-sink", audio_sink);
      }
    }

    private void disable_video_sink () {
      if (no_video ) {
        video_sink = Gst.ElementFactory.make ("fakesink", null);
        playbin.set ("video-sink", video_sink);
      }
    }

    private void prepare_media_files () {
      media_files = new GLib.List<string> ();
      int i = 0;
      string media = opt_media_files[i++];
      while (media != null) {
        add_uri (media, true);
        media = opt_media_files[i++];
      }
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
        if (uri.has_suffix ("m3u")) {
          load_m3u_file (uri);
        } else {
          string temp = convert_to_uri (uri);
          media_files.append (temp);
        }
      }
    }

    ~GalacticaApp () {
      output.query_stop ();
      pipeline.set_state (Gst.State.NULL);
    }

    private void load_m3u_file (string uri) {
      string content;
      ulong len;
      string[] m3u_item;
      string[] folders;
      string base_dir = "";
      string last = "";

      output.message ("Parsing file as m3u file %s".printf (uri), true);

      /* find the base dir of the uri */
      folders = uri.split("/");
      foreach (string f in folders) {
        base_dir = base_dir + last;
        last = f + "/";
      }

      FileUtils.get_contents (uri, out content, out len);
      m3u_item = content.split ("\n");

      foreach (string item in m3u_item) {
        if (item != "" && !item.has_prefix ("#")) {
          if (item.has_prefix ("http://"))
            add_uri (item, false);
          else
            add_uri (base_dir + item, false);
        }
      }
    }

    private bool bus_call (Gst.Bus bus, Gst.Message message) {
      switch (message.type) {
        case MessageType.EOS:
          output.message ("EOS detected", false);
          lock (pipeline) {
            load_next_or_quit ();
          }
          break;
        case MessageType.ERROR:
          {
            remove_current_media_from_playlist ();
            GLib.Error error = null;
            message.parse_error (out error, null);
            output.message ("Error : %s".printf (error.message), true);
            lock (pipeline) {
              load_next_or_quit ();
            }
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
        case MessageType.BUFFERING:
          var s = message.get_structure ();
          int p;
          s.get_int ("buffer-percent", out p);
          output.message ("Buffering : %d %%".printf (p), false);
          stdout.flush ();
          break;
        default:
          break;
      }
      return true;
    }

    private static void dump_tag_bool (Gst.TagList list, string tag, string name) {
      bool temp;
      list.get_boolean (tag, out temp);
      output.message ("%s : %s".printf (name, (temp ? "True" : "False")), true);
    }

    private static void dump_tag_time (Gst.TagList list, string tag, string name) {
      uint64 temp;
      list.get_uint64 (tag, out temp);
      output.message ("%s : %s".printf (name, output.time_to_string (temp)), true);
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
            output.message ("%s : %s".printf (tag_get_nick (tag), temp), true);
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
              output.message ("%s : %.2f kbits/sec".printf (tag_get_nick (tag), dtemp), true);
            } else {
              output.message ("%s : %d".printf (tag_get_nick (tag), (int)temp), true);
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
          output.message ("unhandled tag : %s".printf (tag), true);
          break;
      }
    }

    private void remove_current_media_from_playlist () {
      string media_file = media_files.nth_data (--active_file);
      media_files.remove_link (media_files.nth (active_file));
      output.message ("Removing %s from playlist".printf (media_file), true);
    }

    private string convert_to_uri (string media_file) {
      if (Gst.uri_is_valid (media_file))
        return media_file;
      if (media_file.has_prefix ("/"))
        return "file://%s".printf (media_file);
      return "file://%s/%s".printf (Environment.get_current_dir (), media_file);
    }

    private void create_new_pipeline (string media_file) {
      output.message ("Now playing (%d/%d): %s".printf ((int)active_file, (int)media_files.length (), media_file), true);
      if (pipeline != null) {
        pipeline.set_state (Gst.State.NULL);
      }
      playbin.set ("uri", media_file);
      output.query_stop ();
      pipeline.set_state (Gst.State.PAUSED);
      playing = false;
    }

    public void load_next_or_quit () {
      if (!load_next ()) {
        output.message ("End of playlist", true);
        cons.stop ();
      } else {
        start_playing ();
      }
    }

    private void shuffle_playlist () {
      output.message ("Shuffle mode: shuffling playlist", true);
      var length = media_files.length ();
      GLib.List<string> temp_list = new GLib.List<string> ();
      foreach (string a in media_files)
        temp_list.append ("%s".printf (a));
      media_files = new GLib.List<string> ();
      while (temp_list.length () > 0) {
        int random = Random.int_range (0, (int32)temp_list.length ());
        media_files.append ("%s".printf (temp_list.nth_data (random)));
        temp_list.remove_link (temp_list.nth (random));
      }
    }

    public void load_prev () {
      if (active_file <= 2)
        active_file = 0;
      else
        active_file -= 2;
      if (load_next ())
        start_playing ();
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
          output.message ("Repeat mode: back to start of playlist", true);
          active_file = 0;
          return load_next ();
        }
        return false;
      }
    }

    public void start_playing () {
      output.query_pipeline (pipeline);
      pipeline.set_state (Gst.State.PLAYING);
      playing = true;
    }

    private void seek (bool forward, int sec) {
      int64 pos;
      Gst.Format format;

      format = Format.TIME;
      pipeline.query_position (ref format, out pos);
      if (format != Format.TIME) {
        output.message  ("seeking is not supported in this format (%d)".printf (format), true);
        return;
      }
      if (format == CLOCK_TIME_NONE) {
        output.message ("Failed to query position can't seek", true);
        return;
      }
      if (forward)
        pos += (sec * SECOND);
      else
        pos -= (sec * SECOND);
      if (pos < 0)
        pos = 0;
      pipeline.seek_simple (format, SeekFlags.FLUSH, pos);
    }

    private void console_keypress (int code) {
      if (code == 113 || code == 3) {
        cons.stop ();
      } else if (code == 32) {
        lock (pipeline) {
          if (playing) {
            output.query_stop ();
            pipeline.set_state (State.PAUSED);
            output.message ("=== PAUSED ===", false);
            playing = false;
          } else {
            start_playing ();
          }
        }
      } else if (code == 110) {
        lock (pipeline) {
          load_next_or_quit ();
        }
      } else if (code == 112) {
        lock (pipeline) {
          load_prev ();
        }
      } else if (code == 67 || code == 108) {
        lock (pipeline) {
          seek (true, 10);
        }
      } else if (code == 68 || code == 104) {
        lock (pipeline) {
          seek (false, 10);
        }
      } else if (code == 65 || code == 107) {
        lock (pipeline) {
          seek (true, 60);
        }
      } else if (code == 66 || code == 106) {
        lock (pipeline) {
          seek (false, 60);
        }
      } else if (code == 114) {
        lock (pipeline) {
          remove_current_media_from_playlist ();
          load_next_or_quit ();
        }
      } else {
        // message ("code %d", code);
      }
    }

    public static int main (string [] args) {
      output = new Output ();

      try {
        var opt_context = new OptionContext ("- Galactica Player");
        opt_context.set_help_enabled (true);
        opt_context.add_main_entries (options, null);
        opt_context.parse (ref args);
      } catch (OptionError e) {
        output.message ("%s".printf (e.message), true);
        output.message ("Run '%s --help' to see a full list of available command line options.".printf (args[0]), true);
        return 1;
      }

      output.message ("Galactica Player %s".printf (version_string), true);
      if (version) {
        return 1;
      }

      if (opt_media_files == null && custom_pipeline == null) {
        output.message ("No media files specified.", true);
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
