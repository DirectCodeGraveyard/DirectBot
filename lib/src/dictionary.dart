part of directbot;

void register_dictionary_commands() {
  bot.command("define").listen((CommandEvent event) {
    if (event.args.length == 0) {
      event.reply("> Usage: define <word>");
      return;
    }
    var word = event.args.join(" ");
    http.get("http://api.urbandictionary.com/v0/define?term=${Uri.encodeComponent(word)}").then((http.Response resp) {
      var data = JSON.decode(resp.body);
      if (data["list"].length == 0) {
        event.reply("> No Definition Found");
      } else {
        event.reply("> ${data["list"].first["word"]}: ${data["list"].first["definition"]}");
      }
    });
  });
}