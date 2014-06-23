part of directbot;

class regex {
  static void handle(MessageEvent event) {
    if (event.message.startsWith("s/") && event.message.length > 3) {
      var msg = event.message.substring(2); // skip "s/"
      if (msg.endsWith("/"))
        msg = msg.substring(0, msg.length - 1);
      
      var index = msg.indexOf("/");
      var expr = msg.substring(0, index);
      var replacement = msg.substring(index + 1, msg.length);
      
      RegExp regex = new RegExp(escapeRegex(expr));

      var events = Buffer.get(event.channel.name);
      for (event in events) {
        if (regex.hasMatch(event.message)) {
          event.reply(event.from + ": " + event.message.replaceAll(regex, replacement));
          return;
        }
      }
      event.reply("> ERROR: No Match Found for expression '${expr}'");
    }
  }
}