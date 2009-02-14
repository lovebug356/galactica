using Galactica;
using Core;

public class Test.Custom : Trial.Suite {
  public override void initialize () {
    name = "Galactica.Track.CustomPipeline";
    add_test_case ("CustomPipeline.to_string", test_to_string);
  }

  void test_to_string () {
    var p = new CustomPipeline ("fakesrc ! fakesink");
    assert_true (p.to_string () == "fakesrc ! fakesink");
  }

  public static int main (string[] args) {
    var suite = new Test.Custom ();
    return suite.run ();
  }
}
