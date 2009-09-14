using Lua;
using Gee;

namespace Galactica.Lua {

  public delegate void QuitFunction ();

  static Playlist playlist;
  static LuaVM vm = null;
  static QuitFunction quit_function;

  public static void init (Playlist playlist, QuitFunction quit_function) {

    Galactica.Lua.playlist = playlist;
    Galactica.Lua.quit_function = quit_function;

    /* init the vm */
    vm = new LuaVM ();
    vm.open_libs ();

    /* register some functions */
    vm.register ("play_next", play_next);
    vm.register ("play_prev", play_prev);
    vm.register ("remove_current_track", remove_current_track);
    vm.register ("seek", seek);
    vm.register ("toggle_play_pause", toggle_play_pause);
    vm.register ("quit", quit);
    vm.register ("current_track", current_track);
    vm.register ("current_display_name", current_display_name);
    vm.register ("no_position_update", no_position_update);
  }

  static int no_position_update (LuaVM vm) {
    bool temp = vm.to_boolean (1);
    playlist.no_position_update = temp;
    return 0;
  }

  static int current_display_name (LuaVM vm) {
    vm.push_string (playlist.current_track.display_name ());
    return 1;
  }

  static int current_track (LuaVM vm) {
    vm.push_string (playlist.current_track.to_string ());
    return 1;
  }

  static int quit (LuaVM vm) {
    quit_function ();
    return 0;
  }

  static int toggle_play_pause (LuaVM vm) {
    playlist.toggle_play_pause ();
    return 0;
  }

  static int play_next (LuaVM vm) {
    playlist.play_next ();
    return 0;
  }

  static int play_prev (LuaVM vm) {
    playlist.play_prev ();
    return 0;
  }

  static int remove_current_track (LuaVM vm) {
    playlist.remove_current_track ();
    return 0;
  }

  static int seek (LuaVM vm) {
    bool positive = vm.to_boolean (1);
    int time = vm.to_integer (2) * (positive ? 1 : -1);
    playlist.seek (time);
    return 0;
  }

  public static void configuration_action (int keycode) {
    vm.get_global ("key_%u".printf (keycode));
    if (vm.is_function (-1)) {
      vm.pcall ();
    }
  }

  public static void load_configuration_file (string? filename) {
    ArrayList<string> configuration_files = new ArrayList<string> ();
    if (filename != null)
      configuration_files.add (filename);
    configuration_files.add (Path.build_filename ("share", "galactica.lua"));
    configuration_files.add (Path.build_filename (Environment.get_home_dir (), ".galactica.lua"));
    configuration_files.add (Path.build_filename (Environment.get_user_config_dir (), "galactica.lua"));
    configuration_files.add (Path.build_filename (Config.DATADIR, "galactica.lua"));
    configuration_files.add (Path.build_filename ("/usr/share", "galactica.lua"));

    foreach (string file in configuration_files) {
      if (FileUtils.test (file, FileTest.EXISTS)) {
        vm.load_file (file);
        vm.pcall ();
        return;
      }
    }
    stdout.printf ("WARNING: no configuration file found\n");
  }
}
