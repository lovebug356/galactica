using Gee;
using Collective;

namespace Collective {
  public class ItemList : Gee.ArrayList<Collective.Item> {
    public void dump () {
      print ("List: %d items\n", size);
      foreach (Item i in this) {
        print ("\ttitle: %s\n", i.title);
        print ("\turl: %s\n", i.url);
      }
    }
  }
}
