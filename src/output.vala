using GLib;
using Gst;

namespace Galactica {
  public class Output : Gst.Object {

    private bool busy; /* just to create a lock */
    private Element pipeline;
    public bool running;
    public bool old_new_line;


    construct {
      running = true;
    }

    [CCode (cname="expand_string")]
    public extern static string expand_string (string message, int length);
    [CCode (cname="console_width")]
    public extern int console_width ();

    private string message_scrap (string# message) {
      string[] list = message.split ("%");
      string temp = "";
      foreach (string a in list) {
        if (a != "") {
          if (temp == "")
            temp = a;
          else
            temp = temp + "%%" + a;
        }
      }
      return temp;
    }

    public void message (string m, bool new_line) {
      lock (busy) {
        string message = message_scrap (m);
        int expand_length = console_width () - (int)message.length;
        stdout.printf (message);
        if (expand_length > 0)
          stdout.printf (expand_string (" ", expand_length));
        if (new_line)
          stdout.printf ("\n");
        else
          stdout.printf ("\r");
        stdout.flush ();
      }
    }

    public string time_to_string (uint64 temp) {
      uint64 second = temp / Gst.SECOND;
      temp %= Gst.SECOND;
      uint64 hour = second / 3600;
      second %= 3600;
      uint64 minute = second / 60;
      second %= 60;
      temp = ( temp * 10 ) / SECOND;
      return "%.2d:%.2d:%.2d.%.1d".printf ((int)hour, (int)minute, (int)second, (int)temp);
    }

    public void query_pipeline (Element element) {
      running = false;
      lock (running) {
        pipeline = element;
        running = true;
      }
      try {
        Thread.create (query_duration, false);
      } catch (ThreadError er) {
        warning ("Failed to start a thread for query-ing the duration");
      }
    }

    public void query_stop () {
      running = false;
      lock (running) {};
    }

    public string progress_bar (double pos) {
      int fill;
      int cw = console_width ();

      if (cw < 30)
        return "";
      cw = cw - 30 - 2;
      if (pos > 1.0 || pos < 0.0)
        fill = 0;
      else
        fill = (int) (cw * pos);
      int empty = cw - fill;
      return "[" + expand_string ("=", fill) + expand_string (" ", empty) + "]";
    }

    public void* query_duration () {
      int update_duration = 10;
      int64 duration;
      lock (running) {
        while (running) {
          Thread.usleep (100000);
          int64 position;
          double pro;
          Format pos_f, dur_f;
          pos_f = dur_f = Format.TIME;
          pipeline.query_position (ref dur_f, out position);
          if (update_duration == 0 || duration == 0) {
            pipeline.query_duration (ref pos_f, out duration);
            update_duration = 10;
          } else {
            update_duration--;
          }
          if ((pos_f == dur_f) && (pos_f == Format.TIME)) {
            if (duration > 0)
              pro = ((double)position / (double)duration);
            else
              pro = 0;
            message (" %s %s : %s ".printf (progress_bar (pro), time_to_string (position), time_to_string (duration)), false);
          }
        }
      }
      return null;
    }
  }
}
