using Galactica;

namespace Galactica {
  public class Playbin1 : Playbin {
    construct {
      init_debug ("playbin");
      playbin_name = "playbin";
    }

    public Playbin1 (string uri) {
      this.uri = uri;
    }
  }
}
