using GLib;
using Gst;

namespace Galactica {
  public class Object : GLib.Object {
    DebugCategory debug_cat = null;

    public void init_debug (string name, uint color=0, string? description=null) {
      if (description == null) {
        debug_cat.init (name, color, name + " debugging");
      } else {
        debug_cat.init (name, color, description);
      }
    }

    public void debug (string text, string method = GLib.Log.METHOD) {
      Gst.debug_log (debug_cat, Gst.DebugLevel.DEBUG, "", method, 0, this, text);
    }
  }
}
