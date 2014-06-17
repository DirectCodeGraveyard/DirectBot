part of directbot;

var googleAPIKey = "AIzaSyCn3fRjsEMyw837JKcgnqJZ1J8YAxFUB0c";

void google(CommandEvent event) {
    if (event.args.length >= 1) {
        String query = Uri.encodeComponent(event.args.join(" "));
        new HttpClient().getUrl(Uri.parse('http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=' + query)).then((HttpClientRequest req) {
            return req.close();
        }).then((HttpClientResponse response) {
            response.transform(UTF8.decoder).join("").then((content) {
                var resp = JSON.decoder.convert(content);
                List results = resp["responseData"]["results"];
                if  (results.length == 0) {
                    event.reply("> No Results Found!");
                } else {
                    var result = results[0];
                    event.reply("> ${result["titleNoFormatting"]} | ${result["unescapedUrl"]}");
                }
            });
        });
    } else {
        event.reply("> Usage: google <query>");
    }
}

Future<String> shorten(String longUrl) {
    var input = JSON.encode({
        "longUrl": longUrl
    });
    return new HttpClient().postUrl(Uri.parse("https://www.googleapis.com/urlshortener/v1/url?key=${googleAPIKey}")).then((HttpClientRequest request) {
        request.headers.contentType = ContentType.JSON;
        request.write(input);
        return request.close();
    }).then((HttpClientResponse response) {
        return response.transform(UTF8.decoder).join("");
    }).then((content) {
        Map<String, Object> resp = JSON.decoder.convert(content);
        return new Future.value(resp["id"]);
    });
}