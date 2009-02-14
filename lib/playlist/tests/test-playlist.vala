using Galactica;
using Core;
using Core.Container;

class Test.Playlist : Trial.Suite {

  int no_tracks_signal_counter;
  int end_of_playlist_signal_counter;
  ArrayList<string> new_track_strings;
  ArrayList<int> new_position;
  ArrayList<int> new_size;
  Galactica.Playlist playlist;

  protected override void initialize () {
    name = "Galactica.Playlist";
    add_test_case ("add tracks", test_add_tracks);
    add_test_case ("no tracks", test_no_tracks);
    add_test_case ("play single", test_play_single);
    add_test_case ("play more", test_play_more);
    add_test_case ("remove currect", test_remove_current);
    add_test_case ("play_prev", test_play_prev);
    add_test_case ("random_sort", test_random);
    add_test_case ("repeat", test_repeat);
  }

  protected override void set_up () {
    playlist = new Galactica.Playlist ();
    playlist.no_tracks += no_tracks_cb;
    playlist.end_of_playlist += end_of_playlist_cb;
    playlist.new_track += new_track_cb;
    playlist.new_size += new_size_cb;
    /* clear the prev state */
    no_tracks_signal_counter = 0;
    end_of_playlist_signal_counter = 0;
    new_track_strings = new ArrayList<string> ();
    new_size = new ArrayList<int> ();
    new_position = new ArrayList<int> ();
  }

  protected override void tear_down () {
    playlist = null;
  }

  /* call back functions */
  void no_tracks_cb () {
    no_tracks_signal_counter++;
  }

  void end_of_playlist_cb () {
    end_of_playlist_signal_counter++;
  }

  void new_track_cb (Galactica.Playlist list, Galactica.Track track, int position) {
    assert (list == playlist);

    new_track_strings.add (track.to_string ());
    new_position.add (position);
  }

  void new_size_cb (Galactica.Playlist list, int new_size) {
    assert (list == playlist);

    this.new_size.add (new_size);
  }

  /* our real test cases */
  void test_add_tracks () {
    assert_true (playlist.size == 0);

    playlist.add_track (new CustomPipeline ("fakesrc ! fakesink"));
    assert_true (new_size.size == 1);
    playlist.add_track (new CustomPipeline ("fakesrc ! fakesink"));
    assert_true (new_size.size == 2);
    playlist.add_track (new CustomPipeline ("fakesrc ! fakesink"));
    assert_true (new_size.size == 3);

    assert_true (playlist.size == 3);
    assert_true (end_of_playlist_signal_counter == 0);
    assert_true (new_track_strings.size == 0);
  }

  void test_no_tracks () {
    playlist.play_next ();

    assert_true (new_position.size == 0);
    assert_true (no_tracks_signal_counter == 1);
    assert_true (end_of_playlist_signal_counter == 1);
    assert_true (new_track_strings.size == 0);
  }

  void test_play_single () {
    playlist.add_track (new CustomPipeline ("audiotestsrc freq=300 ! fakesink"));
    playlist.play_next ();
    assert_true (new_track_strings.size == 1);
    assert_true (new_track_strings.get(0) == "audiotestsrc freq=300 ! fakesink");
    Thread.usleep (100000);
    playlist.play_next ();
    assert_true (new_track_strings.size == 1);
    assert_true (new_track_strings.get(0) == "audiotestsrc freq=300 ! fakesink");
    assert_true (no_tracks_signal_counter == 0);
    assert_true (end_of_playlist_signal_counter == 1);
    playlist.stop ();
  }

  void test_play_more () {
    playlist.add_track (new CustomPipeline ("audiotestsrc freq=300 ! fakesink"));
    playlist.add_track (new CustomPipeline ("audiotestsrc freq=400 ! fakesink"));
    playlist.add_track (new CustomPipeline ("audiotestsrc freq=500 ! fakesink"));
    playlist.add_track (new CustomPipeline ("audiotestsrc freq=600 ! fakesink"));

    for (int i = 0; i < 4 ; i++) {
      playlist.play_next ();
      Thread.usleep (100000);
      assert_true (new_position.size == (i+1));
      assert_true (new_position.get (i) == i + 1);
      assert_true (end_of_playlist_signal_counter == 0);
      assert_true (new_track_strings.size == (i + 1));
    }
    playlist.play_next ();
    assert_true (no_tracks_signal_counter == 0);
    assert_true (end_of_playlist_signal_counter == 1);
    playlist.stop ();

    assert_true (new_track_strings.size == 4);
    assert_true (new_track_strings.get (0) == "audiotestsrc freq=300 ! fakesink");
    assert_true (new_track_strings.get (1) == "audiotestsrc freq=400 ! fakesink");
    assert_true (new_track_strings.get (2) == "audiotestsrc freq=500 ! fakesink");
    assert_true (new_track_strings.get (3) == "audiotestsrc freq=600 ! fakesink");
  }

  void test_remove_current () {
    playlist.add_track (new CustomPipeline ("audiotestsrc freq=300 ! fakesink"));
    playlist.add_track (new CustomPipeline ("audiotestsrc freq=400 ! fakesink"));

    playlist.play_next ();

    /* remove the first track */
    playlist.remove_current_track ();

    assert_true (new_track_strings.size == 1);
    assert_true (new_size.size == 3);
    assert_true (new_size.get (0) == 1);
    assert_true (new_size.get (1) == 2);
    assert_true (new_size.get (2) == 1);

    /* remove current track while there is no track playing */
    playlist.remove_current_track ();

    assert_true (new_track_strings.size == 1);
    assert_true (new_size.size == 3);
    assert_true (end_of_playlist_signal_counter == 0);

    /* remove the last track */
    playlist.play_next ();
    playlist.remove_current_track ();

    assert_true (new_track_strings.size == 2);
    assert_true (new_size.size == 4);
    assert_true (new_size.get (3) == 0);
  }

  void test_play_prev () {
    playlist.add_track (new CustomPipeline ("audiotestsrc freq=300 ! fakesink"));
    playlist.add_track (new CustomPipeline ("audiotestsrc freq=400 ! fakesink"));

    playlist.play_next ();
    assert_true (new_position.size == 1);
    assert_true (new_position.get (0) == 1);

    playlist.play_prev ();
    assert_true (new_position.size == 1);
    assert_true (new_position.get (0) == 1);

    playlist.play_next ();
    playlist.play_prev ();
    assert_true (new_position.size == 3);
    assert_true (new_position.get (2) == 1);
  }

  void test_repeat () {
    var track_1 = new CustomPipeline ("fakesrc ! fakesink");
    var track_2 = new CustomPipeline ("fakesrc ! fakesink");

    playlist.add_track (track_1);
    playlist.add_track (track_2);

    playlist.repeat = true;

    playlist.play_next (); /* play the first track */
    playlist.play_next (); /* play the second track */
    playlist.play_next (); /* play the first track again */

    assert_true (new_position.size == 3);
    assert_true (new_position.get (0) == 1);
    assert_true (new_position.get (1) == 2);
    assert_true (new_position.get (2) == 1);
    assert_true (end_of_playlist_signal_counter == 0);
  }

  void test_random () {
    var track_1 = new CustomPipeline ("fakesrc ! fakesink");
    var track_2 = new CustomPipeline ("fakesrc ! fakesink");
    var track_3 = new CustomPipeline ("fakesrc ! fakesink");
    var track_4 = new CustomPipeline ("fakesrc ! fakesink");

    playlist.shuffle = true;

    playlist.add_track (track_1);
    playlist.add_track (track_2);
    playlist.add_track (track_3);
    playlist.add_track (track_4);

    int counter = 0;
    int shuffled_count = 0;

    while (counter++ < 5) {
      playlist.play_next ();
      if (playlist.current_track != track_1) shuffled_count++;
      playlist.play_next ();
      if (playlist.current_track != track_2) shuffled_count++;
      playlist.play_next ();
      if (playlist.current_track != track_3) shuffled_count++;
      playlist.play_next ();
      if (playlist.current_track != track_4) shuffled_count++;
    }

    assert_true (shuffled_count > 12);
  }
}

static int main (string[] args) {
  Gst.init (ref args);
  var suite = new Test.Playlist ();
  return suite.run ();
}
