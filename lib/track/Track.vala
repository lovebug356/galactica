using Gst;

namespace Galactica {
  public abstract class Track : Galactica.Object {

    public bool disable_sync {get;set;default=false;}
    public bool disable_qos {get;set;default=false;}
    protected Gst.Element element = null;

    public virtual void prepare_element () {
      if (element != null) {
        if (disable_qos) {
        }
        if (disable_sync) {
        }
      }
    }

    public virtual Gst.Element get_element (Track? prev_track) {
      if (element == null)
        prepare_element ();

      return element;
    }

    public virtual string to_string () {
      return "Unknown";
    }

    public virtual string display_name () {
      return to_string ();
    }
  }
}
