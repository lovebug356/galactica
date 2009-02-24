using Galactica;
using Core;

public class Test.Playbin : Trial.Suite {
  public override void initialize () {
    name = "Galactica.Track.Playbin";
    add_test_case ("Playbin.to_string", test_to_string);
    add_test_case ("Playbin.display_name", test_display_name);
  }

  void test_to_string () {
    var p = new Playbin1 ("uri");
    assert_true (p.to_string () == "uri");
    var p2 = new Playbin2 ("uri_2");
    assert_true (p2.to_string () == "uri_2");
  }

  void test_display_name () {
    var p = new Playbin1 ("file:///tmp/music.mp3");

    assert_true (p.display_name () == "music.mp3");
  }

  public static int main (string[] args) {
    var suite = new Test.Playbin ();
    return suite.run ();
  }
}
