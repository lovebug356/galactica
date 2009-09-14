using Galactica;

void test_toString () {
  var p = new CustomPipeline ("fakesrc ! fakesink");
  assert (p.to_string () == "fakesrc ! fakesink");
}

public static void main (string[] args) {
  Gst.init (ref args);
  Test.init (ref args);
  Test.add_func ("/Galactica/Custom/ToString", test_toString);
  Test.run ();
}
