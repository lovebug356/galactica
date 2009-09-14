using Galactica;

void test_toString () {
  var p = new Playbin1 ("uri");
  assert (p.to_string () == "uri");
  var p2 = new Playbin2 ("uri_2");
  assert (p2.to_string () == "uri_2");
}

void test_displayName () {
  var p = new Playbin1 ("file:///tmp/music.mp3");
  assert (p.display_name () == "music.mp3");
}

public static void main (string[] args) {
  Gst.init (ref args);
  Test.init (ref args);
  Test.add_func ("/Galactica/Playbin/ToString", test_toString);
  Test.add_func ("/Galactica/Playbin/DisplayName", test_displayName);
  Test.run ();
}
