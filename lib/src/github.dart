part of directbot;

// Github IP range converted to regex
var github_ip_regex = new RegExp(r"192\.30\.25[2-5]\.[0-9]{1,3}");

void init_github() {}

String get_repo_name(Map<String, dynamic> repo) {
  if (repo["full_name"] != null) {
    return repo["full_name"];
  } else {
    return "${repo["owner"]["name"]}/${repo["name"]}";
  }
}

List<String> github_channels_for(String repo_id) {
  var gh_conf = config["github"];
  if (gh_conf["channels"] != null && gh_conf["channels"].containsKey(repo_id)) {
    var chans = gh_conf["channels"][repo_id];
    if (chans is String) {
      chans = [chans];
    }
    return chans;
  } else {
    return gh_conf["default_channels"];
  }
}

void register_github_hooks([String user = "DirectMyFile"]) {
  var added_hook = false;
  var completer = new Completer();
  var repos = null;
  var count = 0;
  GitHubAPI.get("https://api.github.com/users/${user}/repos").then((response) {
    
    if (response.statusCode != 200) {
      bot.message("#directcode", "[${Color.BLUE}GitHub${Color.RESET}] Failed to get repository list.");
      return;
    }
    
    repos = JSON.decode(response.body) as List<Map<String, Object>>;
    repos.forEach((repo) {
      GitHubAPI.get(repo["hooks_url"]).then((hresp) {
        var hooks = JSON.decode(hresp.body) as List<Map<String, Object>>;
        
        var add_hook = true;
        
        for (var hook in hooks) {
          if (hook["config"]["url"] == "http://bot.directmyfile.com:8020/github") {
            add_hook = false;
          }
        }
        
        if (add_hook) {
          added_hook = true;
          GitHubAPI.post(repo["hooks_url"], JSON.encode({
            "name": "web",
            "active": true,
            "config": {
              "url": "http://bot.directmyfile.com:8020/github",
              "content_type": "json"
            },
            "events": GitHubAPI.events
          } as Map<String, Object>)).then((resp) {
            if (resp.statusCode != 201) {
              bot.message("#directcode", "[${Color.BLUE}GitHub${Color.RESET}] Failed to add hook for ${repo["name"]}.");
            } else {
              bot.message("#directcode", "[${Color.BLUE}GitHub${Color.RESET}] Added Hook for ${repo["name"]}.");
            }
          });
        }
        
        count++;
        if (count == repos.length) {
          completer.complete();
        }
      });
    });
  });
  
  completer.future.then((_) {
    if (!added_hook) {
      bot.message("#directcode", "[${Color.BLUE}GitHub${Color.RESET}] No Hooks Added");
    }
  });
}

String get_repo_owner(Map<String, dynamic> repo) {
  if (repo["owner"]["name"] != null) {
    return repo["owner"]["name"];
  } else {
    return repo["owner"]["login"];
  }
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
  var address = request.connectionInfo.remoteAddress.address;

  if (!github_ip_regex.hasMatch(address)) {
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
      var name = get_repo_name(json["repository"]);
      
      var names = config["github"]["names"];
      
      if (names != null && names.containsKey(name)) {
        repo_name = names[name];
      } else {
        if (get_repo_owner(json["repository"]) != "DirectMyFile") {
          repo_name = name;
        } else {
          repo_name = json["repository"]["name"];
        }
      }
    }

    void message(String msg, [bool prefix = true]) {
      var m = "";
      if (prefix) {
        m += "[${Color.BLUE}${repo_name}${Color.RESET}] ";
      }
      m += msg;
      for (var chan in github_channels_for(repo_name)) {
        bot.message(chan, m);
      }
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
          message("${Color.OLIVE}${get_repo_owner(forkee)}${Color.RESET} created a fork at ${forkee["full_name"]} - ${url}");
        });
        break;
    }
    
    request.response.write(JSON.encode({
        "status": "success",
        "information": {
          "repo_name": repo_name,
          "channels": github_channels_for(repo_name)
        }
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

class GitHubAPI {
  static String token = null;
  
  static List<String> events = [
    "push",
    "ping",
    "pull_request",
    "fork",
    "release",
    "issues"
  ];
  
  static Future<http.Response> get(String url) {
    return http.get(url, headers: {
      "Authorization": "token ${GitHubAPI.token}"
    });
  }
  
  static Future<http.Response> post(String url, body) {
    return http.post(url, headers: {
      "Authorization": "token ${GitHubAPI.token}"
    }, body: body);
  }
}

void register_github_commands() {
  admin_command("check-hooks", (event) {
    if (event.args.length == 0) {
      register_github_hooks();
    } else {
      if (event.args.length != 1) {
        event.reply("> Usage: check-hooks [user]");
      } else {
        var user = event.args[0];
        register_github_hooks(user);
      }
    }
  });
}