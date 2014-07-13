part of directbot;

HttpServer server;

void server_listen() {
  runZoned(() {
    HttpServer.bind(InternetAddress.ANY_IP_V4, config['http_port'])
    .then((HttpServer _server) {
      server = _server;
      server.listen((HttpRequest request) {
        switch (request.uri.path) {
          case "/github":
            handle_github_request(request);
            break;
          case "/info.json":
            handle_info_request(request);
            break;
          default:
            handle_unhandled_path(request);
        }
      });
    });
  }, onError: (Error err) {
    print("------------- HTTP Server Error --------------");
    print(err);
    print(err.stackTrace);
    print("----------------------------------------------");
  });
}

void handle_unhandled_path(HttpRequest request) {
  request.response
    ..statusCode = 404
    ..write(JSON.encode({ "status": "failure", "error": "Not Found" }))
    ..close();
}

void handle_info_request(HttpRequest request) {
  var response = request.response;
  var out = {};
  out["server"] = {
    "host": bot.client.config.host,
    "port": bot.client.config.port
  };
  out["nickname"] = bot.client.nickname;
  out["channels"] = bot.client.channels.map((a) => a.name);
  response.write(JSON.encode(out));
  response.close();
}