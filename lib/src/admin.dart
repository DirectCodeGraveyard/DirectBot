part of directbot;

register_admin_cmds() {
  bot.command("op").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length == 0) {
        event.reply("> Usage: ${event.command} <users>");
        return;
      }
      event.args.forEach((user) => event.channel.op(user));
    }
  });

  bot.command("voice").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length == 0) {
        event.reply("> Usage: ${event.command} <users>");
        return;
      }
      event.args.forEach((user) => event.channel.voice(user));
    }
  });

  bot.command("deop").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length == 0) {
        event.reply("> Usage: ${event.command} <users>");
        return;
      }
      event.args.forEach((user) => event.channel.deop(user));
    }
  });

  bot.command("devoice").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length == 0) {
        event.reply("> Usage: ${event.command} <users>");
        return;
      }
      event.args.forEach((user) => event.channel.devoice(user));
    }
  });

  bot.command("ban").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length == 0) {
        event.reply("> Usage: ${event.command} <user> [reason]");
        return;
      }
      var user = event.args[0];
      var vargs = new List.from(event.args)..removeAt(0);
      var reason = event.args.length == 1 ? "banned by ${event.from}" : vargs.join(" ");
      event.channel.ban(user);
      event.client.send("KICK ${event.channel.name} ${user} :${reason}");
    }
  });

  bot.command("unban").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length == 0) {
        event.reply("> Usage: ${event.command} <users>");
        return;
      }
      event.args.forEach((user) => event.channel.unban(user));
    }
  });

  bot.command("kick").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length >= 1) {
        var user = event.args[0];
        var vargs = new List.from(event.args)..removeAt(0);
        var reason = event.args.length == 1 ? "kicked by ${event.from}" : vargs.join(" ");
        event.client.send("KICK ${event.channel.name} ${user} :${reason}");
      } else {
        event.reply("> Usage: ${event.command} <user> [reason]");
      }
    }
  });
}

void register_bot_admin_commands() {
  bot.command("execute").listen((CommandEvent event) {
    if (check_user(event)) {
      List<String> input = new List.from(event.args);
      var exec = input[0];
      input.removeAt(0);
      var args = input;
      runZoned(() {
        Process.run(exec, args, runInShell: true).then((ProcessResult result) {
          String _out = result.stdout.toString();
          String _err = result.stderr.toString();
          int exit = result.exitCode;
          if (_out.isNotEmpty) {
            event.reply("> STDOUT:");
            _out.split("\n").forEach((line) {
              event.reply(line);
            });
          }
          if (_err.isNotEmpty) {
            event.reply("> STDERR:");
            _err.split("\n").forEach((line) {
              event.reply(line);
            });
          }
          if (exit != 0) {
            event.reply("> EXIT: ${exit}");
          }
        });
      }, onError: (err) {
        event.reply("> ERROR: " + err);
      });
    }
  });
  
  bot.command("authenticate").listen((CommandEvent event) {
    var info = <dynamic>[event.from, event.target, event.client];
    TimedEntry<List<dynamic>> te = new TimedEntry<List<dynamic>>(info);
    te.start(10, () => _awaiting_authentication.remove(te));
    _awaiting_authentication.add(te);
    event.client.send("WHOIS ${event.from}");
  });
  
  bot.command("clear-buffer").listen((CommandEvent event) {
    if (!check_user(event)) return;
    if (event.args.length != 0) {
      event.args.forEach((target) {
        Buffer.clear(target);
      });
      event.reply("> ${Color.GREEN}Buffer Cleared${Color.RESET}");
    } else {
      event.reply("> ${Color.GREEN }Cleared All Buffers${Color.RESET}");
    }
  });
  
  var handle_whois = (WhoisEvent event) {
    
    TimedEntry<List<dynamic>> search(String nick) {
      for (var v in _awaiting_authentication) {
        if (v.value[0] == nick)
          return v;
      }
      return null;
    }
    
    bool isAuthenticated() {
      for (AuthenticatedUser user in authenticated) {
        if (user.username == event.username && user.client == event.client) {
          return true;
        }
      }
      return false;
    }
    
    var entry = search(event.nickname);
    
    if (entry != null && entry.value[2] == event.client) {
      _awaiting_authentication.remove(entry);
      List<dynamic> info = entry.value;
      if (!_config['admins'].split(" ").contains(event.username)) {
        info[2].message(info[1], "${info[0]}> ${Color.RED}Authentication prohibited${Color.RESET}.");
      } else {
        if (!isAuthenticated()) {
          authenticated.add(new AuthenticatedUser(event.client, event.username, event.nickname));
          info[2].message(info[1], "${info[0]}> Authentication successful.");
        } else {
          info[2].message(info[1], "${info[0]}> Already authenticated.");
        }
      }
    }
  };
  
  bot.register(handle_whois);
  
  FreenodeBridge.client.register(handle_whois);
  
  bot.register((ReadyEvent event) {
    authenticated.add(new AuthenticatedUser(event.client, "kaendfinger", "kaendfinger"));
  });
}