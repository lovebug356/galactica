using Galactica;

namespace Galactica {
  public abstract class Playbin : Track {

    protected string playbin_name;
    protected string uri;

    public bool disable_audio {get;set;default=false;}
    public bool disable_video {get;set;default=false;}

    public Playbin (string uri) {
      this.uri = uri;
    }

    public override void prepare_element () {
      element = Gst.ElementFactory.make (playbin_name, null);
      element.set ("uri", this.uri);

      if (disable_audio) {
        element.set ("audio-sink", Gst.ElementFactory.make ("fakesink", null));
      }

      if (disable_video) {
        element.set ("video-sink", Gst.ElementFactory.make ("fakesink", null));
      }

      base.prepare_element ();
    }

    public override string to_string () {
      return Filename.display_name (uri);
    }
  }
}
