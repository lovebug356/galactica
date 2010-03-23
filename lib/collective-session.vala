namespace Collective {
  public class Session : GLib.Object {
    static const string MUSIC_RSS = "http://8bitcollective.com/rss/music";

    Soup.Session session;

    construct {
      session = new Soup.SessionAsync ();
    }

    void session_cb (Soup.Session session, Soup.Message message) {
      var parser = new Collective.Parser ();
      parser.new_item.connect (new_item_cb);
      parser.parse ((string) message.response_body.data,
          (ssize_t) message.response_body.length);
    }

    public void music_rss () {
      var message = new Soup.Message ("GET", MUSIC_RSS);
      session.send_message (message);
      session_cb (session, message);
      // session.queue_message (message, session_cb);
    }

    public virtual void new_item_cb (Item item) {
    }
  }
}
