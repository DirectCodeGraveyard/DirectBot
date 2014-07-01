part of directbot;

// Github IP range converted to regex
RegExp _exp = new RegExp(r"192\.30\.25[2-5]\.[0-9]{1,3}");

List<String> github_chans;

void init_github() {
  github_chans = config['hook_channels'].split(" ");
}

void handle_github_request(HttpRequest request) {
  if (request.method != "POST") {
    request.response.write(JSON.encode({
        "status": "failure",
        "error": "Only POST is Supported"
    }));
    request.response.close();
    return;
  }
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

    var repo_name;

    if (json["repository"] != null) {
      repo_name = json["repository"]["name"];
    }

    void message(String msg, [bool prefix = true]) {
      var m = "";
      if (prefix)
        m += "[${Color.BLUE}$repo_name${Color.RESET}] ";
      m += msg;
      for (var chan in github_chans)
        bot.message(chan, m);
    }

    switch (request.headers.value('X-GitHub-Event')) {
      case "ping":
        message("[${Color.BLUE}GitHub${Color.RESET}] ${json["zen"]}", false);
        break;
      case "push":
        var ref_regex = new RegExp(r"refs/(heads|tags)/(.*)$");
        var branchName = "";
        var tagName = "";
        var is_branch = false;
        var is_tag = false;
        if (ref_regex.hasMatch(json["ref"])) {
          var match = ref_regex.firstMatch(json["ref"]);
          var _type = match.group(1);
          var type = ({
              "heads": "branch",
              "tags": "tag"
          }[_type]);
          if (type == "branch") {
            is_branch = true;
            branchName = match.group(2);
          } else if (type == "tag") {
            is_tag = true;
            tagName = match.group(2);
          }
        }
        if (json["commits"] != null && json["commits"].length != 0) {
          if (json['repository']['fork'])
            break;
          var pusher = json['pusher']['name'];
          var commit_size = json['commits'].length;

          void message(String msg) {
            for (var chan in github_chans)
              bot.message(chan, "[${Color.BLUE}$repo_name${Color.RESET}] $msg");
          }

          gitio_shorten(json["compare"]).then((compareUrl) {
            var committer = "${Color.OLIVE}$pusher${Color.RESET}";
            var commit = "commit${commit_size > 1 ? "s" : ""}";
            var branch = "${Color.GREEN}${json['ref'].split("/")[2]}${Color.RESET}";

            var url = "${Color.PURPLE}${compareUrl}${Color.RESET}";
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
        } else if (is_tag) {
          if (json['repository']['fork'])
            break;
          String out = "";
          if (json['pusher'] != null) {
            out += "${Color.OLIVE}${json["pusher"]["name"]}${Color.RESET} tagged ";
          } else {
            out += "Tagged ";
          }
          out += "${Color.GREEN}${json['head_commit']['id'].substring(0, 7)}${Color.RESET} as ";
          out += "${Color.GREEN}${tagName}${Color.RESET}";
          message(out);
        } else if (is_branch) {
          if (json['repository']['fork'])
            break;
          String out = "";
          if (json["deleted"]) {
            if (json["pusher"] != null)
              out += "${Color.OLIVE}${json["pusher"]["name"]}${Color.RESET} deleted branch ";
            else
              out += "Deleted branch";
          } else {
            if (json["pusher"] != null)
              out += "${Color.OLIVE}${json["pusher"]["name"]}${Color.RESET} created branch ";
            else
              out += "Created branch";
          }
          out += "${Color.GREEN}${branchName}${Color.RESET}";

          gitio_shorten(json["head_commit"]["url"]).then((url) {
            out += " - ${Color.PURPLE}${url}${Color.RESET}";
            message(out);
          });
        }
        break;

      case "issues":
        var action = json["action"];
        var by = json["sender"]["login"];
        var issueId = json["issue"]["number"];
        var issueName = json["issue"]["title"];
        var issueUrl = json["issue"]["html_url"];
        gitio_shorten(issueUrl).then((url) {
          message("${Color.OLIVE}${by}${Color.RESET} ${action} the issue '${issueName}' (${issueId}) - ${url}");
        });
        break;

      case "release":
        var action = json["action"];
        var author = json["sender"]["login"];
        var name = json["release"]["name"];
        gitio_shorten(json["release"]["html_url"]).then((url) {
          message("${Color.OLIVE}${author}${Color.RESET} ${action} the release '${name}' - ${url}");
        });
        break;

      case "fork":
        var forkee = json["forkee"];
        gitio_shorten(forkee["html_url"]).then((url) {
          message("${Color.OLIVE}${forkee["owner"]["login"]}${Color.RESET} created a fork at ${forkee["full_name"]} - ${url}");
        });
        break;
    }

    request.response.write(JSON.encode({
        "status": "success"
    }));
    request.response.close();
  });
}

Future<String> gitio_shorten(String input) {
  return new HttpClient().postUrl(Uri.parse("http://git.io/?url=${Uri.encodeComponent(input)}"))
    .then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      if (response.statusCode != 201) {
        return new Future.value(input);
      } else {
        return new Future.value("http://git.io/${response.headers.value("Location").split("/").last}");
      }
    });
}