part of directbot;

class regex {
  static void handle(MessageEvent event) {
    if (event.message.startsWith("s/") && event.message.length > 3) {
      var msg = event.message;
      var begins = 2;
      var ends = msg.indexOf("/", begins + 1);
      var begin_replacement = ends + 1;
      var end_replacement = msg.endsWith("/") ? msg.length - 1 : msg.length;
      var expression = new String.fromCharCodes(msg.codeUnits.getRange(begins, ends));
      var replacement = new String.fromCharCodes(msg.codeUnits.getRange(begin_replacement, end_replacement));
      RegExp regex;
      try {
        regex = new RegExp(expression);
      } catch (e) {
        regex = new RegExp(r"^" + escapeRegex(expression) + r"$");
      }
      var replaced = msg.substring(msg.indexOf(expression), msg.lastIndexOf("/"));
      var events = buffer.get(event.channel.name);
      var scope = new List.from(events.getRange(0, events.length < 20 ? events.length : 20));
      for (event in scope.reversed) {
        if (regex.hasMatch(event.message)) {
          event.reply(event.from + ": " + event.message.replaceAll(regex, replacement));
          return;
        }
      }
      event.reply("> ERROR: No Match Found for expression '${expression}'");
    }
  }
}