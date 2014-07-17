part of directbot;

void register_fun_commands() {
  command("who", (event) {

    if (event.args.length == 0) {
      event.reply("> Usage: who <question>");
      return;
    }

    var msg = event.args.join(" ").trim();
    if (msg.endsWith("?")) {
      msg = msg.substring(0, msg.length - 1);
    }
    switch (msg) {
      case "wants the d":
        event.reply("> she wants the d.");
        break;
      case "cares":
        event.reply("> http://www.youtube.com/watch?v=RFZrzg62Zj0");
        break;
      case "likes KitKats":
        event.reply("> kaendfinger");
        break;
      default:
        var url = "http://lmgtfy.com/?q=${Uri.encodeComponent("who " + msg)}";
        google_shorten(url).then((shortened) {
          event.reply("> ${shortened}");
        });
        break;
    }

    Achievements.give(event.from, "Fun Person");
  });
}
