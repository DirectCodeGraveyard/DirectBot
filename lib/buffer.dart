part of directbot;

class buffer {

  static Multimap<String, MessageEvent> messages = new Multimap<String, MessageEvent>();

  static void handle(MessageEvent event) {
    if (messages[event.target].length >= 30) {
      messages.removeAll(event.target);
    }
    messages.add(event.target, event);
  }

  static List<MessageEvent> get(String name) {
    return messages[name];
  }
}
