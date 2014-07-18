part of directbot;

class Buffer {

  static Map<String, Buffer> buffers = new Map<String, Buffer>();

  List<MessageEvent> messages = [];
  final int _limit = 30;
  int _tracker = 0;

  void _handle(MessageEvent event) {
    if (event.message.startsWith("s/")) return;

    if (_tracker > _limit - 1) _tracker = 0;
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

    var messages = data["message_count"];
    var chars = data["character_count"];
    
    var channel = event.target;
    
    var user_id = "${get_store_name(event.from)}${event.target}";
    
    // Messages Count (Channel)
    {
      var count = messages[channel];
      if (count == null) {
        count = 0;
      }
      count++;
      messages[channel] = count;
      
      if (count % 50 == 0) {
        Points.add_points(event.from, 1, null, false);
      }
    }
    
    // Messages Count (User)
    {
      var count = messages[user_id];
      if (count == null) {
        count = 0;
      }
      count++;
      messages[user_id] = count;
      
      if (count % 10 == 0) {
        Points.add_points(event.from, 1, null, false);
      }
    }
    
    // Character Count (Channel)
    {
      var count = chars[channel];
      if (count == null) {
        count = 0;
      }
      count += event.message.length;
      chars[channel] = count;
      
      if (count % 5000 == 0) {
        Points.add_points(event.from, 1, null, false);
      }
    }
    
    // Characters Count (User)
    {
      var count = chars[user_id];
      if (count == null) {
        count = 0;
      }
      count += event.message.length;
      chars[user_id] = count;
      
      if (count % 5000 == 0) {
        Points.add_points(event.from, 1, null, false);
      }
    }

    var buf = buffers[event.target];
    if (buf == null) {
      buf = new Buffer();
      buffers[event.target] = buf;
      for (int i = 0; i < 30; i++) buf.messages.add(null);
    }

    buf._handle(event);
  }

  static List<MessageEvent> get(String name) {
    var buf = buffers[name];
    if (buf == null) return <MessageEvent>[];

    var list = buf.messages;
    var tracker = buf._tracker;

    List<MessageEvent> newList = [];

    for (int i = buf._tracker - 1; i >= 0; i--) {
      if (list[i] == null) break;
      newList.add(list[i]);
    }

    for (int i = buf._limit - 1; i >= buf._tracker; i--) {
      if (list[i] == null) break;
      newList.add(list[i]);
    }

    return newList;
  }

  static void clear(String name) {
    var buf = buffers[name];
    if (buf != null) buf.messages.clear();
  }
}
