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
    if (event.isPrivate())
      return;
    
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
