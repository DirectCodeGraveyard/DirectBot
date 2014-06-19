part of directbot;

// Github IP range converted to regex
RegExp _exp = new RegExp(r"192\.30\.25[2-5]\.[0-9]{1,3}");

void listen() {
  runZoned(() {
    HttpServer.bind(InternetAddress.ANY_IP_V4, config['http_port'])
    .then((HttpServer server) {
      server.listen((HttpRequest request) {
        print("Request received");
        String address = request.connectionInfo.remoteAddress.address;
        if (!_exp.hasMatch(address)) {
          print("$address was rejected from the server");
          request.response
          ..statusCode = 403
          ..close();
          return;
        }
        
        request.transform(UTF8.decoder).join("").then((String data) {
          
          var json = JSON.decoder.convert(data);
          
          switch (request.headers.value('X-GitHub-Event')) {
            case "push":
              if (json['repository']['fork'])
                break;
              
              var repo_name = json['repository']['name'];
              var pusher = json['pusher']['name'];
              var commit_size = json['commits'].length;
              
              List<String> chans = config['hook_channels'].split(" ");
              void message(String msg) {
                for (var chan in chans)
                  bot.message(chan, "[${Color.BLUE}$repo_name${Color.RESET}] $msg");
              }
              
              (new HttpClient()).postUrl(Uri.parse("http://git.io/?url=${json['compare']}"))
              .then((HttpClientRequest req) {
                return req.close();
              }).then((HttpClientResponse rep) {
                              
                var committer = "${Color.OLIVE}$pusher${Color.RESET}";
                var commit = "commit${commit_size > 1 ? "s" : ""}";
                var branch = "${Color.GREEN}${json['ref'].split("/")[2]}${Color.RESET}";
                var url = "${Color.PURPLE}http://git.io/${rep.headers.value('Location').split("/").last}${Color.RESET}";
                message("$committer pushed ${Color.GREEN}$commit_size${Color.RESET} $commit to $branch - $url");
                
                int tracker = 0;
                for (var commit in json['commits']) {
                  tracker++;
                  if (tracker > 5)
                    break;
                  committer = "${Color.OLIVE}${commit['committer']['name']}${Color.RESET}";
                  var sha = "${Color.GREEN}${commit['id'].substring(0, 7)}${Color.RESET}";
                  message("$committer $sha - ${commit['message']}");
                }
              });
              
              break;
          }
          
          request.response.close();
        });
      });
    });
  }, onError: (err) {
    print("ERROR: $err");
  });
}