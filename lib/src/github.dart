part of directbot;

class GitHub {
  static String token = null;

// Github IP range converted to regex
  static var IP_REGEX = new RegExp(r"192\.30\.25[2-5]\.[0-9]{1,3}");

  static var HOOK_URL = "http://bot.directcode.org:8020/github";

  static List<String> events = ["push", "ping", "pull_request", "fork", "release", "issues", "commit_comment", "watch"];

  static Future<http.Response> get(String url, {String api_token}) {
    if (api_token == null) {
      api_token = token;
    }
    return http.get(url, headers: {
      "Authorization": "token ${api_token}"
    });
  }

  static Future<http.Response> post(String url, body, {String api_token}) {
    if (api_token == null) {
      api_token = token;
    }
    return http.post(url, headers: {
      "Authorization": "token ${api_token}"
    }, body: body);
  }

  static Future<String> shorten(String input) {
    return new HttpClient().postUrl(Uri.parse("http://git.io/?url=${Uri.encodeComponent(input)}")).then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      if (response.statusCode != 201) {
        return new Future.value(input);
      } else {
        return new Future.value("http://git.io/${response.headers.value("Location").split("/").last}");
      }
    });
  }

  static String get_repo_owner(Map<String, dynamic> repo) {
    if (repo["owner"]["name"] != null) {
      return repo["owner"]["name"];
    } else {
      return repo["owner"]["login"];
    }
  }

  static void handle_request(HttpRequest request) {
    if (request.method != "POST") {
      request.response.write(JSON.encode({
        "status": "failure",
        "error": "Only POST is Supported"
      }));
      request.response.close();
      return;
    }
    var address = request.connectionInfo.remoteAddress.address;

    if (!IP_REGEX.hasMatch(address)) {
      print("$address was rejected from the server");
      request.response
          ..statusCode = 403
          ..close();
      return;
    }

    var handled = true;

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

        // Skip Bot Data Repository
        if (get_repo_name(json["repository"]) == "DirectMyFile/bot-data") {
          return;
        }
      }

      void message(String msg, [bool prefix = true]) {
        var m = "";
        if (prefix) {
          m += "[${Color.BLUE}${repo_name}${Color.RESET}] ";
        }
        m += msg;
        for (var chan in channels_for(repo_name)) {
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
            if (json['repository']['fork']) break;
            var pusher = json['pusher']['name'];
            var commit_size = json['commits'].length;

            GitHub.shorten(json["compare"]).then((compareUrl) {
              var committer = "${Color.OLIVE}$pusher${Color.RESET}";
              var commit = "commit${commit_size > 1 ? "s" : ""}";
              var branch = "${Color.GREEN}${json['ref'].split("/")[2]}${Color.RESET}";

              var url = "${Color.PURPLE}${compareUrl}${Color.RESET}";
              message("$committer pushed ${Color.GREEN}$commit_size${Color.RESET} $commit to $branch - $url");

              int tracker = 0;
              for (var commit in json['commits']) {
                tracker++;
                if (tracker > 5) break;
                committer = "${Color.OLIVE}${commit['committer']['name']}${Color.RESET}";
                var sha = "${Color.GREEN}${commit['id'].substring(0, 7)}${Color.RESET}";
                message("$committer $sha - ${commit['message']}");
              }
            });
          } else if (is_tag) {
            if (json['repository']['fork']) break;
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
            if (json['repository']['fork']) break;
            String out = "";
            if (json["deleted"]) {
              if (json["pusher"] != null) {
                out += "${Color.OLIVE}${json["pusher"]["name"]}${Color.RESET} deleted branch ";
              } else {
                out += "Deleted branch";
              }
            } else {
              if (json["pusher"] != null) {
                out += "${Color.OLIVE}${json["pusher"]["name"]}${Color.RESET} created branch ";
              } else {
                out += "Created branch";
              }
            }
            out += "${Color.GREEN}${branchName}${Color.RESET}";

            GitHub.shorten(json["head_commit"]["url"]).then((url) {
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
          GitHub.shorten(issueUrl).then((url) {
            message("${Color.OLIVE}${by}${Color.RESET} ${action} the issue '${issueName}' (${issueId}) - ${url}");
          });
          break;

        case "release":
          var action = json["action"];
          var author = json["sender"]["login"];
          var name = json["release"]["name"];
          GitHub.shorten(json["release"]["html_url"]).then((url) {
            message("${Color.OLIVE}${author}${Color.RESET} ${action} the release '${name}' - ${url}");
          });
          break;

        case "fork":
          var forkee = json["forkee"];
          GitHub.shorten(forkee["html_url"]).then((url) {
            message("${Color.OLIVE}${get_repo_owner(forkee)}${Color.RESET} created a fork at ${forkee["full_name"]} - ${url}");
          });
          break;
        case "commit_comment":
          var who = json["sender"]["login"];
          var commit_id = json["comment"]["commit_id"].substring(0, 10);
          message("${Color.OLIVE}${who}${Color.RESET} commented on commit ${commit_id}");
          break;
        case "issue_comment":
          var issue = json["issue"];
          var sender = json["sender"];
          var action = json["action"];

          if (action == "created") {
            message("${Color.OLIVE}${sender["login"]}${Color.RESET} commented on issue #${issue["number"]}");
          }

          break;
        case "watch":
          var who = json["sender"]["login"];
          message("${Color.OLIVE}${who}${Color.RESET} starred the repository");
          break;
        case "page_build":
          var build = json["build"];
          var who = build["pusher"]["login"];
          var msg = "";
          if (build["error"]["message"] != null) {
            msg += "${Color.OLIVE}${who}${Color.RESET} Page Build Failed (Message: ${build["error"]["message"]})";
            message(msg);
          }
          break;
        case "gollum":
          var who = json["sender"]["login"];
          var pages = json["pages"];
          for (var page in pages) {
            var name = page["title"];
            var type = page["action"];
            var summary = page["summary"];
            var msg = "${Color.OLIVE}${who}${Color.RESET} ${type} '${name}' on the wiki";
            if (summary != null) {
              msg += " (${msg})";
            }
            message(msg);
          }
          break;

        case "pull_request":
          var who = json["sender"]["login"];
          var pr = json["pull_request"];
          var number = json["number"];

          var action = json["action"];

          if (["opened", "reopened", "closed"].contains(action)) {
            GitHub.shorten(pr["html_url"]).then((url) {
              message("${Color.OLIVE}${who}${Color.RESET} ${action} a Pull Request (#${number}) - ${url}");
            });
          }

          break;

        default:
          handled = false;
          break;
      }

      request.response.write(JSON.encode({
        "status": "success",
        "information": {
          "repo_name": repo_name,
          "channels": channels_for(repo_name),
          "handled": handled
        }
      }));
      request.response.close();
    });
  }

  static void register_github_hooks([String user = "DirectMyFile", String irc_user, String channel = "#directcode", String token]) {
    var added_hook = false;
    var completer = new Completer();
    var repos = null;
    var count = 0;

    var ran_complete = false;

    GitHub.get("https://api.github.com/users/${user}/repos", api_token: token).then((response) {

      if (response.statusCode != 200) {
        bot.message("#directcode", "[${Color.BLUE}GitHub${Color.RESET}] Failed to get repository list.");
        return;
      }

      repos = JSON.decode(response.body) as List<Map<String, Object>>;

      var timer;
      timer = new Timer.periodic(new Duration(milliseconds: 20), (it) {
        if (count == repos.length) {
          completer.complete();
          timer.cancel();
        }
      });

      repos.forEach((repo) {
        GitHub.get(repo["hooks_url"], api_token: token).then((hresp) {
          if (hresp.statusCode != 200) {
            var m = "[${Color.BLUE}GitHub${Color.RESET}] No Permissions for Repository '${repo["name"]}'";
            if (irc_user != null) {
              bot.client.notice(irc_user, m);
            }
            count++;
            return;
          }

          var hooks = JSON.decode(hresp.body) as List<Map<String, Object>>;

          var add_hook = true;

          for (var hook in hooks) {
            if (hook["config"]["url"] == HOOK_URL) {
              add_hook = false;
            }
          }

          if (add_hook) {
            GitHub.post(repo["hooks_url"], JSON.encode({
              "name": "web",
              "active": true,
              "config": {
                "url": HOOK_URL,
                "content_type": "json"
              },
              "events": GitHub.events
            } as Map<String, Object>), api_token: token).then((resp) {
              if (resp.statusCode != 201) {
                var m = "[${Color.BLUE}GitHub${Color.RESET}] Failed to add hook for ${repo["name"]}.";
                if (irc_user != null) {
                  bot.client.notice(irc_user, m);
                }
              } else {
                added_hook = true;
                bot.message(channel, "[${Color.BLUE}GitHub${Color.RESET}] Added Hook for ${repo["name"]}.");
              }

              count++;
            });
          } else {
            count++;
          }
        });
      });
    });

    completer.future.then((_) {
      if (!added_hook) {
        bot.message(channel, "[${Color.BLUE}GitHub${Color.RESET}] Checked ${repos.length} repositories. No Hooks Added");
      }
    });
  }

  static List<String> channels_for(String repo_id) {
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

  static String get_repo_name(Map<String, dynamic> repo) {
    if (repo["full_name"] != null) {
      return repo["full_name"];
    } else {
      return "${repo["owner"]["name"]}/${repo["name"]}";
    }
  }

  static void initialize() {
    admin_command("gh-hooks", (event) {
      if (event.args.length == 0) {
        register_github_hooks();
      } else {
        if (event.args.length > 2) {
          event.reply("> Usage: check-hooks [user] [token]");
        } else {
          var user = event.args[0];
          var token = event.args.length == 2 ? event.args[1] : GitHub.token;
          register_github_hooks(user, event.from, event.isPrivate ? event.from : event.target, token);
        }
      }
    });
  }

  static RegExp ISSUE_REGEX = new RegExp(r"(?:.*)(?:https?)\:\/\/github\.com\/(.*)\/(.*)\/issues\/([0-9]+)(?:.*)");

  static void handle_issue(MessageEvent event) {
    if (ISSUE_REGEX.hasMatch(event.message)) {
      for (var match in ISSUE_REGEX.allMatches(event.message)) {
        var url = "https://api.github.com/repos/${match[1]}/${match[2]}/issues/${match[3]}";
        GitHub.get(url).then((http.Response response) {
          if (response.statusCode != 200) {
            var repo = match[1] + "/" + match[2];
            event.reply("${part_prefix("GitHub Issues")} Failed to fetch issue information (repo: ${repo}, issue: ${match[3]})");
          } else {
            var json = JSON.decode(response.body);
            var msg = "${part_prefix("GitHub Issues")} ";
            
            msg += "Issue #${json["number"]} '${json["title"]}' by ${json["user"]["login"]}";
            event.reply(msg);
            msg = "${part_prefix("GitHub Issues")} ";
            
            if (json["asignee"] != null) {
              msg += "assigned to: ${json["assignee"]["login"]}, ";
            }
            
            msg += "status: ${json["state"]}";
            
            if (json["milestone"] != null) {
              msg += ", milestone: ${json["milestone"]["title"]}";
            }
            
            event.reply(msg);
          }
        });
      }
    }
  }
  
  static RegExp REPO_REGEX = new RegExp(r"(?:.*)(?:https?)\:\/\/github\.com\/([A-Za-z0-9\-\.\_\(\)]+)\/([A-Za-z0-9\-\.\_\(\)]+)(?:\/?)(?:.*)");
  
  static void handle_repo(MessageEvent event) {
    if (REPO_REGEX.hasMatch(event.message)) {
      for (var match in REPO_REGEX.allMatches(event.message)) {
        var user = match[1];
        var repo = match[2];
        
        var url = "https://api.github.com/repos/${user}/${repo}";
        
        GitHub.get(url).then((response) {
          if (response.statusCode != 200) {
            if (response.statusCode == 404) {
              event.reply("${part_prefix("GitHub")} Repository does not exist: ${user}/${repo}");
            } else {
              event.reply("${part_prefix("GitHub")} Failed to get repository information (code: ${response.statusCode})");
            }
            return;
          }
          var json = JSON.decode(response.body);
          var description = json["description"];
          var subscribers = json["subscribers_count"];
          var stars = json["stargazers_count"];
          var forks = json["forks_count"];
          var open_issues = json["open_issues_count"];
          var language = json["language"];
          var default_branch = json["default_branch"];
          var msg = "${part_prefix("GitHub")} ";
          
          if (description != null) {
            msg += "${description}";
            event.reply(msg);
          }
          
          msg = "${part_prefix("GitHub")} ${subscribers} subscribers, ${stars} stars, ${forks} forks, ${open_issues} open issues";
          event.reply(msg);
        
          msg = "${part_prefix("GitHub")} Language: ${language}, Default Branch: ${default_branch}";
          event.reply(msg);
        });
      }
    }
  }
}

