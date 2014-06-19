part of directbot;

var googleAPIKey = "AIzaSyCn3fRjsEMyw837JKcgnqJZ1J8YAxFUB0c";

void google_cmd(CommandEvent event) {
  if (event.args.length >= 1) {
    String query = event.args.join(" ");
    google(query).then((resp) {
      List results = resp["responseData"]["results"];
      if (results.length == 0) {
        event.reply("> No Results Found!");
      } else {
        var result = results[0];
        event.reply("> ${result["titleNoFormatting"]} | ${result["unescapedUrl"]}");
      }
    });
  } else {
    event.reply("> Usage: google <query>");
  }
}

Future<Map<String, Object>> google(String query) {
  return http.get("http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=${Uri.encodeComponent(query)}").then((http.Response response) {
    return new Future.value(JSON.decoder.convert(response.body));
  });
}

Future<String> shorten(String longUrl) {
  var input = JSON.encode({
    "longUrl": longUrl
  });
  return http.post(
      "https://www.googleapis.com/urlshortener/v1/url?key=${googleAPIKey}",
      headers: {
        "Content-Type": ContentType.JSON.toString()
      },
      body: input
  ).then((http.Response response) {
    Map<String, Object> resp = JSON.decoder.convert(response.body);
    return new Future.value(resp["id"]);
  });
}
