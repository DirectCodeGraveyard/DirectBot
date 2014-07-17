part of directbot;

var googleAPIKey = "AIzaSyBNTRakVvRuGHn6AVIhPXE_B3foJDOxmBU";

void register_google_commands() {
  command("google", (event) {
    if (event.args.length >= 1) {
      String query = event.args.join(" ");
      google(query).then((resp) {
        List results = resp["responseData"]["results"];
        if (results.length == 0) {
          event.reply("> No Results Found!");
        } else {
          var result = results[0];
          event.reply("${part_prefix("Google")} ${result["titleNoFormatting"]} | ${result["unescapedUrl"]}");
        }
        Achievements.give(event.from, "Google User");
      });
    } else {
      event.reply("> Usage: google <query>");
    }
  });

  command("shorten", (event) {
    if (event.args.length < 1) {
      event.reply("> Usage: shorten <url>");
    } else {
      google_shorten(event.args.join(" ")).then((shortened) {
        event.reply("${part_prefix("URL Shortener")} ${shortened}");
      });
    }
  });
}

Future<Map<String, Object>> google(String query) {
  return http.get("http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=${Uri.encodeComponent(query)}").then((http.Response response) {
    return new Future.value(JSON.decoder.convert(response.body));
  });
}

Future<String> google_shorten(String longUrl) {
  var input = JSON.encode({
    "longUrl": longUrl
  });
  return http.post("https://www.googleapis.com/urlshortener/v1/url?key=${googleAPIKey}", headers: {
    "Content-Type": ContentType.JSON.toString()
  }, body: input).then((http.Response response) {
    Map<String, Object> resp = JSON.decoder.convert(response.body);
    return new Future.value(resp["id"]);
  });
}
