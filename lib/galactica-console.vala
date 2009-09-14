using GLib;

namespace Galactica {
  public class Console : GLib.Object {
    public bool running;

    [CCode (cname="read_key")]
    public extern static int read_key ();
    [CCode (cname="cons_set_raw")]
    public extern static void reset (int val);

    public signal void key_press (int code);

    construct {
      running = false;
    }

    public void stop () {
      running = false;
      reset (0);
    }

    public void start () {
      running = true;
      try {
        Thread.create (console_thread, false);
      } catch (ThreadError er) {
        warning ("Failed to startup the console thread");
      }
    }

    public void* console_thread () {
      while (running) {
        key_press (read_key ());
      }
      stdout.printf ("\n");
      return null;
    }
  }
}
