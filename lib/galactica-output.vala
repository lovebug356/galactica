using GLib;
using Gst;

namespace Galactica {
  public class Output : Gst.Object {

    public bool old_new_line;

    [CCode (cname="expand_string")]
    public extern static string expand_string (string message, int length);
    [CCode (cname="console_width")]
    public extern int console_width ();

    private string message_scrap (owned string message) {
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
      string message = message_scrap (m);
      int expand_length = console_width () - (int)message.length;
      stdout.printf ("%s", message);
      if (expand_length > 0)
        stdout.printf ("%s", expand_string (" ", expand_length));
      if (new_line)
        stdout.printf ("\n");
      else
        stdout.printf ("\r");
      stdout.flush ();
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

    public void new_track (string name, int position, int size) {
      message ("Now playing (%u/%u): %s".printf (position, size, name), true);
    }

    public void update_position (int64 position, int64 duration) {
      double pro;
      if (duration > 0)
        pro = ((double)position / (double)duration);
      else {
        pro = 0;
        duration = 0;
      }
      message (" %s %s : %s ".printf (progress_bar (pro), time_to_string (position), time_to_string (duration)), false);
    }

    public void state_paused () {
      message ("=== PAUSED ===", false);
    }

    public void error (string err) {
      message ("%s".printf (err), true);
    }

    public void buffering (int percentage) {
      message ("Buffering : %d %%".printf (percentage), false);
      stdout.flush ();
    }
  }
}
