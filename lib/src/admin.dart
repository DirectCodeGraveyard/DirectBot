part of directbot;

register_admin_commands() {
  admin_command("op", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: ${event.command} <users>");
      return;
    }
    event.args.forEach((user) => event.channel.op(user));
  });

  admin_command("voice", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: ${event.command} <users>");
      return;
    }
    event.args.forEach((user) => event.channel.voice(user));
  });

  admin_command("deop", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: ${event.command} <users>");
      return;
    }
    event.args.forEach((user) => event.channel.deop(user));
  });

  admin_command("devoice", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: ${event.command} <users>");
      return;
    }
    event.args.forEach((user) => event.channel.devoice(user));
  });

  admin_command("ban", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: ${event.command} <user> [reason]");
      return;
    }
    var user = event.args[0];
    var vargs = new List.from(event.args)..removeAt(0);
    var reason = event.args.length == 1 ? "banned by ${event.from}" : vargs.join(" ");
    event.channel.ban(user);
    event.channel.kick(user, reason);
  });

  admin_command("unban", (CommandEvent event) {
    if (event.args.length == 0) {
      event.reply("> Usage: ${event.command} <users>");
      return;
    }
    event.args.forEach((user) => event.channel.unban(user));
  });

  admin_command("kick", (event) {
    if (event.args.length >= 1) {
      var user = event.args[0];
      var vargs = new List.from(event.args)..removeAt(0);
      var reason = event.args.length == 1 ? "kicked by ${event.from}" : vargs.join(" ");
      event.client.send("KICK ${event.channel.name} ${user} :${reason}");
    } else {
      event.reply("> Usage: ${event.command} <user> [reason]");
    }
  });
}

void register_bot_admin_commands() {
  admin_command("execute", (event) {
    var input = new List.from(event.args);
    runZoned(() {
      var exec;
      var args;
      if (Platform.isLinux || Platform.isMacOS) {
        exec = Platform.environment['SHELL'];
        args = ['-c', input.join(' ')];
      } else if (Platform.isWindows) {
        exec = input[0];
        input.removeAt(0);
        args = input;
      } else {
        throw new Exception("System not supported");
      }

      Process.start(exec, args, runInShell: true).then((Process proc) {
        proc.stdout.transform(UTF8.decoder).transform(new LineSplitter()).listen(event.reply);

        proc.stderr.transform(UTF8.decoder).transform(new LineSplitter()).listen(event.reply);

        proc.exitCode.then((code) {
          if (code != 0) {
            event.reply("> EXIT: ${code}");
          }
        });
      });
    }, onError: (err) {
      event.reply("> ERROR: " + err);
    });
  });

  command("authenticate", (event) {
    var info = <dynamic>[event.from, event.target, event.client];
    TimedEntry<List<dynamic>> te = new TimedEntry<List<dynamic>>(info);
    te.start(10, () => _awaiting_authentication.remove(te));
    _awaiting_authentication.add(te);
    event.client.send("WHOIS ${event.from}");
  });

  admin_command("clear-buffer", (event) {
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
        if (v.value[0] == nick) return v;
      }
      return null;
    }

    bool isAuthenticated() {
      for (var user in authenticated) {
        if (user.username == event.username && user.client == event.client) {
          return true;
        }
      }
      return false;
    }

    var entry = search(event.nickname);

    if (entry != null && entry.value[2] == event.client) {
      _awaiting_authentication.remove(entry);
      var info = entry.value;
      if (!config["admins"].contains(event.username)) {
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

  register(handle_whois);

  FreenodeBridge.client.register(handle_whois);

  register((ReadyEvent event) {
    authenticated.add(new AuthenticatedUser(event.client, "kaendfinger", "kaendfinger"));
  });

  admin_command("reload", (event) {
    if (event.args.length != 1) {
      event.reply("> Usage: reload <config/aliases/txtcmds/all>");
      return;
    }
    var what = event.args[0];
    if (!["aliases", "txtcmds", "all", "config"].contains(what)) {
      event.reply("> Usage: reload <config/aliases/txtcmds/all>");
      return;
    }
    if (what == "aliases") {
      setup_aliases();
      event.reply("> Reloading Aliases");
    } else if (what == "txtcmds") {
      load_txt_cmds();
      event.reply("> Reloading Text Commands");
    } else if (what == "config") {
      reload_config();
      event.reply("> Reloading Configuration");
    } else {
      load_txt_cmds();
      setup_aliases();
      reload_config();
      event.reply("> Reloading Configuration, Aliases, Text Commands");
    }
  });
}

void reload_config() {
  load_config().then((_conf) {
    _config = _conf;

    github_chans = config["github"]["channels"];
    sticky_channels = config["sticky_channels"];
    var ch = config["channels"];
    bot.client.channels.forEach((c) {
      if (!ch.contains(c.name)) {
        bot.part(c.name);
      }
    });
    ch.forEach((a) {
      if (bot.channel(a) == null) {
        bot.join(a);
      }
    });
  });
}
