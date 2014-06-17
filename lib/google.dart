part of directbot;

void google(CommandEvent event) {
    if (event.args.length >= 1) {
        String query = Uri.encodeComponent(event.args.join(" "));
        new HttpClient().getUrl('http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=' + query).then((HttpClientRequest req) {
            return req.close();
        }).then((HttpClientResponse response) {
            return response.transform(UTF8.decoder);
        }).then((content) {
            var resp = JSON.decode(content);
            var results = resp["responseData"]["results"];
            if  (results.length == 0) {
                event.reply("> No Results Found!");
            } else {
                var result = results[0];
                event.reply("> ${result["titleNoFormatting"]} | ${result["url"]}");
            }
        });
    } else {
        event.reply("> Usage: google <query>");
    }
}