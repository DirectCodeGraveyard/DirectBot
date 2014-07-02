part of directbot;

void register_fun_commands() {
  bot.command("who").listen((CommandEvent event) {
    var msg = event.args.join(" ");
    switch (msg) {
      case "is epic":
      case "is the best programmer":
        event.reply("> samrg472");
        break;
      case "wants the d":
        event.reply("> she wants the d.");
        break;
      case "cares":
        event.reply("> http://www.youtube.com/watch?v=RFZrzg62Zj0");
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
