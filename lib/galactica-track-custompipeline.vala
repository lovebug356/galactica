using Galactica;

namespace Galactica {
  public class CustomPipeline : Track {

    string element_string;

    public CustomPipeline (string element) {
      this.element_string = element;
    }

    public override void prepare_element () {
      element = Gst.parse_launch (element_string);

      base.prepare_element ();
    }

    public override string to_string () {
      return element_string;
    }
  }
}
