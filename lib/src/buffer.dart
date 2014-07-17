part of directbot;

class Buffer {

  static Map<String, Buffer> buffers = new Map<String, Buffer>();
  
  List<MessageEvent> messages = [];
  final int _limit = 30;
  int _tracker = 0;

  void _handle(MessageEvent event) {
    if (event.message.startsWith("s/"))
      return;
    
    if (_tracker > _limit - 1)
      _tracker = 0;
    messages[_tracker] = event;
    _tracker++;
  }
  
  static void handle(MessageEvent event) {
    if (event.isPrivate) {
      return;
    }
    
    var data = DataStore.data;
    
    if (data["message_count"] == null) {
      data["message_count"] = {};
    }
    
    if (data["character_count"] == null) {
      data["character_count"] = {};
    }
    
    var counts = data["message_count"];
    var chars = data["character_count"];
    
    var id = "${get_store_name(event.from)}${event.target}";
    
    if (!counts.containsKey(id)) {
      counts[id] = 1;
    } else {
      counts[id] = counts[id] + 1;
    }
    
    var count = counts[id];
    var chan_count = counts[event.target];
    
    if (chan_count == null) {
      chan_count = 0;
    }
    
    chan_count++;
    
    if (!counts.containsKey(id)) {
      counts[id] = 1;
    } else {
      counts[id] = counts[id] + 1;
    }
    
    var char_count = counts[id];
    var chan_char_count = counts[event.target];
    
    if (char_count == null) {
      char_count = 0;
    }
    
    char_count += event.message.length;
    
    if (!chars.containsKey(id)) {
      chars[id] = 1;
    } else {
      chars[id] = chars[id] + event.message.length;
    }
    
    if (chan_count % 10 == 0) {
      Points.add_points(event.target, 1, null, false);
    }
    
    if (chan_count == 500) {
      Points.add_points(event.target, 50);
    }
    
    
    if (count % 5 == 0) {
      Points.add_points(event.from, 1, null, false);
    }
    
    counts[event.target] = chan_count;
    chars[event.target] = char_count;
    
    var buf = buffers[event.target];
    if (buf == null) {
      buf = new Buffer();
      buffers[event.target] = buf;
      for (int i = 0; i < 30; i++)
        buf.messages.add(null);
    }
    
    buf._handle(event);
  }

  static List<MessageEvent> get(String name) {
    var buf = buffers[name];
    if (buf == null)
      return <MessageEvent>[];
    
    var list = buf.messages;
    var tracker = buf._tracker;
    
    List<MessageEvent> newList = [];
    
    for (int i = buf._tracker - 1; i >= 0; i--) {
      if (list[i] == null)
        break;
      newList.add(list[i]);
    }
    
    for (int i = buf._limit - 1; i >= buf._tracker; i--) {
      if (list[i] == null)
        break;
      newList.add(list[i]);
    }
    
    return newList;
  }
  
  static void clear(String name) {
    var buf = buffers[name];
    if (buf != null)
      buf.messages.clear();
  }
}
