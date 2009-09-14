using Galactica;
using Gee;

int no_tracks_signal_counter;
int end_of_playlist_signal_counter;
ArrayList<string> new_track_strings;
ArrayList<int> new_position;
ArrayList<int> new_size;
Galactica.Playlist playlist;

public void set_up () {
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

public void tear_down () {
  playlist = null;
}

public void async_spin (uint count) {
  var loop = new MainLoop (null, false);
  var context = loop.get_context ();
  while (count > 0) {
    context.iteration (false);
    count--;
  }
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

void new_size_cb (Galactica.Playlist list, int size) {
  assert (list == playlist);
  new_size.add (size);
}

/* our real test cases */
void test_tracks_add () {
  set_up ();
  assert (playlist.size == 0);

  playlist.add_track (new CustomPipeline ("fakesrc ! fakesink"));
  assert (new_size.size == 1);
  playlist.add_track (new CustomPipeline ("fakesrc ! fakesink"));
  assert (new_size.size == 2);
  playlist.add_track (new CustomPipeline ("fakesrc ! fakesink"));
  assert (new_size.size == 3);

  assert (playlist.size == 3);
  assert (end_of_playlist_signal_counter == 0);
  assert (new_track_strings.size == 0);
}

void test_endOfPlaylist () {
  set_up ();
  playlist.play_next ();

  assert (end_of_playlist_signal_counter == 1);
}

void test_tracks_no () {
  set_up ();
  playlist.play_next ();

  assert (new_position.size == 0);
  assert (no_tracks_signal_counter == 1);
  assert (end_of_playlist_signal_counter == 1);
  assert (new_track_strings.size == 0);
}

void test_playSingle () {
  set_up ();
  playlist.add_track (new CustomPipeline ("audiotestsrc freq=300 ! fakesink"));
  playlist.play_next ();
  assert (new_track_strings.size == 1);
  assert (new_track_strings.get(0) == "audiotestsrc freq=300 ! fakesink");
  Thread.usleep (100000);
  playlist.play_next ();
  assert (new_track_strings.size == 1);
  assert (new_track_strings.get(0) == "audiotestsrc freq=300 ! fakesink");
  assert (no_tracks_signal_counter == 0);
  assert (end_of_playlist_signal_counter == 1);
  playlist.stop ();
}

void test_playMore () {
  set_up ();
  playlist.add_track (new CustomPipeline ("audiotestsrc freq=300 ! fakesink"));
  playlist.add_track (new CustomPipeline ("audiotestsrc freq=400 ! fakesink"));
  playlist.add_track (new CustomPipeline ("audiotestsrc freq=500 ! fakesink"));
  playlist.add_track (new CustomPipeline ("audiotestsrc freq=600 ! fakesink"));

  for (int i = 0; i < 4 ; i++) {
    playlist.play_next ();
    Thread.usleep (100000);
    assert (new_position.size == (i+1));
    assert (new_position.get (i) == i + 1);
    assert (end_of_playlist_signal_counter == 0);
    assert (new_track_strings.size == (i + 1));
  }
  playlist.play_next ();
  assert (no_tracks_signal_counter == 0);
  assert (end_of_playlist_signal_counter == 1);
  playlist.stop ();

  assert (new_track_strings.size == 4);
  assert (new_track_strings.get (0) == "audiotestsrc freq=300 ! fakesink");
  assert (new_track_strings.get (1) == "audiotestsrc freq=400 ! fakesink");
  assert (new_track_strings.get (2) == "audiotestsrc freq=500 ! fakesink");
  assert (new_track_strings.get (3) == "audiotestsrc freq=600 ! fakesink");
}

void test_removeCurrent () {
  set_up ();
  playlist.add_track (new CustomPipeline ("audiotestsrc freq=300 ! fakesink"));
  playlist.add_track (new CustomPipeline ("audiotestsrc freq=400 ! fakesink"));

  playlist.play_next ();

  /* remove the first track */
  playlist.remove_current_track ();

  assert (new_track_strings.size == 1);
  assert (new_size.size == 3);
  assert (new_size.get (0) == 1);
  assert (new_size.get (1) == 2);
  assert (new_size.get (2) == 1);

  /* remove current track while there is no track playing */
  playlist.remove_current_track ();

  assert (new_track_strings.size == 1);
  assert (new_size.size == 3);
  assert (end_of_playlist_signal_counter == 0);

  /* remove the last track */
  playlist.play_next ();
  playlist.remove_current_track ();

  assert (new_track_strings.size == 2);
  assert (new_size.size == 4);
  assert (new_size.get (3) == 0);
}

void test_playPrev () {
  set_up ();
  playlist.add_track (new CustomPipeline ("audiotestsrc freq=300 ! fakesink"));
  playlist.add_track (new CustomPipeline ("audiotestsrc freq=400 ! fakesink"));

  playlist.play_next ();
  assert (new_position.size == 1);
  assert (new_position.get (0) == 1);

  playlist.play_prev ();
  assert (new_position.size == 1);
  assert (new_position.get (0) == 1);

  playlist.play_next ();
  playlist.play_prev ();
  assert (new_position.size == 3);
  assert (new_position.get (2) == 1);
}

void test_repeat () {
  set_up ();
  var track_1 = new CustomPipeline ("fakesrc ! fakesink");
  var track_2 = new CustomPipeline ("fakesrc ! fakesink");

  playlist.add_track (track_1);
  playlist.add_track (track_2);

  playlist.repeat = true;

  playlist.play_next (); /* play the first track */
  playlist.play_next (); /* play the second track */
  playlist.play_next (); /* play the first track again */

  assert (new_position.size == 3);
  assert (new_position.get (0) == 1);
  assert (new_position.get (1) == 2);
  assert (new_position.get (2) == 1);
  assert (end_of_playlist_signal_counter == 0);
}

void test_random () {
  set_up ();
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

  assert (shuffled_count > 12);
}

void test_endOfPlaylist2 () {
  set_up ();
  playlist.add_track (new CustomPipeline ("fakesrc num-buffers=100 ! fakesink"));

  playlist.auto_next = true;

  playlist.play_next ();

  do {
    async_spin (1);
  } while (end_of_playlist_signal_counter == 0);
  assert (end_of_playlist_signal_counter == 1);
}

void test_error () {
  set_up ();
  playlist.add_track (new CustomPipeline ("fakesrc num-buffers=10 ! fakesink"));
  playlist.add_track (new CustomPipeline ("playbin uri=file:///tmp/non_existing_file.avi"));
  playlist.add_track (new CustomPipeline ("fakesrc num-buffers=10 ! fakesink"));

  playlist.auto_next = true;
  playlist.auto_error = true;

  playlist.play_next ();

  do {
    /*Thread.usleep (100000);*/
    async_spin (1);
  } while (end_of_playlist_signal_counter == 0);
  assert (end_of_playlist_signal_counter > 0);
  
  assert (new_position.size == 3);
  assert (new_position.get (0) == 1);
  assert (new_position.get (1) == 2);
  assert (new_position.get (2) == 2);
}

static void main (string[] args) {
  Gst.init (ref args);
  Test.init (ref args);
  Test.add_func ("/Galactica/Playlist/Tracks/Add", test_tracks_add);
  Test.add_func ("/Galactica/Playlist/EndOfPlaylist", test_endOfPlaylist);
  Test.add_func ("/Galactica/Playlist/Tracks/No", test_tracks_no);
  Test.add_func ("/Galactica/Playlist/PlaySingle", test_playSingle);
  Test.add_func ("/Galactica/Playlist/PlayMore", test_playMore);
  Test.add_func ("/Galactica/Playlist/RemoveCurrent", test_removeCurrent);
  Test.add_func ("/Galactica/Playlist/PlayPrev", test_playPrev);
  Test.add_func ("/Galactica/Playlist/Repeat", test_repeat);
  Test.add_func ("/Galactica/Playlist/Random", test_random);
  Test.add_func ("/Galactica/Playlist/EndOfPlaylist2", test_endOfPlaylist2);
  Test.add_func ("/Galactica/Playlist/Error", test_error);
  Test.run ();
}
