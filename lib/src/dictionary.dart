part of directbot;

void register_dictionary_commands() {
  command("urban", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: urban <word>");
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

  command("define", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: define <word>");
      return;
    }
    var word = event.args.join(" ");
    http.get("http://api.wordnik.com/v4/word.json/${Uri.encodeComponent(word)}/definitions?limit=50&includeRelated=true&useCanonical=true&includeTags=false&api_key=50b6a4b7956e5934de00d0e43c10b78e7a67da3eef3e50662").then((http.Response resp) {
      var data = JSON.decode(resp.body);
      if (data.length == 0) {
        event.reply("> No Definition Found");
      } else {
        event.reply("> ${data.first["word"]}: ${data.first["text"]}");
      }
    });
  });
}
