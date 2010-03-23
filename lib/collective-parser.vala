namespace Collective {
  public class Parser : GLib.Object {
    Item temp_item;
    bool title_text;

    public signal void new_item (Item item);

    construct {
      temp_item = null;
    }

    public void parse (string data, ssize_t length) throws MarkupError {
      MarkupParser parser = {open_tag, close_tag, process_text,
          null, null};
      var context = new MarkupParseContext (parser,
          MarkupParseFlags.TREAT_CDATA_AS_TEXT, this, null);
      context.parse (data, length);
      context.end_parse ();
    }

    void open_tag (MarkupParseContext ctx,
        string elem,
        string[] attribute_names,
        string[] attribute_values) throws MarkupError {
      if (elem == "item") {
        temp_item = new Item ();
      }
      if (elem == "title") {
        title_text = true;
      }
      if (elem == "enclosure") {
        for (int i=0;i<attribute_names.length ;i++) {
          if (attribute_names[i] == "url") {
            if (temp_item != null) {
              temp_item.url = attribute_values[i];
              break;
            }
          }
        }
      }
    }

    void close_tag (MarkupParseContext ctx,
        string elem) throws MarkupError {
      if (elem == "item") {
        new_item (temp_item);
        temp_item = null;
      }
      if (elem == "title") {
        title_text = false;
      }
    }

    void process_text (MarkupParseContext ctx,
        string text,
        size_t text_len) throws MarkupError {
      if (title_text && temp_item != null) {
        temp_item.title = text;
      }
    }
  }
}
