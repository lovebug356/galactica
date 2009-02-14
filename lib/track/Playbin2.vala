using Galactica;

namespace Galactica {
  public class Playbin2 : Playbin {
    construct {
      init_debug ("playbin2");
      playbin_name = "playbin2";
    }

    public Playbin2 (string uri) {
      this.uri = uri;
    }
  }
}
