part of directbot;

class regex {
  static void handle(MessageEvent event) {
    if (event.message.startsWith("s/") && event.message.length > 3) {
      var msg = event.message.substring(2); // skip "s/"
      var first = true;
      if (msg.endsWith("/"))
        msg = msg.substring(0, msg.length - 1);
      else if (msg.endsWith("/g")) {
        msg = msg.substring(0, msg.length - 2);
        first = false;
      }
      
      var index = msg.indexOf("/");
      var expr = msg.substring(0, index);
      var replacement = msg.substring(index + 1, msg.length);
      
      RegExp regex = new RegExp(escapeRegex(expr));

      var events = Buffer.get(event.channel.name);
      for (event in events) {
        if (regex.hasMatch(event.message)) {
          var dat_msg = event.message;
          var newmsg = first ? dat_msg.replaceFirst(regex, replacement) : dat_msg.replaceAll(regex, replacement);
          var e = new MessageEvent(event.client, event.from, event.target, newmsg);
          event.reply(event.from + ": " + e.message);
          Buffer.handle(e);
          return;
        }
      }
      event.reply("> ERROR: No Match Found for expression '${expr}'");
    }
  }
}