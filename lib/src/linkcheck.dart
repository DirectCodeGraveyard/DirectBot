part of directbot;


/// Simple URL regex to match http(s) urls.
var URL_REGEX = new RegExp(r'\(?\b((http|https)://|www[.])[-A-Za-z0-9+&@#/%?=~_()|!:,.;]*[-A-Za-z0-9+&@#/%=~_()|]');

handleLink(MessageEvent event)
{
  if (URL_REGEX.hasMatch(event.message))
  {
    var url = URL_REGEX.firstMatch(event.message).group(0);
    readPageTitle(event, url);
  }
}

void readPageTitle(MessageEvent event, String url)
{
  httpClient.get(url).then((http.Response response)
  {
    var data = response.body;
    var page = HtmlParser.parse(data);
    var title = page.querySelector('title').text;
    RegExp specialChars = new RegExp(r'''[^a-zA-Z0-9`~!@#$%^&*()\-_=+\[\]:'",<.>/?\\| ]''');
    RegExp multiSpaces = new RegExp(r' {2,}');
    title = title.replaceAll(specialChars, ' ').replaceAll(multiSpaces, ' ');
    event.reply(title);
  });
}