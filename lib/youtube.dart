part of directbot;

var link_regex = new RegExp(r'\(?\b((http|https)://|www[.])[-A-Za-z0-9+&@#/%?=~_()|!:,.;]*[-A-Za-z0-9+&@#/%=~_()|]');

var _yt_info_url = 'https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&key=${googleAPIKey}&id=';

var _yt_link_id = new RegExp(r'^.*(youtu.be/|v/|embed/|watch\?|youtube.com/user/[^#]*#([^/]*?/)*)\??v?=?([^#\&\?]*).*');

handle_youtube(event) {
  if (link_regex.hasMatch(event.message)) {
    link_regex.allMatches(event.message).forEach((match) {
      var url = match.group(0);
      if (url.contains("youtube") || url.contains("youtu.be")) {
        var request_url = "${_yt_info_url}${extract_yt_id(url)}";
        http.getUrl(Uri.parse(request_url)).then((request) => request.close()).then((response) {
          response.transform(UTF8.decoder).join("").then((content) {
            var data = JSON.decoder.convert(content);
            var items = data['items'];
            var video = items[0];
            print_yt_info(event, video);
          });
        });
      }
    });
  }
}

print_yt_info(event, info) {
  var snippet = info["snippet"];
  event.reply("> ${snippet['title']} | ${snippet['channelTitle']} (${Color.GREEN}${info['statistics']['likeCount']}${Color.RESET}:${Color.RED}${info['statistics']['dislikeCount']}${Color.RESET})");
}

extract_yt_id(url) {
  return _yt_link_id.firstMatch(url).group(3);
}