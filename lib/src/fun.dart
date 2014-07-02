part of directbot;

void register_fun_commands() {
  bot.command("who").listen((CommandEvent event) {
    var msg = event.args.join(" ").trim();
    if (msg.endsWith("?")) {
      msg = msg.substring(0, msg.length - 1);
    }
    switch (msg) {
      case "is epic":
      case "is the best coder":
      case "writes the best code":
      case "makes the best code":
      case "is the best programmer":
        event.reply("> samrg472");
        break;
      case "is the worst code":
      case "is the worst coder":
      case "is the worse programmer":
        event.reply("> Clank");
        break;
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
        shorten(url).then((shortened) {
          event.reply("> ${shortened}");
        });
        break;
    }
  });
}
