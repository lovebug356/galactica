using GLib;
using Gee;

namespace Galactica {
  public class PlaylistBuilder : Galactica.Object {
    ArrayList<string> uris;

    public bool disable_audio {get;set;default=false;}
    public bool disable_video {get;set;default=false;}
    public bool custom_pipeline {get;set;default=false;}
    public bool playbin2 {get;set;default=false;}

    construct {
      uris = new ArrayList<string> ();
    }

    public void uri_add (string uri) {
      uris.add (uri);
    }

    string convert_to_uri (string uri) {
      if (Gst.uri_is_valid (uri))
        return uri;
      if (Path.is_absolute (uri))
        return Filename.to_uri (uri);
      else
        return Filename.to_uri (Path.build_filename (Environment.get_current_dir (), uri));
    }

    public void new_folder_track (string uri) {
      Dir folder;
      try {
        folder = Dir.open (uri);
      } catch (Error err) {
        folder = null;
      }
      if (folder != null) {
        weak string item = folder.read_name ();
        while (item != null) {
          uris.add (Path.build_filename (uri, item));
          item = folder.read_name ();
        }
      }
    }

    public void new_m3u_file (string uri) {
      string[] m3u_item;
      string content;

      string filename;
      string dirname;

      if (Path.is_absolute (uri))
        filename = uri;
      else
        filename = Path.build_filename (Environment.get_current_dir (), uri);

      dirname = Path.get_dirname (filename);

      try {
        FileUtils.get_contents (uri, out content);
      } catch (Error err) {
        return;
      }

      m3u_item = content.split ("\n");

      foreach (string item in m3u_item) {
        if (item != "" && !item.has_prefix ("#")) {
          if (Gst.uri_is_valid (item) || Path.is_absolute (item))
            uris.add (item);
          else
            uris.add (Path.build_filename (dirname, item));
        }
      }
    }

    public Galactica.Track? new_playbin_track (string uri) {
      if (FileUtils.test (uri, FileTest.EXISTS) && FileUtils.test (uri, FileTest.IS_DIR)) {
        new_folder_track (uri);
      } else if (uri.has_suffix ("m3u")) {
        new_m3u_file (uri);
      } else {
        Galactica.Track track = null;
        if (playbin2) {
          track = new Galactica.Playbin2 (convert_to_uri (uri));
        } else {
          track = new Galactica.Playbin1 (convert_to_uri (uri));
        }
        if (track != null) {
          var playbin = track as Galactica.Playbin;
          playbin.disable_audio = disable_audio;
          playbin.disable_video = disable_video;
          return track;
        }
      }
      return null;
    }

    public Galactica.Playlist get_playlist () {
      var playlist = new Playlist ();
      while (uris.size > 0) {
        Galactica.Track track = null;
        string uri = uris.get (0);
        uris.remove_at (0);
        if (custom_pipeline) {
          track = new Galactica.CustomPipeline (uri);
        } else {
          track = new_playbin_track (uri);
        }
        if (track != null) {
          playlist.add_track (track);
        }
      }
      return playlist;
    }
  }
}
