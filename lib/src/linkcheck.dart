part of directbot;

/// Simple URL regex to match http(s) urls.
var URL_REGEX = new RegExp(r'\(?\b((http|https)://|www[.])[-A-Za-z0-9+&@#/%?=~_()|!:,.;]*[-A-Za-z0-9+&@#/%=~_()|]');

/// Regex to match any character that is not a letter, number, or keyboard (enUS) symbol.
final RegExp NO_SPECIAL_CHARS = new RegExp(r'''[^\w`~!@#$%^&*()\-_=+\[\]:'",<.>/?\\| ]''');

/// Regex to match any instance of a whitespace character occuring more than once consecutively.
final RegExp NO_MULTI_SPACES = new RegExp(r' {2,}');

handleLink(MessageEvent event) {
  if (URL_REGEX.hasMatch(event.message)) {
    var url = URL_REGEX.firstMatch(event.message).group(0);
    readPageTitle(event, url);
  }
}

/// Will pull down the HTML body for the given [url], then parse the HTML into a DOM
/// before then grabbing the text between the '''<title></title>''' tags and sending
/// it as a reply to the triggering [event].
void readPageTitle(MessageEvent event, String url) {
  http.get(url).then((http.Response response) {
    var data = response.body;
    if (data == null) {
      return;
    }

    var page = HtmlParser.parse(data);
    if (page == null) {
      return;
    }

    var title = page.querySelector('title').text;
    if (title == null || title.isEmpty) {
      return;
    }

    title = title.replaceAll(NO_SPECIAL_CHARS, ' ').replaceAll(NO_MULTI_SPACES, ' ');
    event.reply("${part_prefix("Link Title")} posted by ${event.from}: ${title}");
  });
}
