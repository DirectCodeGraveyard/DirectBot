part of directbot;

Future<Map<String, dynamic>> load_config() {
  return new HttpClient().getUrl(Uri.parse("http://script.google.com/macros/s/AKfycbwifjQ_eaDUkalw9NYqGMZnZv8TxQ3P7ltnBdt9slykTy3fauE/exec")).then((HttpClientRequest request) => request.close()).then((HttpClientResponse response) {
    return response.transform(UTF8.decoder).join("").then((content) {
        print("Config Loaded");
        return new Future(() => JSON.decoder.convert(content));
    });
  });
}