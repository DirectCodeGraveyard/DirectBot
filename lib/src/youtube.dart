part of directbot;

var link_regex = new RegExp(r'\(?\b((http|https)://|www[.])[-A-Za-z0-9+&@#/%?=~_()|!:,.;]*[-A-Za-z0-9+&@#/%=~_()|]');
var _yt_info_url = 'https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&key=${googleAPIKey}&id=';
var _yt_link_id = new RegExp(r'^.*(youtu.be/|v/|embed/|watch\?|youtube.com/user/[^#]*#([^/]*?/)*)\??v?=?([^#\&\?]*).*');

void handle_youtube(MessageEvent event) {
  if (link_regex.hasMatch(event.message)) {
    link_regex.allMatches(event.message).forEach((match) {
      var url = match.group(0);
      if (url.contains("youtube") || url.contains("youtu.be")) {
        output_youtube_info(event, url);
      }
    });
  }
}

void output_youtube_info(MessageEvent event, String url) {
  var id = extract_yt_id(url);
  if (id == null) {
    return;
  }
  var request_url = "${_yt_info_url}${id}";
  httpClient.get(request_url).then((http.Response response) {
    var data = JSON.decode(response.body);
    var items = data['items'];
    var video = items[0];
    print_yt_info(event, video);
  });
}

void print_yt_info(event, info) {
  var snippet = info["snippet"];
  event.reply("${part_prefix("YouTube")} ${snippet['title']} | ${snippet['channelTitle']} (${Color.GREEN}${info['statistics']['likeCount']}${Color.RESET}:${Color.RED}${info['statistics']['dislikeCount']}${Color.RESET})");
}

String part_prefix(String name) {
  return "[${Color.BLUE}${name}${Color.RESET}]";
}

String extract_yt_id(url) {
  var first = _yt_link_id.firstMatch(url);
  
  if (first == null) {
    return null;
  }
  return first.group(3);
}
