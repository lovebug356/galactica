using Galactica;
using Core.Container;
using Gst;

namespace Galactica {
  public class Playlist : Galactica.Object {
    ArrayList<Galactica.Track> tracks;
    Gst.Element pipeline;
    Gst.Element element;
    Gst.Bus bus;
    bool query_position;
    bool pipeline_is_playing;

    public Galactica.Track current_track;

    /* properties */
    public bool shuffle {get;set;default=false;}
    public bool repeat {get;set;default=false;}
    public bool auto_next {get;set;default=false;}
    public bool auto_remove {get;set;default=false;}
    public bool no_position_update {get;set;default=false;}
    public int64 position_delay {get;set;default=100000;}

    /* signals */
    public signal void no_tracks ();
    public signal void end_of_playlist ();
    public signal void eos ();
    public signal void new_track (Galactica.Track track, int position);
    public signal void new_size (int new_size);
    public signal void error (string error_message);
    public signal void update_position (int64 position, int64 duration);
    public signal void buffering (int percentage);
    public signal void state_playing ();
    public signal void state_paused ();
    public signal void state_stopped ();

    public int size {
      get {
        return tracks.size;
      }
    }

    construct {
      tracks = new ArrayList<Galactica.Track> ();
      current_track = null;
      pipeline = new Gst.Pipeline ("galactica");
      bus = pipeline.get_bus ();
      bus.add_watch (bus_cb);
      pipeline_is_playing = false;
    }

    ~Playlist () {
      query_position = false;
    }

    public void start_query_position (int64 position_delay = -1) {
      if (position_delay != Gst.CLOCK_TIME_NONE) {
        this.position_delay = position_delay;
      }

      query_position = true;
      try {
        Thread.create (query_duration, false);
      } catch (Error e) {
      }
    }

    public void* query_duration () {
      int64 duration = 0;
      int64 position = 0;
      while (query_position) {
        Thread.usleep ((long)position_delay);
        Gst.Format position_format, duration_format;
        position_format = duration_format = Format.TIME;
        lock (pipeline) {
          pipeline.query_position (ref duration_format, out position);
          pipeline.query_duration (ref position_format, out duration);
        }
        if ((position_format == Format.TIME) && (position_format == Format.TIME)) {
          if (pipeline_is_playing && !no_position_update)
            update_position (position, duration);
        }
      }
      return null;
    }

    bool bus_cb (Gst.Bus bus, Gst.Message msg) {
      switch (msg.type) {
        case Gst.MessageType.EOS:
          if (auto_next) {
            play_next ();
          } else {
            eos ();
          }
          break;
        case Gst.MessageType.ERROR:
          if (auto_remove) {
            remove_track (current_track);
          } else {
            GLib.Error err = null;
            msg.parse_error (out err, null);
            error (err.message);
          }
          break;
        case Gst.MessageType.BUFFERING:
          var s = msg.get_structure ();
          int p;
          s.get_int ("buffer-percent", out p);
          buffering (p);
          break;
        case Gst.MessageType.STATE_CHANGED:
          if (msg.src == pipeline) {
            Gst.State new_state;
            msg.parse_state_changed (null, out new_state, null);
            switch (new_state) {
              case Gst.State.PLAYING:
                state_playing ();
                pipeline_is_playing = true;
                break;
              case Gst.State.PAUSED:
                state_paused ();
                pipeline_is_playing = false;
                break;
              default:
                state_stopped ();
                pipeline_is_playing = false;
                break;
            }
          }
          break;
        default:
          break;
      }
      return true;
    }

    public void add_track (Galactica.Track track) {
      lock (pipeline) {
        tracks.add (track);
      }
      new_size (size);
    }

    public void remove_track (Galactica.Track track) {
      lock (pipeline) {
        tracks.remove (track);
      }
      new_size (size);
    }

    void remove_current_element () {
      lock (pipeline) {
        stop ();
        if (element != null)
          ((Gst.Bin)pipeline).remove (element);
        element = null;
      }
    }

    public void remove_current_track () {
      lock (pipeline) {
        if (current_track == null)
          return;

        remove_current_element ();
        var position = tracks.index_of (current_track);
        remove_track (current_track);
        if (position == 0 || tracks.size >= (position + 1)) {
          current_track = null;
        } else {
          current_track = tracks.get (position - 1);
        }
      }
    }

    public void play_prev () {
      lock (pipeline) {
        if (current_track != null) {
          var pos = tracks.index_of (current_track);
          if (pos != 0) {
            current_track = tracks.get (pos - 1);
            play_current ();
          }
        }
      }
    }

    void play_current () {
      lock (pipeline) {
        remove_current_element ();
        new_track (current_track, tracks.index_of (current_track) + 1);
        element = current_track.get_element (null);
        ((Gst.Bin)pipeline).add (element);
        resume ();
      }
    }

    void shuffle_tracks () {
      lock (pipeline) {
        int shuffle_length = size * 2;
        while (shuffle_length-- > 0) {
          Galactica.Track track = tracks.get (0);
          tracks.remove_at (0);
          tracks.insert (Random.int_range (0, tracks.size + 1), track);
        }
      }
    }

    public bool play_next () {
      bool ret = true;
      bool loop = false;

      lock (pipeline) {
        if (current_track == null) {
          if (tracks.size == 0) {
            no_tracks ();
            end_of_playlist ();
            current_track = null;
            ret = false;
          } else {
            if (shuffle)
              shuffle_tracks ();
            current_track = tracks.get (0);
          }
        } else {
          var pos = tracks.index_of (current_track);
          if (tracks.size <= (pos + 1)) {
            if (!repeat) {
              end_of_playlist ();
              current_track = null;
              ret = false;
            } else {
              current_track = null;
              loop = true;
            }
          } else {
            current_track = tracks.get (pos + 1);
          }
        }
        if (current_track != null)
          play_current ();
      }
      if (loop)
        ret = play_next ();
      return ret;
    }

    public void seek (int seconds) {
      int64 position;
      Gst.Format format;

      lock (pipeline) {
        format = Format.TIME;
        pipeline.query_position (ref format, out position);

        if (format == Format.TIME && position != CLOCK_TIME_NONE) {
          position += (seconds * SECOND);
          if (position < 0)
            position = 0;

          pipeline.seek_simple (format, SeekFlags.FLUSH, position);
        }
      }
    }

    public void toggle_play_pause () {
      if (pipeline_is_playing) {
        pause ();
      } else {
        resume ();
      }
    }

    public void resume () {
      pipeline.set_state (Gst.State.PLAYING);
    }

    public void pause () {
      pipeline.set_state (Gst.State.PAUSED);
    }

    public void stop () {
      pipeline.set_state (Gst.State.NULL);
    }
  }
}
